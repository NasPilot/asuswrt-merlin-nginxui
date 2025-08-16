import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import cssInjectedByJsPlugin from 'vite-plugin-css-injected-by-js';
import { visualizer } from 'rollup-plugin-visualizer';
import fs from 'fs';
import { resolve } from 'path';

// Simplified shell file watcher (based on XrayUI pattern)
function watchShellFiles() {
  return {
    name: 'watch-shell-files',
    buildStart(this: any) {
      const backendDir = resolve(__dirname, 'src/backend');
      if (fs.existsSync(backendDir)) {
        this.addWatchFile(backendDir);
        console.log('Watching backend shell files for changes...');
      }
    }
  };
}

// Build info generator
function generateBuildInfo() {
  return {
    name: 'generate-build-info',
    generateBundle(this: any) {
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

// Inline shell imports (simplified version)
function inlineShellImports() {
  return {
    name: 'inline-shell-imports',
    transform(code: string, id: string) {
      if (id.endsWith('.ts') || id.endsWith('.js')) {
        // Simple shell import replacement
        return code.replace(
          /import\s+['"]([^'"]+\.sh)['"];?/g,
          (match, shellPath) => {
            try {
              const fullPath = resolve(process.cwd(), 'src/backend', shellPath);
              if (fs.existsSync(fullPath)) {
                const content = fs.readFileSync(fullPath, 'utf-8');
                return `const shellScript = ${JSON.stringify(content)};`;
              }
            } catch (error) {
              console.warn(`Failed to inline shell script: ${shellPath}`);
            }
            return match;
          }
        );
      }
      return null;
    }
  };
}

export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    cssInjectedByJsPlugin(),
    watchShellFiles(),
    inlineShellImports(),
    generateBuildInfo(),
    ...(mode === 'analyze' ? [visualizer({ filename: 'dist/stats.html', open: true })] : [])
  ],
  
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        app: resolve(__dirname, 'src/main.ts')
      },
      output: {
        entryFileNames: 'app.js',
        assetFileNames: (assetInfo) => {
          if (assetInfo.name?.endsWith('.css')) {
            return 'app.css';
          }
          return '[name].[ext]';
        },
        manualChunks: undefined
      }
    },
    minify: mode === 'production',
    sourcemap: mode === 'development'
  },
  
  define: {
    __DEV__: mode === 'development',
    __VERSION__: JSON.stringify(process.env.npm_package_version || '1.0.0')
  },
  
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@components': resolve(__dirname, 'src/components'),
      '@modules': resolve(__dirname, 'src/modules'),
      '@views': resolve(__dirname, 'src/views')
    }
  },
  
  server: {
    port: 3000,
    open: false,
    cors: true
  }
}));