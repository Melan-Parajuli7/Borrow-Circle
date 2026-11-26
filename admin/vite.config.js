import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// The Express API already sends CORS headers for the dev server origin,
// so no proxy is needed. Run the API on port 3000 and this app on 5173.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
  },
});