import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true
  },
  define: {
    global: 'globalThis',
    'process.env': {},
    'process.version': '"v16.0.0"',
    'process.platform': '"browser"',
  },
  resolve: {
    alias: {
      process: 'process/browser',
      util: 'util',
    },
  },
  optimizeDeps: {
    include: ['process', 'util'],
  },
})
