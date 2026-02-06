# Stargazer Social Account Lookup: Multi-Platform Discovery

## Preface

Multi-platform social lookup now discovers Mastodon, Twitter, and Bluesky accounts for stargazers: searches GitHub bios/blogs/profile fields, validates domains via NodeInfo, searches usernames on known instances, and caches results. Scheduled GitHub Action runs every 2h (incremental for new stargazers) and weekly (full refresh for updated bios). Dashboard popover shows social icons + links for all three platforms. Better validation eliminates false positives (corporate emails, link-in-bio services).

## Completed

**0: Social lookup script, GitHub Action workflow, and UI integration all functional. Supersedes [2026-02-04-stargazer-mastodon-lookup.md](2026-02-04-stargazer-mastodon-lookup.md).

## Checklist

- [x] Define SocialCacheEntry type with all three platforms
- [x] Create empty social-overrides.json
- [x] Create empty public/social-cache.json
- [x] Update useGitHubStats.ts to fetch and merge social cache
- [x] Create scripts/update-social-cache.ts
- [x] Fetch GitHub user details (bio, blog, twitter_username)
- [x] Parse Twitter from GitHub profile + bio/blog
- [x] Parse Mastodon handle from bio/blog with validation
- [x] Parse Bluesky handle from bio/blog
- [x] Search username on known Mastodon instances
- [x] Search username via Bluesky API
- [x] Merge with manual overrides
- [x] Create update-social-cache.yml workflow
- [x] Configure incremental (2h) + full (weekly) schedule
- [x] Add Mastodon, Twitter, Bluesky icons to Icon.tsx
- [x] Update StargazersPanel.tsx popover with icon row
- [x] Link icons to social profiles
- [x] Fix TypeScript errors in script
- [x] Test popover in browser
- [x] Add manual overrides for known stargazers

---

## Goal

Find social media accounts (Mastodon, Twitter/X, Bluesky) for all repository stargazers and display/link them in the Dashboard popover with platform-specific icons.

## Tech Stack

- GitHub Actions (Scheduled Workflow)
- Node.js/TypeScript script for social account search
- JSON file as social data cache (committed to repo)
- Next.js client-side fetch for live stargazer list

## Data Strategy: Hybrid Approach

**Key insight:** Stargazers are already fetched live via GitHub API on every page load. Only the social account lookup data needs caching (because it's expensive and slow).

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
│  SCHEDULED (GitHub Action, every 2h)                        │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐   │
│  │ Fetch       │───▶│ Search       │───▶│ Generate      │   │
│  │ Stargazers  │    │ Social Accts │    │ JSON          │   │
│  └─────────────┘    └──────────────┘    └───────────────┘   │
│                                                ▼            │
│                                    ┌────────────────────┐   │
│                                    │ social-cache.json  │   │
│                                    │ (committed to repo)│   │
│                                    └────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                    =
┌─────────────────────────────────────────────────────────────┐
│  MERGED at runtime                                          │
│  ┌─────────────────┐    ┌────────────────────┐              │
│  │ Live stargazers │ +  │ Cached Social      │              │
│  │ from API        │    │ from JSON          │              │
│  └────────┬────────┘    └─────────┬──────────┘              │
│           │                       │                         │
│           └───────────┬───────────┘                         │
│                       ▼                                     │
│           ┌───────────────────────┐                         │
│           │ Stargazer with social │                         │
│           │ icons (if any found)  │                         │
│           └───────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

### Update Strategy: Incremental + Weekly Full Refresh

```
┌─────────────────────────────────────────────────────────────┐
│  FIRST RUN                                                  │
│  └── All stargazers → full social search                    │
├─────────────────────────────────────────────────────────────┤
│  EVERY 2 HOURS (incremental)                                │
│  └── Compare current stargazers with cache                  │
│      └── Only search for NEW stargazers                     │
│      └── Skip already-cached entries                        │
├─────────────────────────────────────────────────────────────┤
│  WEEKLY (Sundays 4 AM UTC)                                  │
│  └── Full refresh of ALL stargazers                         │
│      └── Catches updated bios, changed handles              │
│      └── Removes entries for users who unstarred            │
└─────────────────────────────────────────────────────────────┘
```

## Supported Platforms

| Platform | Icon | Detection Methods |
|----------|------|-------------------|
| Twitter/X | 𝕏 | GitHub `twitter_username` field, bio parsing, blog URL |
| Mastodon | 🐘 | Bio parsing (`@user@instance`), blog URL, username search |
| Bluesky | 🦋 | Bio parsing (`.bsky.social`), blog URL, API search |

## API Details

### GitHub API

- **Rate Limits:**
  - Unauthenticated: 60 req/hour
  - With `GITHUB_TOKEN`: 1,000 req/hour
  - With Personal Access Token: 5,000 req/hour ✅
- **Available data:**

| Endpoint | Fields |
|---|---|
| `GET /users/{username}` | `bio`, `blog`, `twitter_username`, `avatar_url`, `name` |

### Platform APIs

| Platform | Endpoint | Notes |
|---|---|---|
| Mastodon | `https://{instance}/api/v1/accounts/lookup?acct={username}` | Need to know instance |
| Bluesky | `https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor={handle}` | Public, no auth needed |
| Twitter | N/A (no public API) | Only parse from GitHub profile |

## Search Strategies (Prioritized)

| Priority | Source | Method | Reliability |
|---|---|---|---|
| 1 | Manual Overrides | `social-overrides.json` | ✅ 100% |
| 2 | Gravatar Profile | JSON API with verified accounts | ✅ High |
| 3 | About.me Profile | Scrape social links | ✅ High |
| 4 | GitHub Profile | `twitter_username` field | ✅ 100% (for Twitter) |
| 5 | GitHub Bio | Regex for handles | ✅ High |
| 6 | GitHub Blog | URL parsing | ✅ High |
| 7 | Username Match + Avatar | Same username + same avatar image | ✅ High |

## Regex Patterns

```typescript
// Mastodon: @username@instance.tld or username@instance.tld
const MASTODON_HANDLE_REGEX = /@?([a-zA-Z0-9_]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g;

// Bluesky: @handle.bsky.social or handle.bsky.social
const BLUESKY_HANDLE_REGEX = /@?([a-zA-Z0-9.-]+\.bsky\.social)/gi;

// Twitter: @username (simple, combined with context)
const TWITTER_HANDLE_REGEX = /@([a-zA-Z0-9_]{1,15})/g;
```

## Data Types

```typescript
interface SocialInfo {
  handle: string;
  url: string;
  source: "github" | "bio" | "blog" | "username-match" | "manual";
  verified: boolean;
}

interface SocialCacheEntry {
  login: string;
  mastodon?: SocialInfo;
  twitter?: SocialInfo;
  bluesky?: SocialInfo;
  updatedAt: string;
}

interface SocialCache {
  generatedAt: string | null;
  entries: Record<string, SocialCacheEntry>;
}

// Runtime merged type (simpler, no source/verified)
interface Stargazer {
  login: string;
  avatarUrl: string;
  profileUrl: string;
  mastodon?: { handle: string; url: string };
  twitter?: { handle: string; url: string };
  bluesky?: { handle: string; url: string };
}
```

## Files

### New Files

| File | Purpose |
|---|---|
| `docs/scripts/update-social-cache.ts` | Main script for social account search |
| `docs/public/social-cache.json` | Cached social data (served statically) |
| `docs/social-overrides.json` | Manual corrections/mappings |
| `.github/workflows/update-social-cache.yml` | Scheduled workflow |

### Modified Files

| File | Change |
|---|---|
| `docs/app/hooks/useGitHubStats.ts` | Fetch + merge social-cache.json |
| `docs/app/components/StargazersPanel.tsx` | Popover with social icons + links |
| `docs/app/components/Icon.tsx` | Add Mastodon, Twitter, Bluesky icons |

## UI Design

### Popover with Social Icons

```
┌─────────────────────────────────┐
│         phranck                 │
│  🐘 Mastodon                    │
│  🦋 Bluesky                     │
│  𝕏  Twitter                     │
└─────────────────────────────────┘
```

- GitHub username always visible (centered, top)
- Social accounts listed below with icon + platform name
- Order: Mastodon, Bluesky, Twitter
- Icons are **monochrome only** (colored by theme)
- Each line is a clickable link to the profile
- Only show platforms where account was found

## GitHub Action Workflow

```yaml
name: Update Social Cache

on:
  schedule:
    - cron: '0 */2 * * *'  # Every 2 hours (incremental)
    - cron: '0 4 * * 0'    # Weekly full refresh (Sundays 4 AM UTC)
  workflow_dispatch:
    inputs:
      full_refresh:
        description: 'Run full refresh instead of incremental'
        type: boolean
        default: false

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm ci
        working-directory: docs
      - name: Update social cache
        run: npx tsx scripts/update-social-cache.ts ${{ steps.mode.outputs.args }}
        working-directory: docs
        env:
          GITHUB_TOKEN: ${{ secrets.DASHBOARD_GITHUB_TOKEN }}
      - name: Commit if changed
        run: |
          git diff --quiet docs/public/social-cache.json && exit 0
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/public/social-cache.json
          git commit -m "chore: update social cache [skip ci]"
          git push
```

## Implementation Plan

### Phase 1: Data Structure & Runtime Merge

- [x] Define `SocialCacheEntry` type (with all three platforms)
- [x] Create empty `social-overrides.json`
- [x] Create empty `public/social-cache.json`
- [x] Update `useGitHubStats.ts` to fetch and merge social cache

### Phase 2: Social Search Script

- [x] Create `scripts/update-social-cache.ts`
- [x] Fetch GitHub user details (bio, blog, twitter_username)
- [x] Parse Twitter from GitHub profile + bio/blog
- [x] Parse Mastodon handle from bio/blog
- [x] Parse Bluesky handle from bio/blog
- [x] Search username on known Mastodon instances
- [x] Search username via Bluesky API
- [x] Merge with manual overrides
- [x] Write `social-cache.json`

### Phase 3: Scheduled Workflow

- [x] Create `update-social-cache.yml` workflow
- [x] Configure incremental (2h) + full (weekly) schedule
- [x] Use `DASHBOARD_GITHUB_TOKEN` secret
- [x] Test manual trigger

### Phase 4: UI Updates

- [x] Add Mastodon, Twitter, Bluesky icons to `Icon.tsx`
- [x] Update `StargazersPanel.tsx` popover with icon row
- [x] Link icons to social profiles
- [x] Add tooltips with full handles

### Phase 5: Testing & Finalization

- [x] Fix TypeScript errors in script
- [x] Run `npm run build` successfully
- [x] Run script locally to verify
- [x] Test popover in browser
- [x] Add manual overrides for known stargazers

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Rate Limiting (Mastodon) | Max 1 req/s per instance, parallel instances OK |
| Rate Limiting (Bluesky) | Public API, generous limits |
| False positive matches | `verified: false` flag, manual overrides |
| Instance offline | Try/catch, skip and retry on next run |
| Many stargazers | Incremental updates (only check new ones) |

## Known Mastodon Instances

```typescript
const KNOWN_INSTANCES = [
  "mastodon.social",
  "mastodon.online",
  "mstdn.social",
  "fosstodon.org",
  "hachyderm.io",
  "infosec.exchange",
  "techhub.social",
  "iosdev.space",
  "indieweb.social",
  "chaos.social",
  "ruby.social",
  "phpc.social",
];
```
