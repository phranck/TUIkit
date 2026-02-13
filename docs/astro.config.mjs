import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwindcss from '@tailwindcss/vite';
import fs from 'fs';

// Load project stats from prebuild script (if available)
let testCount = '0';
let suiteCount = '0';
try {
  const stats = JSON.parse(fs.readFileSync('./project-stats.json', 'utf-8'));
  testCount = String(stats.testCount ?? 0);
  suiteCount = String(stats.suiteCount ?? 0);
} catch {
  // File not found or invalid JSON, use defaults
}

// https://astro.build/config
export default defineConfig({
  site: 'https://tuikit.dev',
  output: 'static',
  integrations: [
    react(),
  ],
  vite: {
    plugins: [tailwindcss()],
    define: {
      'import.meta.env.PUBLIC_TUIKIT_VERSION': JSON.stringify(process.env.TUIKIT_VERSION ?? '0.1.0'),
      'import.meta.env.PUBLIC_TUIKIT_TEST_COUNT': JSON.stringify(testCount),
      'import.meta.env.PUBLIC_TUIKIT_SUITE_COUNT': JSON.stringify(suiteCount),
    },
  },
});
