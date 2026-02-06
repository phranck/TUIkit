## Preface

Social lookup script is optimized to eliminate false positives: instance validation via NodeInfo (confirms domains run ActivityPub software), expanded blocklist for link-in-bio services, leading-`@` requirement for Mastodon handles (rejects corporate emails), and preservation of `verified: true` for authoritative sources (GitHub profile, Keybase, manual overrides). Full refresh overwrites stale entries. 21 known Mastodon instances searched. Cleaner cache, no manual corrections needed.

## Completed

**2026-02-05** — All 8 implementation steps done. Commits: `fb4eef0`, `032bcc7`.

## Checklist

- [x] Implement instance validation via NodeInfo
- [x] Replace email blocklist with positive identification (leading @)
- [x] Expand blog URL blocklist with link-in-bio services
- [x] Make bio/blog Mastodon parsers async with validation
- [x] Preserve verified: true for authoritative sources (github, keybase, manual)
- [x] Fix full refresh to overwrite stale entries
- [x] Expand Mastodon instance list (12 → 21 instances)
- [x] Test script locally
- [x] Regenerate cache with full refresh
- [x] Verify no false positives
- [x] Commit updated social-cache.json

# Social Lookup Script — Matching Algorithm Optimization

## Goal

Reduce false positives and increase true matches in `docs/scripts/update-social-cache.ts`. The script discovers Mastodon, Twitter, and Bluesky accounts for GitHub stargazers — but currently produces several false positives and misses verifiable matches.

## Findings

### False Positives in Current Cache

| User | Platform | Match | Root Cause |
|---|---|---|---|
| `sqwu` | Mastodon | `@menghang@bento.me` | Blog URL `bento.me/@menghang` matched by `MASTODON_URL_REGEX` — bento.me is a link-in-bio service, not a Mastodon instance |
| `gahms` | Mastodon | `@henriksen@knowit.dk` | Bio contains `henriksen@knowit.dk` (corporate email) — matched by `MASTODON_HANDLE_REGEX` because `knowit.dk` is not on the email provider blocklist |
| `jtvargas` | Mastodon | `@apps@go.jrtv.space` | Blog URL `go.jrtv.space/@apps` matched — personal redirect service, not Mastodon |

### Bug: `verified` Flag Always `false`

All 33 social entries in the cache show `verified: false`, including:

- **7 Twitter entries with `source: "github"`** — `getTwitterFromGitHubProfile()` sets `verified: true` (line 532), but the cache shows `false`. Likely cause: entries were written by an earlier script version that did not set the flag, and incremental runs skip already-cached users.
- **All `username-match` entries** — Avatar comparison never matched (different images due to resizing/compression), cross-verification found no backlink, but the entry was not deleted. Suggests the deletion logic may not be working as intended, or these entries predate it.

### Systematic Weaknesses

#### 1. Blog URL Regex Too Greedy (High Impact)

`MASTODON_URL_REGEX` matches any URL with the pattern `domain/@username` or `domain/users/username`. This matches dozens of non-Mastodon sites:

- Link-in-bio services: bento.me, linktr.ee, carrd.co, bio.link, etc.
- Personal websites with `/@` routes
- Any service that uses `/users/` URL patterns

The blocklist has only 7 entries. **No instance validation** is performed.

#### 2. Bio Email Detection Incomplete (High Impact)

`MASTODON_HANDLE_REGEX` matches `user@domain.tld`. The email filter only blocks 12 common providers. Any corporate email (`user@company.dk`, `user@firm.io`) gets misidentified as a Mastodon handle.

The fundamental problem: `user@domain` is ambiguous — it could be a Mastodon handle OR an email. The current approach (blocklist) cannot scale. Need a positive identification strategy instead.

#### 3. Avatar Hash Too Fragile (Medium Impact)

The djb2 hash with 50-byte sampling + file size comparison requires byte-identical images. Platform-specific resizing, recompression, or CDN transformations break the match even for the same source image. This is why no `username-match` entry has `verified: true`.

#### 4. Limited Mastodon Instance Coverage (Medium Impact)

Only 12 instances searched. Popular instances like `mastodon.world`, `mas.to`, `social.linux.pizza`, `toot.community`, `mastodon.art` etc. are missing.

#### 5. No Twitter Cross-Verification (Low Impact)

Twitter entries from `source: "github"` are already high-confidence (user-set in GitHub profile). No additional verification needed.

#### 6. Bluesky Custom Domains Missed (Low Impact)

Username search only tries `{user}.bsky.social`. Custom domains (e.g. `user.dev`) are only found via bio/blog parsing. Growing portion of Bluesky users use custom domains.

## Optimization Strategy

### Phase 1: Eliminate False Positives (High Priority)

#### 1a. Instance Validation via NodeInfo

For **every** Mastodon match from bio or blog parsing, validate the domain before accepting:

```
GET https://{domain}/.well-known/nodeinfo
```

If the response contains a valid NodeInfo `links` array, the domain runs ActivityPub software (Mastodon, Pleroma, Misskey, etc.). Cache results in a `Map<string, boolean>` for the script lifetime.

**Short-circuit**: Known instances from `KNOWN_MASTODON_INSTANCES` skip validation. Known non-Mastodon domains from a blocklist skip validation (return false).

**Cost**: One extra HTTP request per unknown domain per script run. Cached, so repeated encounters are free.

#### 1b. Replace Email Blocklist with Positive Identification

Instead of "is this NOT an email?", flip the logic to "is this a Mastodon handle?":

1. Require the `@user@instance` pattern to have a **leading `@`** (Mastodon convention). Bare `user@domain` without leading `@` is almost always an email.
2. If no leading `@`: fall through to instance validation (1a). If the domain is a validated ActivityPub instance, accept it anyway.

This eliminates corporate emails without needing an infinite blocklist.

#### 1c. Expand Blog URL Blocklist

Add comprehensive list of link-in-bio services and social platforms that use `/@username` URL patterns:

```typescript
const NON_MASTODON_DOMAINS = [
  // Social platforms
  "twitter.com", "x.com", "github.com", "linkedin.com",
  "facebook.com", "instagram.com", "youtube.com", "reddit.com",
  "threads.net", "bsky.app",
  // Link-in-bio services
  "bento.me", "linktr.ee", "carrd.co", "bio.link", "beacons.ai",
  "campsite.bio", "solo.to", "tap.bio", "withkoji.com", "milkshake.app",
  "later.com", "snipfeed.co", "hoo.be", "allmylinks.com", "lnk.bio",
  // Publishing platforms
  "medium.com", "dev.to", "hashnode.dev", "substack.com",
  // Design platforms
  "codepen.io", "dribbble.com", "behance.net",
];
```

Blog URL matches against domains NOT in `KNOWN_MASTODON_INSTANCES` also go through NodeInfo validation (1a).

#### 1d. Make Bio/Blog Mastodon Parsers Async

`parseMastodonFromBio()` and `parseMastodonFromBlog()` become async and validate the domain (1a) before returning a match. Turns "match and hope" into "match and verify".

### Phase 2: Fix Bugs (High Priority)

#### 2a. Preserve `verified: true` for Authoritative Sources

Ensure that entries from high-trust sources keep their verified flag:

- `source: "github"` (Twitter from GitHub profile) → always `verified: true`
- `source: "keybase"` (cryptographically verified) → always `verified: true`
- `source: "manual"` (manual override) → always `verified: true`

The `crossPlatformVerify()` function must skip entries that are already `verified: true` from authoritative sources. Currently it checks `!accounts.mastodon.verified` which should work — but add the same guard for Twitter defensively.

#### 2b. Full Refresh Overwrites Stale Entries

The `--full` flag re-processes all users, but `findSocialAccounts()` does not clear previous cache entries. Old false positives survive across full refreshes if the user still has *some* social account found. Fix: On full refresh, delete the old entry before re-processing.

### Phase 3: Improve True Matches (Medium Priority)

#### 3a. Expand Mastodon Instance List

From 12 to 21 instances:

```
+mastodon.world, +mas.to, +social.linux.pizza, +toot.community,
+det.social, +mastodon.art, +social.coop, +aus.social, +nrw.social
```

#### 3b. Avatar Comparison (Optional, Lower Priority)

Current hash is too strict. Options:

1. **Normalize image size**: Request both avatars at same size (GitHub supports `?s=200`). Compare at canonical resolution.
2. **Accept close file sizes**: If sizes differ by <5% and hash matches, accept.
3. **Leave as-is**: Backlink verification is the better signal. Avatar matching is nice-to-have.

Recommendation: Option 3 — rely on backlink verification. Avatar comparison is unreliable across CDNs.

### Phase 4: Cache Cleanup (Medium Priority)

After script changes are applied, run `--full` refresh to regenerate the cache. Known false positives (`sqwu`, `gahms`, `jtvargas`) should automatically be excluded by the new validation. Verify regenerated cache manually before committing.

## Implementation Order

1. Add `NON_MASTODON_DOMAINS` blocklist and `isMastodonInstance()` validation function
2. Make `parseMastodonFromBio()` and `parseMastodonFromBlog()` async with instance validation
3. Fix bio regex: require leading `@` or pass through instance validation
4. Guard `verified: true` for authoritative sources in `crossPlatformVerify()`
5. Expand `KNOWN_MASTODON_INSTANCES` list
6. On `--full` refresh: clear stale entries before re-processing
7. Run script locally with `--full`, inspect output
8. Verify cache, commit

## Files Modified

| File | Change |
|---|---|
| `docs/scripts/update-social-cache.ts` | All detection/validation logic changes |
| `docs/public/social-cache.json` | Regenerated by script (full refresh) |

## Risks

| Risk | Mitigation |
|---|---|
| NodeInfo requests add latency | Cached per domain, only hit once per unknown domain per run |
| NodeInfo endpoint down on some instances | Timeout (5s), fall back to rejection — better to miss than false-match |
| Stricter bio regex misses real Mastodon handles | Instance validation as fallback for bare `user@domain` patterns |
| Full refresh hits GitHub API rate limit | Script already uses `GITHUB_TOKEN` (5000 req/h), processes sequentially with 200ms delay |
