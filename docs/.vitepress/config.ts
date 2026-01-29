import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "TUIKit",
  description: "A declarative, SwiftUI-like framework for building Terminal User Interfaces in Swift",
  lang: 'en-US',

  head: [
    ['meta', { name: 'theme-color', content: '#10b981' }],
    ['link', { rel: 'icon', href: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y="75" font-size="75">▂</text></svg>' }],
  ],

  themeConfig: {
    logo: '/logo.svg',
    siteTitle: 'TUIKit',

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'API', link: '/api/overview' },
      { text: 'GitHub', link: 'https://github.com/phranck/SwiftTUI' }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/getting-started' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quick-start' },
          ]
        },
        {
          text: 'Core Concepts',
          items: [
            { text: 'Views', link: '/guide/views' },
            { text: 'State Management', link: '/guide/state' },
            { text: 'Styling', link: '/guide/styling' },
            { text: 'Themes', link: '/guide/themes' },
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/overview' },
            { text: 'Components', link: '/api/components' },
            { text: 'Modifiers', link: '/api/modifiers' },
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/phranck/SwiftTUI' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024-present Frank Gregor'
    },

    search: {
      provider: 'local'
    }
  },

  markdown: {
    lineNumbers: true,
    theme: {
      light: 'github-light',
      dark: 'github-dark'
    }
  }
})
