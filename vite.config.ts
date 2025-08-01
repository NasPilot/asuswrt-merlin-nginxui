/* eslint-disable  @typescript-eslint/no-unsafe-assignment */
/* eslint-disable  @typescript-eslint/no-unsafe-call */
/* eslint-disable  @typescript-eslint/no-unsafe-member-access */
/* eslint-disable  @typescript-eslint/no-unsafe-return */
/* eslint-disable  @typescript-eslint/no-unsafe-argument */
/* eslint-disable  @typescript-eslint/no-explicit-any */

import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import cssInjectedByJsPlugin from 'vite-plugin-css-injected-by-js';
import { visualizer } from 'rollup-plugin-visualizer';
import fs from 'fs';
import { dirname, join, resolve } from 'path';
import { fileURLToPath } from 'url';

// Plugin to generate build info
function generateBuildInfo() {
  return {
    name: 'generate-build-info',
    generateBundle() {
      const buildInfo = {
        version: process.env.npm_package_version || '1.0.0',
        buildTime: new Date().toISOString(),
        gitCommit: process.env.GIT_COMMIT || 'unknown',
        nodeVersion: process.version,
        platform: process.platform
      };
      
      this.emitFile({
        type: 'asset',
        fileName: 'build-info.json',
        source: JSON.stringify(buildInfo, null, 2)
      });
    }
  };
}

function watchAllShFiles(pluginContext, dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  entries.forEach((entry) => {
    const fullPath = join(dir, entry.name);

    if (entry.isDirectory()) {
      watchAllShFiles(pluginContext, fullPath);
    } else if (entry.isFile() && fullPath.endsWith('.sh')) {
      try {
        pluginContext.addWatchFile(fullPath);
        console.log(`Watching shell file: ${fullPath}`);
      } catch (error) {
        console.error(`Error watching shell file ${fullPath}:`, error);
      }
    }
  });
}

function inlineShellImports(scriptPath, visited = new Set(), isRoot = true) {
  if (visited.has(scriptPath)) {
    return '';
  }
  visited.add(scriptPath);

  const content = fs.readFileSync(scriptPath, 'utf8');
  const dirOfScript = dirname(scriptPath);

  const lines = content.split('\n');
  let output = '';

  for (const line of lines) {
    const match = line.match(/^import\s+(.+)$/);
    if (match) {
      const importedFile = match[1].trim();
      const importAbsolutePath = resolve(dirOfScript, importedFile);
      output += inlineShellImports(importAbsolutePath, visited, false);
    } else {
      if (!isRoot && line.match(/^#/)) {
        continue;
      }
      output += `${line  }\n`;
    }
  }

  return output;
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production';
  const isAnalyze = mode === 'analyze';
  
  const plugins = [
    vue({
      template: {
        compilerOptions: {
          // Treat custom elements as custom components
          isCustomElement: (tag) => tag.startsWith('asus-')
        }
      }
    }),
    cssInjectedByJsPlugin({
      topExecutionPriority: true,
      jsAssetsFilterFunction: function customJsAssetsfilterFunction(outputChunk) {
        return outputChunk.isEntry || outputChunk.isDynamicEntry;
      }
    }),
    generateBuildInfo(),
    {
      name: 'shell-script-bundler',
      buildStart() {
        const backendDir = resolve(__dirname, 'src/backend');
        if (fs.existsSync(backendDir)) {
          watchAllShFiles(this, backendDir);
        }
      },
      
      handleHotUpdate({ file, server }) {
        if (file.endsWith('.sh')) {
          console.log(`Shell file changed: ${file}`);
          server.ws.send({
            type: 'full-reload'
          });
          return [];
        }
      },
      generateBundle() {
        const backendDir = resolve(__dirname, 'src/backend');
        if (!fs.existsSync(backendDir)) {
          return;
        }

        const entries = fs.readdirSync(backendDir);
        entries.forEach((entry) => {
          const fullPath = join(backendDir, entry);
          if (fs.statSync(fullPath).isFile() && fullPath.endsWith('.sh')) {
            const content = inlineShellImports(fullPath);
            this.emitFile({
              type: 'asset',
              fileName: entry,
              source: content
            });
          }
        });
      }
    },
    {
      name: 'copy-static-files',
      generateBundle() {
        const staticFiles = [
          { src: 'src/App.html', dest: 'nginxui.asp' },
          { src: 'README.md', dest: 'README.md' }
        ];

        staticFiles.forEach(({ src, dest }) => {
          const srcPath = resolve(__dirname, src);
          if (fs.existsSync(srcPath)) {
            const content = fs.readFileSync(srcPath, 'utf8');
            this.emitFile({
              type: 'asset',
              fileName: dest,
              source: content
            });
          }
        });
      }
    }
  ];
  
  // Add bundle analyzer in analyze mode
  if (isAnalyze) {
    plugins.push(
      visualizer({
        filename: 'dist/stats.html',
        open: true,
        gzipSize: true,
        brotliSize: true,
        template: 'treemap' // Better visualization
      })
    );
  }
  
  return {
    plugins,
    build: {
      outDir: 'dist',
      minify: isProduction ? 'terser' : false,
      sourcemap: !isProduction,
      target: 'es2015',
      cssCodeSplit: false,
      rollupOptions: {
        input: 'index.html',
        output: {
          entryFileNames: isProduction ? 'nginxui-[hash].js' : 'nginxui.js',
          chunkFileNames: isProduction ? 'chunks/[name]-[hash].js' : 'chunks/[name].js',
          assetFileNames: (assetInfo) => {
            if (assetInfo.name && assetInfo.name.endsWith('.css')) {
              return isProduction ? 'nginxui-[hash].css' : 'nginxui.css';
            }
            return isProduction ? 'assets/[name]-[hash].[ext]' : 'assets/[name].[ext]';
          },
          manualChunks: {
            vendor: ['vue'],
            utils: ['axios']
          }
        },
        external: [],
        treeshake: isProduction
      },
      terserOptions: isProduction ? {
        compress: {
          drop_console: true,
          drop_debugger: true,
          pure_funcs: ['console.log', 'console.info', 'console.debug']
        },
        mangle: {
          safari10: true
        },
        format: {
          comments: false
        }
      } : undefined,
      reportCompressedSize: isProduction,
      chunkSizeWarningLimit: 1000
    },
    resolve: {
      alias: {
        '@': resolve(__dirname, 'src'),
        '@modules': resolve(__dirname, 'src/modules'),
        '@components': resolve(__dirname, 'src/components'),
        '@utils': resolve(__dirname, 'src/utils'),
        '@types': resolve(__dirname, 'src/types'),
        '@assets': resolve(__dirname, 'src/assets')
      }
    },
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version || '1.0.0'),
      __BUILD_TIME__: JSON.stringify(new Date().toISOString())
    },
    server: {
      port: 3000,
      host: true,
      open: true,
      cors: true,
      
      // Enhanced proxy configuration for development
      proxy: {
        '/api': {
          target: 'http://192.168.1.1',
          changeOrigin: true,
          secure: false
        },
        '/user1.asp': {
          target: 'http://192.168.1.1',
          changeOrigin: true,
          secure: false
        }
      }
    },
    preview: {
      port: 4173,
      host: true,
      open: true
    },
    optimizeDeps: {
      include: ['vue', 'axios', 'vue-i18n'],
      exclude: ['@vueuse/core']
    },
    
    // Enhanced CSS configuration
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `@import "@/styles/variables.scss";`
        }
      },
      devSourcemap: !isProduction
    },
    
    // Enhanced logging
    logLevel: !isProduction ? 'info' : 'warn'
  };
});