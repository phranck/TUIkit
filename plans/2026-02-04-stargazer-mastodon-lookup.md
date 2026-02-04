# Stargazer Mastodon Lookup — Automatic Account Discovery

## Goal

Find Mastodon accounts for all repository stargazers and display/link them in the Dashboard popover. Multi-stage search combines GitHub profile data, username matching, and manual overrides.

## Tech Stack

- GitHub Actions (Scheduled Workflow, daily)
- Node.js/TypeScript script for Mastodon search
- JSON file as Mastodon data cache (committed to repo)
- Next.js client-side fetch for live stargazer list

## Data Strategy: Hybrid Approach

**Key insight:** Stargazers are already fetched live via GitHub API on every page load. Only the Mastodon lookup data needs caching (because it's expensive and slow).

```
┌─────────────────────────────────────────────────────────────┐
│  CLIENT (on every page load)                                │
│  ┌─────────────────┐                                        │
│  │ GitHub API      │──▶ Live stargazer list (login, avatar) │
│  │ /stargazers     │    Always up-to-date on reload!        │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
                                    +
┌─────────────────────────────────────────────────────────────┐
│  SCHEDULED (GitHub Action, daily)                           │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐   │
│  │ Fetch       │───▶│ Search       │───▶│ Generate      │   │
│  │ Stargazers  │    │ Mastodon     │    │ JSON          │   │
│  └─────────────┘    └──────────────┘    └───────────────┘   │
│                                                ▼            │
│                                    ┌────────────────────┐   │
│                                    │ mastodon-cache.json│   │
│                                    │ (committed to repo)│   │
│                                    └────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                    =
┌─────────────────────────────────────────────────────────────┐
│  MERGED at runtime                                          │
│  ┌─────────────────┐    ┌────────────────────┐              │
│  │ Live stargazers │ +  │ Cached Mastodon    │              │
│  │ from API        │    │ from JSON          │              │
│  └────────┬────────┘    └─────────┬──────────┘              │
│           │                       │                         │
│           └───────────┬───────────┘                         │
│                       ▼                                     │
│           ┌───────────────────────┐                         │
│           │ Stargazer with        │                         │
│           │ Mastodon info (if any)│                         │
│           └───────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### How it works

1. **Stargazers** are fetched **live** from GitHub API on every page load (existing behavior)
2. **Mastodon data** is loaded from a cached JSON file (fetched once, updated daily)
3. **Merge at runtime**: Match stargazers by `login` with Mastodon cache entries
4. **New stargazers** appear immediately — just without Mastodon info until next scheduled run

### Update Strategy: Incremental + Weekly Full Refresh

```
┌─────────────────────────────────────────────────────────────┐
│  FIRST RUN                                                  │
│  └── All stargazers → full Mastodon search                  │
├─────────────────────────────────────────────────────────────┤
│  EVERY 2 HOURS (incremental)                                │
│  └── Compare current stargazers with cache                  │
│      └── Only search Mastodon for NEW stargazers            │
│      └── Skip already-cached entries                        │
├─────────────────────────────────────────────────────────────┤
│  WEEKLY (Sundays 4 AM UTC)                                  │
│  └── Full refresh of ALL stargazers                         │
│      └── Catches updated bios, changed Mastodon handles     │
│      └── Removes entries for users who unstarred            │
└─────────────────────────────────────────────────────────────┘
```

### How incremental works

1. Load existing `mastodon-cache.json`
2. Fetch current stargazers from GitHub API
3. Find `newStargazers = current - cached`
4. Only run Mastodon search for `newStargazers`
5. Merge results into cache
6. On weekly run: ignore cache, search all

### Advantages

- ✅ **New stargazers appear immediately** on page reload
- ✅ No server costs
- ✅ Stays fully static on GitHub Pages
- ✅ Mastodon search runs in CI (more time, no client timeout)
- ✅ Data is cached (JSON in repo)
- ✅ Manual corrections possible (edit JSON)

### Trade-offs

- New stargazer's Mastodon info appears after next scheduled run (max 2h delay)
- This is acceptable: Mastodon info is a nice-to-have, not critical

## API Limitations

### GitHub API

- **No public endpoint for social accounts!** `/users/{username}/social_accounts` does NOT exist
- Only `/user/social_accounts` for the authenticated user themselves
- **Rate Limits:**
  - Unauthenticated: 60 req/hour
  - With `GITHUB_TOKEN` (in Actions): 1,000 req/hour
  - With Personal Access Token: 5,000 req/hour ✅
- **Available data:**

| Endpoint | Data |
|---|---|
| `GET /users/{username}` | `bio`, `blog`, `avatar_url`, `name` |

### Mastodon API

- Lookup: `https://{instance}/api/v1/accounts/lookup?acct={username}`
- Problem: You need to know the instance (there are thousands)
- Rate limits vary per instance

## Search Strategies (Prioritized)

| Priority | Source | Method | Reliability |
|---|---|---|---|
| 1 | Manual Overrides | `mastodon-overrides.json` | ✅ 100% |
| 2 | GitHub Bio | Regex for `@user@instance` | ✅ High |
| 3 | GitHub Blog | URL parse for Mastodon instances | ✅ High |
| 4 | Username Match | Same username on known instances | ⚠️ Medium |
| 5 | Avatar Comparison | Same avatar = strong hint | ⚠️ Medium (later) |

## Data Types

```typescript
// Cached Mastodon data (in mastodon-cache.json)
export interface MastodonCacheEntry {
  login: string;            // GitHub username (key for matching)
  mastodon: {
    handle: string;         // e.g. "@phranck@mastodon.social"
    url: string;            // e.g. "https://mastodon.social/@phranck"
    source: "bio" | "blog" | "username-match" | "manual";
    verified: boolean;      // true if manually confirmed
  };
  updatedAt: string;        // ISO timestamp
}

// Runtime merged type
export interface Stargazer {
  login: string;
  avatarUrl: string;
  profileUrl: string;
  mastodon?: {
    handle: string;
    url: string;
  };
}
```

## Known Mastodon Instances

```typescript
const KNOWN_INSTANCES = [
  // Large general instances
  "mastodon.social",
  "mastodon.online",
  "mstdn.social",
  // Tech/Developer
  "fosstodon.org",
  "hachyderm.io",
  "infosec.exchange",
  "techhub.social",
  // Swift/Apple Community
  "iosdev.space",
  "indieweb.social",
  // German
  "chaos.social",
  // Language/Community specific
  "ruby.social",
  "phpc.social",
];
```

## Regex Patterns

```typescript
// Matches @username@instance.tld or username@instance.tld
const MASTODON_HANDLE_REGEX = /@?([a-zA-Z0-9_]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g;

// Matches Mastodon profile URLs
const MASTODON_URL_REGEX = /https?:\/\/([a-zA-Z0-9.-]+)\/(@)?([a-zA-Z0-9_]+)/;
```

## New Files

| File | Purpose |
|---|---|
| `docs/scripts/update-mastodon-cache.ts` | Main script for Mastodon search |
| `docs/public/mastodon-cache.json` | Cached Mastodon data (served statically) |
| `docs/mastodon-overrides.json` | Manual corrections/mappings (source of truth) |
| `.github/workflows/update-mastodon-cache.yml` | Scheduled workflow (cron) |

## Modified Files

| File | Change |
|---|---|
| `docs/app/hooks/useGitHubStats.ts` | Fetch + merge mastodon-cache.json |
| `docs/app/components/StargazersPanel.tsx` | Popover with Mastodon info + link |
| `docs/app/components/Icon.tsx` | Add Mastodon icon |

## GitHub Action Workflow

```yaml
name: Update Mastodon Cache

on:
  schedule:
    - cron: '0 */2 * * *'  # Every 2 hours (incremental: new stargazers only)
    - cron: '0 4 * * 0'    # Weekly full refresh (Sundays 4 AM UTC)
  workflow_dispatch:      # Manual trigger

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          
      - name: Install dependencies
        run: npm ci
        working-directory: docs
        
      - name: Update Mastodon cache
        run: npx tsx scripts/update-mastodon-cache.ts
        working-directory: docs
        env:
          GITHUB_TOKEN: ${{ secrets.DASHBOARD_GITHUB_TOKEN }}  # PAT for 5,000 req/h
          
      - name: Commit if changed
        run: |
          git diff --quiet docs/public/mastodon-cache.json && exit 0
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/public/mastodon-cache.json
          git commit -m "chore: update mastodon cache [skip ci]"
          git push
```

## UI Design

### Popover (extended)

```
┌─────────────────────────────┐
│  phranck                    │
│  @phranck@mastodon.social 🐘│
└─────────────────────────────┘
```

- GitHub username always visible
- Mastodon handle below (if found)
- Mastodon icon (🐘 or SVG) as link
- Click on handle opens Mastodon profile

## Implementation Plan

### Phase 1: Data Structure & Runtime Merge

- [ ] Define `MastodonCacheEntry` type
- [ ] Create empty `mastodon-overrides.json`
- [ ] Create empty `public/mastodon-cache.json`
- [ ] Update `useGitHubStats.ts` to fetch and merge Mastodon cache

### Phase 2: Mastodon Search Script

- [ ] Create `scripts/update-mastodon-cache.ts`
- [ ] Fetch GitHub user details (bio, blog)
- [ ] Parse Mastodon handle from bio (regex)
- [ ] Parse Mastodon URL from blog
- [ ] Search username on known instances
- [ ] Merge with manual overrides
- [ ] Write `mastodon-cache.json`

### Phase 3: Scheduled Workflow

- [ ] Create `update-mastodon-cache.yml` workflow
- [ ] Use `DASHBOARD_GITHUB_TOKEN` secret (same PAT as dashboard, 5,000 req/h)
- [ ] Test manual trigger
- [ ] Verify cron schedule works

### Phase 4: UI Updates

- [ ] Add Mastodon icon to `Icon.tsx`
- [ ] Extend `StargazersPanel.tsx` popover content
- [ ] Link to Mastodon profile
- [ ] Styling consistent with retro theme

### Phase 5: Testing & Initial Data

- [ ] Run script locally
- [ ] Add manual overrides for known stargazers
- [ ] Trigger workflow manually
- [ ] Test popover in all themes

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Rate Limiting (Mastodon) | Max 1 req/s per instance, parallel instances OK |
| False positive matches | `verified: false` flag, manual overrides |
| Instance offline | Try/catch, skip and retry on next run |
| Many stargazers | Incremental updates (only check new ones) |

## Open Questions

1. **How often to run cron?** Every 2 hours incremental + weekly full refresh.
2. **Avatar comparison?** Technically possible (hash comparison), but complex. Skip for now.
3. **Verification UI?** Button for "That's not me"? Later, if needed.
4. **Unstarred users?** Weekly full refresh removes them from cache automatically.
