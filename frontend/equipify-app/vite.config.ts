import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Dev proxy avoids CORS entirely and lets /uploads resolve to the API too.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/images': 'http://localhost:5000',
      '/api': { target: 'http://localhost:5000', changeOrigin: true },
      '/uploads': { target: 'http://localhost:5000', changeOrigin: true },
    },
  },
})
