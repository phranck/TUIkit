# Project Dashboard — Live GitHub Metrics Page

## Goal

Eine `/dashboard`-Unterseite der Landing Page, die alle relevanten Projekt- und GitHub-Metriken live visualisiert. Gleicher Retro-Phosphor-Stil wie die Landing Page. Alle Daten client-side via GitHub REST API (public, kein Token nötig).

## Tech Stack

- Next.js App Router (neue Route `app/dashboard/page.tsx`)
- Tailwind CSS v4 (bestehende Theme-Variablen)
- GitHub REST API (client-side fetch, 60 req/h unauthenticated)
- Kein Chart-Library — custom SVG/CSS Visualisierungen (konsistent mit dem Retro-Stil)

## Data Strategy

Alles client-side via `useGitHubStats()` Hook. Ein `useEffect` auf Mount feuert ~12 parallele API-Requests, cached im React State. Kein Build-time-Data, kein Token.

### API-Endpunkte

| Endpunkt | Daten | Requests |
|---|---|---|
| `GET /repos/:owner/:repo` | Stars, Forks, Watchers, Size, License, Dates | 1 |
| `GET /repos/:owner/:repo/commits?per_page=20` | Letzte 20 Commits (Message, Author, Date, SHA) | 1 |
| `GET /repos/:owner/:repo/commits?per_page=1` | Total Commit Count (via Link header) | 1 |
| `GET /repos/:owner/:repo/languages` | Language Breakdown (Bytes pro Sprache) | 1 |
| `GET /repos/:owner/:repo/stats/commit_activity` | Weekly Activity (52 Wochen, Tage aufgeschlüsselt) | 1 |
| `GET /repos/:owner/:repo/pulls?state=open&per_page=1` | Open PR Count (via Link header) | 1 |
| `GET /repos/:owner/:repo/pulls?state=closed&per_page=1` | Closed PR Count | 1 |
| `GET /repos/:owner/:repo/issues?state=closed&per_page=1` | Closed Issues Count | 1 |
| `GET /repos/:owner/:repo/releases?per_page=1` | Releases Count | 1 |
| `GET /repos/:owner/:repo/contributors?per_page=1` | Contributors Count | 1 |
| `GET /repos/:owner/:repo/branches?per_page=1` | Branches Count | 1 |
| `GET /repos/:owner/:repo/tags?per_page=1` | Tags Count | 1 |
| `GET /search/issues?q=repo:...+is:pr+is:merged` | Merged PR Count | 1 |

**Total: ~13 Requests pro Page Load** (unter dem 60/h Limit bei normalem Browsen).

### Rate Limiting

- Anzeige des verbleibenden Rate Limits im Footer
- Graceful degradation: Bei 403 → Fehlermeldung statt Crash
- Kein Auto-Refresh — nur bei Page Load + manuellem Refresh-Button

### Refresh

Manueller Refresh-Button im Header (neben dem Titel). Zeigt Lade-Spinner während Fetch läuft. Kein Auto-Refresh — bei 13 req pro Fetch und 60 req/h Limit ist manuell die sicherste Option.

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
| `app/hooks/useGitHubStats.ts` | GitHub API hook (alle Daten) |
| `app/components/StatCard.tsx` | Einzelne Metrik-Karte (Zahl + Label + Icon) |
| `app/components/ActivityHeatmap.tsx` | 52-Wochen Commit-Heatmap (GitHub-Style, aber Phosphor-Farben) |
| `app/components/LanguageBar.tsx` | Horizontaler gestapelter Balken (Language Breakdown) |
| `app/components/CommitList.tsx` | Letzte 20 Commits (SHA, Message, Author, relative Time) |
| `app/components/RepoInfo.tsx` | Repo-Metadaten (Created, License, Size, Last Push) |

### Modified Files

| File | Change |
|---|---|
| `app/page.tsx` | Nav: "Dashboard" Link hinzufügen |

## Visual Design

- **Stat Cards**: `border-border bg-frosted-glass backdrop-blur-xl` (wie FeatureCard)
- **Zahlen**: Große `text-4xl font-bold text-foreground` mit `text-glow` Utility
- **Labels**: `text-muted text-lg`
- **Heatmap**: CSS Grid 7×52, Zellen als `rounded-sm`, Intensität über `opacity` auf `bg-accent`
- **Language Bar**: Horizontaler Balken, Segmente proportional, Farben: accent für Swift, muted für Rest
- **Commit List**: Monospace SHA (`font-mono text-accent`), volle Commit Message (Title immer sichtbar, Body ausklappbar bei Multi-line), relative Time in `text-muted`
- **Loading State**: Skeleton/Pulse-Animation auf allen Karten
- **Error State**: Dezente Fehlermeldung mit Retry-Hint

## Implementation Plan

### 1. GitHub API Hook

- [ ] `useGitHubStats.ts` — Types, fetch logic, parallel requests, error handling
- [ ] Rate limit tracking (remaining/limit aus Response Headers)
- [ ] AbortController für cleanup bei unmount
- [ ] `refresh()` Funktion im Hook-Return für manuellen Re-fetch

### 2. Dashboard Components

- [ ] `StatCard.tsx` — Icon + Zahl + Label, Loading-Skeleton
- [ ] `ActivityHeatmap.tsx` — CSS Grid, 7 Rows × 52 Cols, Tooltip mit Datum/Count
- [ ] `LanguageBar.tsx` — Stacked bar + Legend, Prozent-Berechnung
- [ ] `CommitList.tsx` — SHA-Link, volle Message (Title + ausklappbarer Body), Author, relative Time Helper
- [ ] `RepoInfo.tsx` — Metadaten-Grid (Created, License, Size, Last Push, Branch)

### 3. Dashboard Page

- [ ] `app/dashboard/page.tsx` — Layout mit allen Components
- [ ] Loading state (Skeleton)
- [ ] Error state (Rate limit exceeded / Network error)
- [ ] Rate limit Anzeige im Footer

### 4. Navigation

- [ ] "Dashboard" Link in Nav (Landing Page + Dashboard)
- [ ] Shared Nav Component extrahieren (optional, wenn sinnvoll)

### 5. Quality

- [ ] `npm run build` (static export)
- [ ] `npm run lint` (ESLint)
- [ ] Responsive check (Mobile + Desktop)
- [ ] Theme check (alle 6 Phosphor-Themes)

## Open Questions

1. **Auto-Refresh?** Timer der alle 5 Minuten neu fetcht? Erstmal nein — nur bei Page Load. Kann später ergänzt werden.
2. **Shared Nav?** Die Nav ist aktuell inline in `page.tsx`. Sollte als eigene Komponente extrahiert werden damit Dashboard die gleiche Nav hat. Aber: minimal-invasiv — könnte auch kopiert werden.
3. **Chart Library?** Recharts, Chart.js? Nein — custom SVG/CSS passt besser zum Retro-Stil und vermeidet eine Dependency.
