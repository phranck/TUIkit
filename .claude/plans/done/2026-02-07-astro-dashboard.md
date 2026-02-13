# Astro Migration: Dashboard

## Completed

2026-02-07

## Preface

This plan migrates the TUIKit Dashboard from Next.js 16 to Astro, building on the landing page migration. The dashboard is more interactive than the landing page: StatCards, ActivityHeatmap, CommitList, PlansCard, and AvatarMarquee all require client-side JavaScript. These become React Islands with appropriate hydration strategies. Data fetching via `useGitHubStats` and localStorage caching remain client-side. The result is a dashboard that loads faster while maintaining all interactivity including Framer Motion animations.

## Context / Problem

The dashboard (`/dashboard`) is a data-heavy page with multiple interactive components:

- **StatCards**: Click handlers, loading states, refresh button
- **ActivityHeatmap**: 52-week calendar, hover popovers, responsive resize
- **CommitList**: Expandable commit bodies, Framer Motion enter/exit animations
- **PlansCard**: Collapsible sections, markdown rendering
- **AvatarMarquee**: Touch/mouse drag, momentum scrolling, stargazer popovers
- **Data fetching**: 13 parallel GitHub API calls, localStorage caching with 5-min TTL

Unlike the landing page, the dashboard has minimal static content. However, Astro still provides benefits:

1. **Selective hydration**: Islands load independently, improving perceived performance
2. **Consistent architecture**: Same build system as landing page
3. **Better code splitting**: Each island is its own chunk

## Specification / Goal

1. **All dashboard features preserved**: StatCards, heatmap, commits, plans, avatars
2. **Framer Motion animations**: CommitList enter/exit, PlansCard collapse
3. **Data fetching unchanged**: Client-side GitHub API with localStorage cache
4. **Auto-refresh**: 5-min cache TTL with force-refresh button
5. **Responsive behavior**: Mobile-optimized layout, hidden heatmap on phones
6. **Same routing**: `/dashboard` path maintained

## Design

### Component Classification

| Component | Type | Hydration Strategy |
|-----------|------|-------------------|
| DashboardLayout | Astro | Page shell, CSS grid |
| StatCard | React Island | `client:load` (above fold, click handlers) |
| RefreshButton | React Island | `client:load` (interactive) |
| ActivityHeatmap | React Island | `client:visible` (below fold on mobile) |
| CommitList | React Island | `client:visible` (Framer Motion) |
| PlansCard | React Island | `client:visible` (collapsible sections) |
| AvatarMarquee | React Island | `client:visible` (drag/swipe) |
| StargazersPanel | React Island | `client:visible` (wrapper for marquee) |
| RepoInfo | Astro | Static metadata |
| LanguageBar | React Island | `client:visible` (needs data from hook) |

### Data Fetching Architecture

The current `useGitHubStats` + `useGitHubStatsCache` pattern works well but requires shared state across multiple islands. Options:

**Option A: Single Data Provider Island**
```astro
<!-- dashboard.astro -->
<DashboardDataProvider client:load>
  <!-- All dashboard islands nested inside -->
</DashboardDataProvider>
```
- Pro: Clean separation, single fetch
- Con: All islands must be children of provider

**Option B: Zustand/Jotai Store**
```typescript
// stores/github-stats.ts
export const useGitHubStore = create((set) => ({
  stats: null,
  fetch: async () => { ... }
}))
```
- Pro: Any island can access data independently
- Con: Adds dependency, store hydration complexity

**Option C: Keep Current Hooks, Lift to Single Island**
```astro
<DashboardContent client:load />
<!-- Single React component containing all dashboard UI -->
```
- Pro: Minimal changes to existing code
- Con: Less island granularity

**Recommendation**: Option C for initial migration. The dashboard is inherently interactive and tightly coupled. A single `DashboardContent` island containing all existing components preserves the current architecture while still benefiting from Astro's static shell.

### Directory Structure

```
docs/
├── src/
│   ├── pages/
│   │   ├── index.astro           # Landing page
│   │   └── dashboard.astro       # Dashboard page
│   ├── components/
│   │   └── react/
│   │       ├── dashboard/
│   │       │   ├── DashboardContent.tsx  # Main island
│   │       │   ├── StatCard.tsx
│   │       │   ├── ActivityHeatmap.tsx
│   │       │   ├── CommitList.tsx
│   │       │   ├── PlansCard.tsx
│   │       │   ├── AvatarMarquee.tsx
│   │       │   └── ...
│   │       └── shared/
│   │           └── ThemeSwitcher.tsx
│   └── hooks/
│       ├── useGitHubStats.ts
│       ├── useGitHubStatsCache.ts
│       └── usePlansCache.ts
```

### Framer Motion Consideration

Framer Motion works in React islands without issues. The `AnimatePresence` wrapper and motion components function identically. No changes needed.

### Environment Variables

Current `NEXT_PUBLIC_GITHUB_TOKEN` becomes `PUBLIC_GITHUB_TOKEN` in Astro (same `VITE_` prefix convention):

```javascript
// astro.config.mjs
export default defineConfig({
  vite: {
    define: {
      'import.meta.env.PUBLIC_GITHUB_TOKEN': JSON.stringify(process.env.GITHUB_TOKEN)
    }
  }
})
```

## Implementation Plan

### Phase 1: Dashboard Page Setup

- [ ] Create `dashboard.astro` page
- [ ] Set up routing (Astro file-based routing handles `/dashboard`)
- [ ] Create page shell with navigation and footer

### Phase 2: Dashboard Island

- [ ] Create `DashboardContent.tsx` as main island
- [ ] Copy all dashboard components into `components/react/dashboard/`
- [ ] Copy hooks into `hooks/`
- [ ] Adapt imports (remove Next.js specific)

### Phase 3: Data Layer

- [ ] Update `useGitHubStats.ts` for Vite env vars
- [ ] Verify localStorage caching works
- [ ] Test auto-refresh timer
- [ ] Test force-refresh button

### Phase 4: Component Migration

- [ ] StatCard: Remove any Next.js deps
- [ ] ActivityHeatmap: Verify ResizeObserver works
- [ ] CommitList: Verify Framer Motion animations
- [ ] PlansCard: Verify markdown rendering (react-markdown)
- [ ] AvatarMarquee: Verify touch/drag interactions
- [ ] StargazersPanel + StargazerPopoverContent

### Phase 5: Integration Testing

- [ ] Test theme switching on dashboard
- [ ] Test mobile responsive behavior
- [ ] Test all click handlers and interactions
- [ ] Test loading states and error handling
- [ ] Verify public data files load (`plans.json`, `social-cache.json`)

### Phase 6: Build and Deploy

- [ ] Update build scripts if needed
- [ ] Configure Astro routing for GitHub Pages
- [ ] Update CI workflow
- [ ] Performance comparison

## Checklist

- [x] `dashboard.astro` page created
- [x] `DashboardContent.tsx` island created
- [x] All dashboard components migrated
- [x] Hooks migrated with Vite env vars
- [x] localStorage caching works
- [x] Auto-refresh works
- [x] Force-refresh button works
- [x] StatCard click handlers work
- [x] ActivityHeatmap hover popovers work
- [x] CommitList Framer Motion animations work
- [x] PlansCard collapse animations work
- [x] AvatarMarquee drag/swipe works
- [x] Theme switching works on dashboard
- [x] Mobile responsive layout works
- [ ] GitHub Pages deployment works
- [ ] Performance comparison documented

## Open Questions

1. **Granular islands vs. single island?** Start with single `DashboardContent` island for simplicity, or invest in Zustand for independent islands?
2. **SSR data?** Could fetch initial stats at build time as fallback, but staleness is a concern. Worth it?
3. **Skeleton loading**: Currently handled in React. Astro could show static skeleton before hydration. Worth the complexity?

## Dependencies

- All landing page dependencies, plus:
- `framer-motion` (existing, for CommitList animations)
- `react-markdown` (existing, for PlansCard)
- `@heroicons/react` (replaced sf-symbols-lib, 26KB vs 26MB)

## Files

### New Files
- `docs/src/pages/dashboard.astro`
- `docs/src/components/react/dashboard/DashboardContent.tsx`

### Migrated Files
- `StatCard.tsx`
- `ActivityHeatmap.tsx`
- `CommitList.tsx`
- `PlansCard.tsx`
- `AvatarMarquee.tsx`
- `StargazersPanel.tsx`
- `StargazerPopoverContent.tsx`
- `LanguageBar.tsx`
- `RepoInfo.tsx`
- `HoverPopover.tsx`
- `useGitHubStats.ts`
- `useGitHubStatsCache.ts`
- `usePlansCache.ts`
- `useHoverPopover.ts`

### Removed (Next.js specific)
- `app/dashboard/page.tsx`

## Sequencing Note

This plan depends on the landing page migration being complete first. The shared infrastructure (Astro config, Tailwind, theme system, base layout) is established in that plan.
