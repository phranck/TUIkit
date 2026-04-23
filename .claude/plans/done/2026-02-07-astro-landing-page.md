# Astro Migration: Landing Page

## Completed

2026-02-07

## Preface

This plan migrates the TUIKit landing page from Next.js 16 to Astro, leveraging Astro's Islands Architecture for zero-JS delivery of static content while preserving React components for interactive elements. The HeroTerminal with CRT effects, TerminalScreen animation, and theme system become React Islands. Static content (FeatureCards, CodePreview, footer) renders as pure Astro components with no client-side JavaScript. Expected outcome: faster initial load, smaller bundle, same visual experience.

## Context / Problem

The current Next.js 16 landing page ships a full React runtime even though most content is static:

- **HeroTerminal** (690+ lines): CRT monitor simulation with audio (Howler.js), power on/off animation, zoom effects
- **TerminalScreen** (457 lines): Multi-scene typing animation with glitch effects
- **Static content**: FeatureCards, CodePreview, PackageBadge, SiteNav, SiteFooter

Next.js static export works but includes React hydration for the entire page. Astro's partial hydration would deliver static content as pure HTML while keeping React only for interactive islands.

## Specification / Goal

1. **Zero JS for static content**: FeatureCards, CodePreview, footer, nav render without JavaScript
2. **React Islands for interactivity**: HeroTerminal, TerminalScreen, ThemeSwitcher, RainOverlay, SpinnerLights
3. **Preserve all visual effects**: CRT simulation, typing animation, audio, theme switching
4. **Maintain build scripts**: `generate-terminal-data.ts`, `update-plans-data.ts` continue working
5. **Same deployment**: GitHub Pages static export
6. **Tailwind 4 compatibility**: Migrate CSS-first Tailwind config to Astro

## Design

### Component Classification

| Component | Type | Hydration Strategy |
|-----------|------|-------------------|
| HeroTerminal | React Island | `client:load` (above fold, audio) |
| TerminalScreen | React Island | `client:load` (animation critical) |
| ThemeSwitcher | React Island | `client:load` (immediate interactivity) |
| ThemeProvider | React Context | Wrap islands, blocking script in head |
| RainOverlay | React Island | `client:visible` (canvas, can defer) |
| SpinnerLights | React Island | `client:visible` (decorative) |
| CloudBackground | Astro | CSS-only keyframes |
| FeatureCard | Astro | Static HTML |
| CodePreview | React Island | `client:visible` (copy button) |
| PackageBadge | React Island | `client:visible` (copy button) |
| SiteNav | Astro + Alpine | Mobile toggle only |
| SiteFooter | Astro | Static HTML |

### Directory Structure

```
docs/
├── src/
│   ├── layouts/
│   │   └── BaseLayout.astro      # HTML shell, fonts, theme script
│   ├── pages/
│   │   └── index.astro           # Landing page composition
│   ├── components/
│   │   ├── astro/                # Pure Astro components
│   │   │   ├── CloudBackground.astro
│   │   │   ├── FeatureCard.astro
│   │   │   └── SiteFooter.astro
│   │   └── react/                # React Islands (existing, adapted)
│   │       ├── HeroTerminal.tsx
│   │       ├── TerminalScreen.tsx
│   │       ├── ThemeSwitcher.tsx
│   │       └── ...
│   └── styles/
│       └── global.css            # Tailwind + theme variables
├── public/
│   ├── fonts/
│   ├── sounds/
│   └── data/
├── scripts/                      # Existing build scripts
├── astro.config.mjs
└── package.json
```

### Theme System Migration

The theme system uses CSS custom properties with a blocking script. This works identically in Astro:

1. **Blocking script in `<head>`**: Reads localStorage, sets `data-theme` attribute before paint
2. **ThemeSwitcher React Island**: Updates localStorage + attribute
3. **CSS custom properties**: No change needed

### Font Strategy

Replace `next/font/google` with direct font loading:

```astro
<!-- BaseLayout.astro -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&family=Geist+Mono&display=swap" rel="stylesheet">
```

WarText.ttf stays in `/public/fonts/` with `@font-face` in CSS.

## Implementation Plan

### Phase 1: Project Setup

- [ ] Create new Astro project alongside existing Next.js
- [ ] Configure Astro with React integration (`@astrojs/react`)
- [ ] Configure Tailwind 4 (`@astrojs/tailwind`)
- [ ] Copy `public/` assets (fonts, sounds, data)
- [ ] Migrate `globals.css` theme variables

### Phase 2: Static Components

- [ ] Create `BaseLayout.astro` with font loading and theme script
- [ ] Convert `CloudBackground` to Astro (CSS-only)
- [ ] Convert `FeatureCard` to Astro
- [ ] Convert `SiteFooter` to Astro
- [ ] Create `SiteNav.astro` with mobile toggle (Alpine.js or vanilla JS)

### Phase 3: React Islands

- [ ] Copy `HeroTerminal.tsx` and adapt imports
- [ ] Copy `TerminalScreen.tsx` (no changes needed)
- [ ] Copy `ThemeSwitcher.tsx` and remove next/navigation deps
- [ ] Copy `RainOverlay.tsx` and `SpinnerLights.tsx`
- [ ] Copy hooks: `useCopyToClipboard.ts`

### Phase 4: Landing Page Composition

- [ ] Create `index.astro` with island integration
- [ ] Wire up theme context for React islands
- [ ] Test audio playback (Howler.js)
- [ ] Test all animations and effects
- [ ] Verify theme switching across islands

### Phase 5: Build Integration

- [ ] Adapt `generate-terminal-data.ts` for Astro
- [ ] Configure static export for GitHub Pages
- [ ] Update CI workflow for Astro build
- [ ] Performance comparison (Lighthouse)

## Checklist

- [x] Astro project created with React + Tailwind integrations
- [x] `public/` assets copied
- [x] `globals.css` migrated with theme variables
- [x] `BaseLayout.astro` created
- [x] Static components converted (CloudBackground, FeatureCard, SiteFooter, SiteNav)
- [x] React islands integrated (HeroTerminal, TerminalScreen, ThemeSwitcher, RainOverlay, SpinnerLights)
- [x] `index.astro` landing page complete
- [x] Theme switching works across all islands
- [x] Audio playback works
- [x] All animations work
- [x] Build scripts adapted
- [ ] GitHub Pages deployment configured
- [ ] Lighthouse performance comparison documented

## Open Questions

1. **Parallel development?** Keep Next.js running until Astro is complete, or replace immediately?
2. **Alpine.js for nav?** Use Alpine for mobile nav toggle, or vanilla JS to avoid another dependency?
3. **Shared state between islands**: Theme context works via CSS variables, but do any other islands need shared React state?

## Dependencies

- `astro` (latest)
- `@astrojs/react`
- `@astrojs/tailwind`
- `react`, `react-dom` (existing)
- `howler` (existing, for audio)
- `framer-motion` (not needed for landing page)

## Files

### New Files
- `docs/astro.config.mjs`
- `docs/src/layouts/BaseLayout.astro`
- `docs/src/pages/index.astro`
- `docs/src/components/astro/*.astro`

### Migrated Files (React)
- `HeroTerminal.tsx`
- `TerminalScreen.tsx`
- `ThemeSwitcher.tsx`
- `RainOverlay.tsx`
- `SpinnerLights.tsx`
- `CodePreview.tsx`
- `PackageBadge.tsx`

### Removed (Next.js specific)
- `next.config.ts`
- `app/layout.tsx`
- `app/page.tsx`
