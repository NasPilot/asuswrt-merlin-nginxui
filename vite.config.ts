/* eslint-disable  @typescript-eslint/no-unsafe-assignment */
/* eslint-disable  @typescript-eslint/no-unsafe-call */
/* eslint-disable  @typescript-eslint/no-unsafe-member-access */
/* eslint-disable  @typescript-eslint/no-unsafe-return */
/* eslint-disable  @typescript-eslint/no-unsafe-argument */
/* eslint-disable  @typescript-eslint/no-explicit-any */

import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import cssInjectedByJsPlugin from 'vite-plugin-css-injected-by-js';
import fs from 'fs';
import { dirname, join, resolve } from 'path';
import { fileURLToPath } from 'url';

function watchAllShFiles(pluginContext, dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  entries.forEach((entry) => {
    const fullPath = join(dir, entry.name);

    if (entry.isDirectory()) {
      watchAllShFiles(pluginContext, fullPath);
    } else if (entry.isFile() && fullPath.endsWith('.sh')) {
      pluginContext.addWatchFile(fullPath);
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

export default defineConfig({
  plugins: [
    vue(),
    cssInjectedByJsPlugin(),
    {
      name: 'shell-script-bundler',
      buildStart() {
        const backendDir = resolve(__dirname, 'src/backend');
        if (fs.existsSync(backendDir)) {
          watchAllShFiles(this, backendDir);
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
  ],
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: 'src/App.ts',
      output: {
        entryFileNames: 'nginxui.js',
        assetFileNames: (assetInfo) => {
          if (assetInfo.name?.endsWith('.css')) {
            return 'nginxui.css';
          }
          return assetInfo.name || 'asset';
        }
      }
    },
    minify: process.env.NODE_ENV === 'production'
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@modules': resolve(__dirname, 'src/modules'),
      '@components': resolve(__dirname, 'src/components')
    }
  }
});