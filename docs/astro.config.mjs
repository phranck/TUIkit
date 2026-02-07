import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://tuikit.layered.work',
  output: 'static',
  integrations: [
    react(),
  ],
  vite: {
    plugins: [tailwindcss()],
    define: {
      'import.meta.env.PUBLIC_TUIKIT_VERSION': JSON.stringify(process.env.TUIKIT_VERSION ?? '0.1.0'),
      'import.meta.env.PUBLIC_TUIKIT_TEST_COUNT': JSON.stringify(process.env.TUIKIT_TEST_COUNT ?? '0'),
      'import.meta.env.PUBLIC_TUIKIT_SUITE_COUNT': JSON.stringify(process.env.TUIKIT_SUITE_COUNT ?? '0'),
    },
  },
});
