# Mobile Performance Optimization

## Completed

2026-02-07

## Preface

The docs site (Landing Page + Dashboard) runs poorly on iPhone due to heavy JavaScript bundles (548KB), expensive CSS effects (22 backdrop-blur instances, 6 animated cloud blurs), and continuous animations (rain canvas, spinner lights, avatar marquee). This plan removes Framer Motion, disables expensive effects on mobile via CSS media queries, and optimizes hydration timing to achieve smooth 60fps scrolling on mobile devices.

## Context/Problem

Performance audit identified:
- **Critical**: Framer Motion (278KB), 4x `client:load` React components, canvas rain at 60fps
- **High**: 22x `backdrop-blur-xl`, 6 cloud animations with blur-[120-150px], SpinnerLights box-shadows, Howler.js loaded on every page
- **Medium**: 100 avatar preload nodes, 5-function avatar filters, 3 font requests

iPhone users experience:
- Janky scrolling
- Delayed interactivity
- Battery drain from continuous animations

## Specification/Goal

1. Remove Framer Motion entirely (save 278KB)
2. Disable expensive CSS effects on mobile (`backdrop-blur`, cloud animations)
3. Change `client:load` to `client:visible` for below-fold components
4. Lazy-load Howler.js (only when user clicks power button)
5. Disable rain animation on mobile
6. Simplify SpinnerLights shadows on mobile
7. Achieve smooth scrolling on iPhone 12 and newer

## Design

### CSS-only Animations (replacing Framer Motion)

CommitList enter animation:
```css
@keyframes fade-slide-in {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}
.commit-item { animation: fade-slide-in 0.2s ease-out; }
```

Refresh icon rotation:
```css
@keyframes spin { to { transform: rotate(360deg); } }
.refresh-spinning { animation: spin 1s linear infinite; }
```

### Mobile Detection Strategy

Use CSS media queries, not JS detection:
```css
@media (max-width: 768px) {
  .backdrop-blur-xl { backdrop-filter: none; }
  .cloud-animation { display: none; }
  .rain-canvas { display: none; }
}
```

For JS components, use `window.matchMedia('(max-width: 768px)')` once on mount.

### Hydration Changes

| Component | Current | New |
|-----------|---------|-----|
| RainOverlay | `client:load` | Remove on mobile, `client:visible` on desktop |
| SpinnerLights | `client:load` | `client:visible` |
| SiteNav | `client:load` | `client:load` (needed for interaction) |
| HeroTerminal | `client:load` | `client:visible` |
| DashboardContent | `client:load` | `client:load` (main content) |

### Howler.js Lazy Loading

```typescript
// Before: import { Howl } from "howler"
// After: Dynamic import on first click
const playSound = async (src: string) => {
  const { Howl } = await import("howler");
  new Howl({ src: [src] }).play();
};
```

## Implementation Plan

### Phase 1: Remove Framer Motion (Critical)
1. Remove `framer-motion` from `package.json`
2. Replace `motion.div` with regular `div` + CSS classes in `CommitList.tsx`
3. Replace `AnimatePresence` with conditional rendering
4. Add CSS keyframe animations to `global.css`
5. Update refresh icon in `DashboardContent.tsx` to use CSS animation class

### Phase 2: Mobile CSS Optimizations (High)
1. Add `@media (max-width: 768px)` rules to disable:
   - `backdrop-blur-xl` (replace with solid bg-opacity)
   - Cloud animations in `CloudBackground.astro`
2. Add `.mobile-hidden` utility class
3. Apply to RainOverlay canvas

### Phase 3: Hydration Optimization (High)
1. Change `client:load` to `client:visible` for:
   - `SpinnerLights`
   - `HeroTerminal`
2. Conditionally render `RainOverlay` only on desktop (via Astro's responsive directives or CSS)

### Phase 4: Howler.js Lazy Load (Medium)
1. Remove static import of Howler
2. Create `useSound` hook with dynamic import
3. Update `HeroTerminal.tsx` to use lazy sound loading

### Phase 5: Additional Mobile Optimizations (Medium)
1. Simplify SpinnerLights box-shadow on mobile (single layer)
2. Reduce avatar filter complexity on mobile (grayscale only)
3. Disable AvatarMarquee animation on mobile (show static grid)

### Phase 6: Font Optimization (Low)
1. Add `<link rel="preconnect" href="https://fonts.googleapis.com">`
2. Combine font requests into single URL
3. Ensure `font-display: swap` is set

## Checklist

- [x] Phase 1: Remove Framer Motion, add CSS animations
- [x] Phase 2: Add mobile media queries for blur/clouds
- [x] Phase 3: Change hydration directives
- [x] Phase 4: Lazy-load Howler.js
- [x] Phase 5: Simplify SpinnerLights/Avatars on mobile
- [x] Phase 6: Optimize font loading
- [ ] Test on iPhone Safari
- [ ] Verify no visual regressions on desktop

## Files

- `docs/package.json`
- `docs/src/components/react/dashboard/CommitList.tsx`
- `docs/src/components/react/dashboard/DashboardContent.tsx`
- `docs/src/components/react/dashboard/AvatarMarquee.tsx`
- `docs/src/components/react/HeroTerminal.tsx`
- `docs/src/components/react/SpinnerLights.tsx`
- `docs/src/components/react/RainOverlay.tsx`
- `docs/src/components/astro/CloudBackground.astro`
- `docs/src/pages/index.astro`
- `docs/src/pages/dashboard.astro`
- `docs/src/styles/global.css`
- `docs/src/layouts/BaseLayout.astro`

## Dependencies

- None (removing dependency on framer-motion)
