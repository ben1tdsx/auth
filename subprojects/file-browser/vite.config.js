import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration from environment variables
const VITE_PORT = parseInt(process.env.VITE_PORT || process.env.PORT || '5173', 10);
const VITE_HOST = process.env.VITE_HOST || process.env.HOST || '0.0.0.0'; // Default to 0.0.0.0 for remote access
const API_SERVER_URL = process.env.VITE_API_URL || process.env.API_URL || 'http://localhost:3001';

export default defineConfig({
  plugins: [vue()],
  build: {
    outDir: 'dist',
    emptyOutDir: true
  },
  server: {
    host: VITE_HOST,
    port: VITE_PORT,
    open: process.env.VITE_OPEN !== 'false' ? '/login' : false,
    proxy: {
      '/api': {
        target: API_SERVER_URL,
        changeOrigin: true
      },
      '/logout': {
        target: API_SERVER_URL,
        changeOrigin: true
      },
      '/health': {
        target: API_SERVER_URL,
        changeOrigin: true
      }
    }
  }
});

