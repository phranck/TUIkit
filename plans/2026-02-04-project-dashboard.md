# Project Dashboard — Live GitHub Metrics Page

## Completed

Completed 2026-02-04. Dashboard live at `/dashboard` with stat cards, commit heatmap, language bar, commit list, stargazer panel, shared nav, and rate limit display.

---

## Goal

A `/dashboard` subpage of the Landing Page that visualizes all relevant project and GitHub metrics live. Same retro phosphor style as the Landing Page. All data fetched client-side via GitHub REST API (public, no token required).

## Tech Stack

- Next.js App Router (new route `app/dashboard/page.tsx`)
- Tailwind CSS v4 (existing theme variables)
- GitHub REST API (client-side fetch, 60 req/h unauthenticated)
- No chart library — custom SVG/CSS visualizations (consistent with retro style)

## Data Strategy

All client-side via `useGitHubStats()` hook. A `useEffect` on mount fires ~12 parallel API requests, cached in React State. No build-time data, no token.

### API Endpoints

| Endpoint | Data | Requests |
|---|---|---|
| `GET /repos/:owner/:repo` | Stars, Forks, Watchers, Size, License, Dates | 1 |
| `GET /repos/:owner/:repo/commits?per_page=20` | Last 20 Commits (Message, Author, Date, SHA) | 1 |
| `GET /repos/:owner/:repo/commits?per_page=1` | Total Commit Count (via Link header) | 1 |
| `GET /repos/:owner/:repo/languages` | Language Breakdown (Bytes per language) | 1 |
| `GET /repos/:owner/:repo/stats/commit_activity` | Weekly Activity (52 weeks, days breakdown) | 1 |
| `GET /repos/:owner/:repo/pulls?state=open&per_page=1` | Open PR Count (via Link header) | 1 |
| `GET /repos/:owner/:repo/pulls?state=closed&per_page=1` | Closed PR Count | 1 |
| `GET /repos/:owner/:repo/issues?state=closed&per_page=1` | Closed Issues Count | 1 |
| `GET /repos/:owner/:repo/releases?per_page=1` | Releases Count | 1 |
| `GET /repos/:owner/:repo/contributors?per_page=1` | Contributors Count | 1 |
| `GET /repos/:owner/:repo/branches?per_page=1` | Branches Count | 1 |
| `GET /repos/:owner/:repo/tags?per_page=1` | Tags Count | 1 |
| `GET /search/issues?q=repo:...+is:pr+is:merged` | Merged PR Count | 1 |

**Total: ~13 Requests per Page Load** (under the 60/h limit with normal browsing).

### Rate Limiting

- Display remaining rate limit in footer
- Graceful degradation: On 403 → error message instead of crash
- No auto-refresh — only on page load + manual refresh button

### Refresh

Manual refresh button in header (next to the title). Shows loading spinner during fetch. No auto-refresh — with 13 req per fetch and 60 req/h limit, manual is the safest option.

## Layout

```
┌────────────────────────────────────────────────────────────┐
│ Nav (same as landing page)                  Dashboard link │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │ TUIKit Dashboard                      [↻ Refresh]  │    │
│  │ Live project metrics · phranck/TUIKit              │    │
│  └────────────────────────────────────────────────────┘    │
│                                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Commits  │ │ Stars    │ │ PRs      │ │ Issues   │       │
│  │ 389      │ │ 3        │ │ 71       │ │ 12       │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│                                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Branches │ │ Tags     │ │ Contribs │ │ Releases │       │
│  │ 8        │ │ 5        │ │ 2        │ │ 0        │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │ Commit Activity (52 weeks heatmap)                 │    │
│  │ ░░░░▓▓░░▓▓▓░░░▓▓▓▓▓▓░░░▓▓▓░░░░░░▓▓▓▓▓▓▓▓░░░░░░     │    │
│  │ Mon                                           Sun  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                            │
│  ┌──────────────────┐ ┌─────────────────────────────┐      │
│  │ Languages        │ │ Recent Commits              │      │
│  │ ████████░ Swf 94%│ │ be2f739 Feat: Add subtree   │      │
│  │ ██░░░░░░ CSS  4% │ │   memoization via Equata..  │      │
│  │ █░░░░░░░ Oth  2% │ │   [▸ show body]             │      │
│  └──────────────────┘ │ 9cdcc39 Fix: Remove global  │      │
│                       │   RenderNotifier mutation.. │      │
│                       │ b986331 Merge PR #70        │      │
│                       │ ...                         │      │
│                       └─────────────────────────────┘      │
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │ Repo Info                                          │    │
│  │ Created: 2026-01-28  License: CC BY-NC-SA 4.0      │    │
│  │ Size: 4.2 MB         Default Branch: main          │    │
│  │ Last Push: 2 hours ago                             │    │
│  └────────────────────────────────────────────────────┘    │
│                                                            │
│  Rate Limit: 47/60 remaining                               │
└────────────────────────────────────────────────────────────┘
```

## Components

### New Files

| File | Purpose |
|---|---|
| `app/dashboard/page.tsx` | Dashboard route + layout |
| `app/hooks/useGitHubStats.ts` | GitHub API hook (all data) |
| `app/components/StatCard.tsx` | Single metric card (number + label + icon) |
| `app/components/ActivityHeatmap.tsx` | 52-week commit heatmap (GitHub-style, but phosphor colors) |
| `app/components/LanguageBar.tsx` | Horizontal stacked bar (language breakdown) |
| `app/components/CommitList.tsx` | Last 20 commits (SHA, message, author, relative time) |
| `app/components/RepoInfo.tsx` | Repo metadata (Created, License, Size, Last Push) |

### Modified Files

| File | Change |
|---|---|
| `app/page.tsx` | Nav: Add "Dashboard" link |

## Visual Design

- **Stat Cards**: `border-border bg-frosted-glass backdrop-blur-xl` (like FeatureCard)
- **Numbers**: Large `text-4xl font-bold text-foreground` with `text-glow` utility
- **Labels**: `text-muted text-lg`
- **Heatmap**: CSS Grid 7×52, cells as `rounded-sm`, intensity via `opacity` on `bg-accent`
- **Language Bar**: Horizontal bar, segments proportional, colors: accent for Swift, muted for rest
- **Commit List**: Monospace SHA (`font-mono text-accent`), full commit message (title always visible, body expandable for multi-line), relative time in `text-muted`
- **Loading State**: Skeleton/pulse animation on all cards
- **Error State**: Subtle error message with retry hint

## Implementation Plan

### 1. GitHub API Hook

- [x] `useGitHubStats.ts` — Types, fetch logic, parallel requests, error handling
- [x] Rate limit tracking (remaining/limit from response headers)
- [x] AbortController for cleanup on unmount
- [x] `refresh()` function in hook return for manual re-fetch

### 2. Dashboard Components

- [x] `StatCard.tsx` — Icon + number + label, loading skeleton
- [x] `ActivityHeatmap.tsx` — CSS Grid, 7 rows × 52 cols, tooltip with date/count
- [x] `LanguageBar.tsx` — Stacked bar + legend, percentage calculation
- [x] `CommitList.tsx` — SHA link, full message (title + expandable body), author, relative time helper
- [x] `RepoInfo.tsx` — Metadata grid (Created, License, Size, Last Push, Branch)

### 3. Dashboard Page

- [x] `app/dashboard/page.tsx` — Layout with all components
- [x] Loading state (skeleton)
- [x] Error state (rate limit exceeded / network error)
- [x] Rate limit display in footer

### 4. Navigation

- [x] "Dashboard" link in nav (Landing Page + Dashboard)
- [x] Extract shared nav component (optional, if useful)

### 5. Quality

- [x] `npm run build` (static export)
- [x] `npm run lint` (ESLint)
- [x] Responsive check (mobile + desktop)
- [x] Theme check (all 6 phosphor themes)

## Open Questions

1. **Auto-Refresh?** Timer that re-fetches every 5 minutes? For now no — only on page load. Can be added later.
2. **Shared Nav?** The nav is currently inline in `page.tsx`. Should be extracted as its own component so Dashboard has the same nav. But: minimal-invasive — could also be copied.
3. **Chart Library?** Recharts, Chart.js? No — custom SVG/CSS fits the retro style better and avoids a dependency.
