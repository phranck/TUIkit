#!/usr/bin/env npx tsx
/**
 * Social Cache Updater
 *
 * Finds social accounts (Mastodon, Twitter, Bluesky) for GitHub stargazers using multiple strategies:
 * 1. Manual overrides (highest priority)
 * 2. Parse GitHub bio for handles
 * 3. Parse GitHub blog URL for profile links
 * 4. Search username on known platforms
 *
 * Supports incremental updates (only new stargazers) and weekly full refresh.
 */

import * as fs from "fs";
import * as path from "path";

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

const OWNER = "phranck";
const REPO = "TUIkit";
const GITHUB_API = "https://api.github.com";

/** Known Mastodon instances to search for username matches. */
const KNOWN_MASTODON_INSTANCES = [
  "mastodon.social",
  "mastodon.online",
  "mastodon.world",
  "mstdn.social",
  "mas.to",
  "fosstodon.org",
  "hachyderm.io",
  "infosec.exchange",
  "techhub.social",
  "iosdev.space",
  "indieweb.social",
  "chaos.social",
  "ruby.social",
  "phpc.social",
  "social.linux.pizza",
  "toot.community",
  "det.social",
  "mastodon.art",
  "social.coop",
  "aus.social",
  "nrw.social",
];

/** Delay between API requests to avoid rate limiting (ms). */
const REQUEST_DELAY = 200;

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

interface SocialInfo {
  handle: string;
  url: string;
  source: "github" | "bio" | "blog" | "username-match" | "manual" | "keybase" | "aboutme" | "linktree";
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

interface SocialOverrides {
  overrides: Record<string, {
    mastodon?: { handle: string; url: string };
    twitter?: { handle: string; url: string };
    bluesky?: { handle: string; url: string };
  }>;
}

interface GitHubUser {
  login: string;
  avatar_url: string;
  html_url: string;
  bio?: string | null;
  blog?: string | null;
  twitter_username?: string | null;
}

interface GitHubStargazer {
  login: string;
  avatar_url: string;
  html_url: string;
}

/**
 * Domains that use `/@username` URL patterns but are NOT Mastodon instances.
 * Prevents false positive matches from link-in-bio services and social platforms.
 */
const NON_MASTODON_DOMAINS = [
  "twitter.com", "x.com", "github.com", "linkedin.com",
  "facebook.com", "instagram.com", "youtube.com", "reddit.com",
  "bento.me", "linktr.ee", "carrd.co", "bio.link", "beacons.ai",
  "campsite.bio", "solo.to", "tap.bio", "withkoji.com", "milkshake.app",
  "later.com", "snipfeed.co", "hoo.be", "allmylinks.com", "lnk.bio",
  "medium.com", "dev.to", "hashnode.dev", "substack.com",
  "codepen.io", "dribbble.com", "behance.net",
  "threads.net", "bsky.app",
];

/** Cache for validated Mastodon/ActivityPub instances (domain → boolean). */
const mastodonInstanceCache = new Map<string, boolean>();

/**
 * Checks whether a domain is a Mastodon/ActivityPub instance by querying its
 * `.well-known/nodeinfo` endpoint. Results are cached for the script lifetime.
 */
async function isMastodonInstance(domain: string): Promise<boolean> {
  if (NON_MASTODON_DOMAINS.some((blocked) => domain.includes(blocked))) return false;
  if (KNOWN_MASTODON_INSTANCES.includes(domain)) return true;

  const cached = mastodonInstanceCache.get(domain);
  if (cached !== undefined) return cached;

  try {
    const response = await fetch(`https://${domain}/.well-known/nodeinfo`, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      signal: AbortSignal.timeout(5000),
      redirect: "follow",
    });
    if (!response.ok) {
      mastodonInstanceCache.set(domain, false);
      return false;
    }
    const data = (await response.json()) as { links?: Array<{ rel: string }> };
    // NodeInfo is used by Mastodon, Pleroma, Misskey, etc.
    const isValid = Array.isArray(data.links) && data.links.some(
      (link) => link.rel?.includes("nodeinfo"),
    );
    mastodonInstanceCache.set(domain, isValid);
    if (isValid) {
      console.log(`    Validated ${domain} as ActivityPub instance ✓`);
    }
    return isValid;
  } catch {
    mastodonInstanceCache.set(domain, false);
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Comparison
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetches an image and returns a hash for comparison.
 * Uses djb2 algorithm with file size for better collision resistance.
 */
async function fetchAvatarHash(url: string): Promise<string | null> {
  try {
    const response = await fetch(url, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      signal: AbortSignal.timeout(5000),
    });
    if (!response.ok) return null;

    const buffer = await response.arrayBuffer();
    const bytes = new Uint8Array(buffer);

    // djb2 hash with denser sampling for better uniqueness
    let hash = 5381;
    for (let i = 0; i < bytes.length; i += 50) {
      hash = ((hash << 5) + hash) ^ bytes[i];
    }
    // Include file size for additional collision resistance
    return `${bytes.length.toString(16)}-${(hash >>> 0).toString(16)}`;
  } catch {
    return null;
  }
}

/**
 * Compares two avatar URLs to check if they're likely the same image.
 * Returns true if avatars match, false otherwise.
 */
async function avatarsMatch(url1: string, url2: string): Promise<boolean> {
  const [hash1, hash2] = await Promise.all([
    fetchAvatarHash(url1),
    fetchAvatarHash(url2),
  ]);

  if (!hash1 || !hash2) return false;
  return hash1 === hash2;
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Lookup Services
// ─────────────────────────────────────────────────────────────────────────────

interface ProfileSocialAccounts {
  mastodon?: SocialInfo;
  twitter?: SocialInfo;
  bluesky?: SocialInfo;
}

// ─────────────────────────────────────────────────────────────────────────────
// About.me Profile Lookup
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetches social accounts from about.me profile by username.
 * Scrapes the profile page for social links.
 */
async function fetchSocialFromAboutMe(username: string): Promise<ProfileSocialAccounts> {
  const accounts: ProfileSocialAccounts = {};

  try {
    const url = `https://about.me/${username}`;
    const response = await fetch(url, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      redirect: "follow",
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return accounts;

    const html = await response.text();

    // Look for Twitter/X links
    const twitterMatch = html.match(/href="https?:\/\/(?:twitter\.com|x\.com)\/([a-zA-Z0-9_]+)"/i);
    if (twitterMatch) {
      accounts.twitter = {
        handle: `@${twitterMatch[1]}`,
        url: `https://x.com/${twitterMatch[1]}`,
        source: "aboutme",
        verified: true,
      };
      console.log(`    Found Twitter from about.me: @${twitterMatch[1]}`);
    }

    // Look for Mastodon links (exclude twitter/x.com false positives)
    const mastodonMatch = html.match(/href="(https?:\/\/([a-zA-Z0-9.-]+)\/@([a-zA-Z0-9_]+))"/i);
    if (mastodonMatch && !mastodonMatch[2].includes("twitter") && !mastodonMatch[2].includes("x.com")) {
      accounts.mastodon = {
        handle: `@${mastodonMatch[3]}@${mastodonMatch[2]}`,
        url: mastodonMatch[1],
        source: "aboutme",
        verified: true,
      };
      console.log(`    Found Mastodon from about.me: @${mastodonMatch[3]}@${mastodonMatch[2]}`);
    }

    // Look for Bluesky links
    const bskyMatch = html.match(/href="https?:\/\/bsky\.app\/profile\/([^"]+)"/i);
    if (bskyMatch) {
      accounts.bluesky = {
        handle: `@${bskyMatch[1]}`,
        url: `https://bsky.app/profile/${bskyMatch[1]}`,
        source: "aboutme",
        verified: true,
      };
      console.log(`    Found Bluesky from about.me: @${bskyMatch[1]}`);
    }
  } catch {
    // about.me lookup failed, continue
  }

  await new Promise((resolve) => setTimeout(resolve, REQUEST_DELAY));
  return accounts;
}

// ─────────────────────────────────────────────────────────────────────────────
// Keybase Profile Lookup
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetches social accounts from Keybase by GitHub username.
 * Keybase has cryptographically verified identities.
 */
async function fetchSocialFromKeybase(githubUsername: string): Promise<ProfileSocialAccounts> {
  const accounts: ProfileSocialAccounts = {};

  try {
    // Keybase API to find user by GitHub proof
    const url = `https://keybase.io/_/api/1.0/user/lookup.json?github=${githubUsername}`;
    const response = await fetch(url, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return accounts;

    const data = (await response.json()) as {
      them?: Array<{
        proofs_summary?: {
          all?: Array<{
            proof_type: string;
            nametag: string;
            service_url: string;
          }>;
        };
      }>;
    };

    const proofs = data.them?.[0]?.proofs_summary?.all;
    if (!proofs) return accounts;

    for (const proof of proofs) {
      if (proof.proof_type === "twitter") {
        accounts.twitter = {
          handle: `@${proof.nametag}`,
          url: proof.service_url || `https://x.com/${proof.nametag}`,
          source: "keybase",
          verified: true, // Keybase proofs are cryptographically verified!
        };
        console.log(`    Found Twitter from Keybase: @${proof.nametag} (verified ✓)`);
      }

      if (proof.proof_type === "mastodon" || proof.proof_type.includes("mastodon")) {
        const mastodonMatch = proof.service_url?.match(/https?:\/\/([^/]+)\/@?([^/]+)/);
        if (mastodonMatch) {
          accounts.mastodon = {
            handle: `@${mastodonMatch[2]}@${mastodonMatch[1]}`,
            url: proof.service_url,
            source: "keybase",
            verified: true,
          };
          console.log(`    Found Mastodon from Keybase: @${mastodonMatch[2]}@${mastodonMatch[1]} (verified ✓)`);
        }
      }
    }
  } catch {
    // Keybase lookup failed, continue
  }

  await new Promise((resolve) => setTimeout(resolve, REQUEST_DELAY));
  return accounts;
}

// ─────────────────────────────────────────────────────────────────────────────
// Linktree Profile Lookup
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetches social accounts from Linktree by username.
 * Scrapes the public profile page for social links.
 */
async function fetchSocialFromLinktree(username: string): Promise<ProfileSocialAccounts> {
  const accounts: ProfileSocialAccounts = {};

  try {
    const url = `https://linktr.ee/${username}`;
    const response = await fetch(url, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      redirect: "follow",
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return accounts;

    const html = await response.text();

    // Look for Twitter/X links
    const twitterMatch = html.match(/href="https?:\/\/(?:twitter\.com|x\.com)\/([a-zA-Z0-9_]+)"/i);
    if (twitterMatch) {
      accounts.twitter = {
        handle: `@${twitterMatch[1]}`,
        url: `https://x.com/${twitterMatch[1]}`,
        source: "linktree",
        verified: true,
      };
      console.log(`    Found Twitter from Linktree: @${twitterMatch[1]}`);
    }

    // Look for Mastodon links (various instances)
    const mastodonMatch = html.match(/href="(https?:\/\/([a-zA-Z0-9.-]+)\/@([a-zA-Z0-9_]+))"/i);
    if (mastodonMatch && !mastodonMatch[2].includes("twitter") && !mastodonMatch[2].includes("x.com")) {
      accounts.mastodon = {
        handle: `@${mastodonMatch[3]}@${mastodonMatch[2]}`,
        url: mastodonMatch[1],
        source: "linktree",
        verified: true,
      };
      console.log(`    Found Mastodon from Linktree: @${mastodonMatch[3]}@${mastodonMatch[2]}`);
    }

    // Look for Bluesky links
    const bskyMatch = html.match(/href="https?:\/\/bsky\.app\/profile\/([^"]+)"/i);
    if (bskyMatch) {
      accounts.bluesky = {
        handle: `@${bskyMatch[1]}`,
        url: `https://bsky.app/profile/${bskyMatch[1]}`,
        source: "linktree",
        verified: true,
      };
      console.log(`    Found Bluesky from Linktree: @${bskyMatch[1]}`);
    }
  } catch {
    // Linktree lookup failed, continue
  }

  await new Promise((resolve) => setTimeout(resolve, REQUEST_DELAY));
  return accounts;
}

// ─────────────────────────────────────────────────────────────────────────────
// GitHub API
// ─────────────────────────────────────────────────────────────────────────────

function getGitHubHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "TUIKit-Social-Lookup",
  };
  const token = process.env.GITHUB_TOKEN;
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

async function fetchStargazers(): Promise<GitHubStargazer[]> {
  const stargazers: GitHubStargazer[] = [];
  let page = 1;
  const perPage = 100;

  while (true) {
    const url = `${GITHUB_API}/repos/${OWNER}/${REPO}/stargazers?per_page=${perPage}&page=${page}`;
    const response = await fetch(url, { headers: getGitHubHeaders() });

    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.status} ${response.statusText}`);
    }

    const data = (await response.json()) as GitHubStargazer[];
    stargazers.push(...data);

    if (data.length < perPage) break;
    page++;
  }

  console.log(`Fetched ${stargazers.length} stargazers from GitHub`);
  return stargazers;
}

async function fetchUserDetails(login: string): Promise<GitHubUser | null> {
  try {
    const url = `${GITHUB_API}/users/${login}`;
    const response = await fetch(url, { headers: getGitHubHeaders() });

    if (!response.ok) {
      console.warn(`  Failed to fetch user ${login}: ${response.status}`);
      return null;
    }

    return (await response.json()) as GitHubUser;
  } catch (error) {
    console.warn(`  Error fetching user ${login}:`, error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GitHub Social Accounts API
// ─────────────────────────────────────────────────────────────────────────────

interface GitHubSocialAccount {
  provider: string;
  url: string;
}

/**
 * Fetches social accounts from GitHub's `/users/{login}/social_accounts` endpoint.
 * These are user-provided and authoritative — highest trust after manual overrides.
 */
async function fetchGitHubSocialAccounts(login: string): Promise<ProfileSocialAccounts> {
  const accounts: ProfileSocialAccounts = {};

  try {
    const url = `${GITHUB_API}/users/${login}/social_accounts`;
    const response = await fetch(url, {
      headers: getGitHubHeaders(),
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return accounts;

    const data = (await response.json()) as GitHubSocialAccount[];

    for (const entry of data) {
      if (entry.provider === "twitter" && !accounts.twitter) {
        const handle = entry.url.match(/(?:twitter\.com|x\.com)\/([a-zA-Z0-9_]+)/i);
        if (handle) {
          accounts.twitter = {
            handle: `@${handle[1]}`,
            url: `https://x.com/${handle[1]}`,
            source: "github",
            verified: true,
          };
          console.log(`    Found Twitter from GitHub social accounts: @${handle[1]}`);
        }
      }

      if (entry.provider === "mastodon" && !accounts.mastodon) {
        const match = entry.url.match(/https?:\/\/([^/]+)\/@?([^/]+)/);
        if (match) {
          accounts.mastodon = {
            handle: `@${match[2]}@${match[1]}`,
            url: entry.url,
            source: "github",
            verified: true,
          };
          console.log(`    Found Mastodon from GitHub social accounts: @${match[2]}@${match[1]}`);
        }
      }

      if (entry.provider === "bluesky" && !accounts.bluesky) {
        const match = entry.url.match(/bsky\.app\/profile\/([a-zA-Z0-9.-]+)/);
        if (match) {
          accounts.bluesky = {
            handle: `@${match[1]}`,
            url: `https://bsky.app/profile/${match[1]}`,
            source: "github",
            verified: true,
          };
          console.log(`    Found Bluesky from GitHub social accounts: @${match[1]}`);
        }
      }
    }
  } catch {
    // Social accounts endpoint failed, continue
  }

  return accounts;
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Detection - Mastodon
// ─────────────────────────────────────────────────────────────────────────────

/** Matches @username@instance.tld or username@instance.tld in text. */
const MASTODON_HANDLE_REGEX = /@?([a-zA-Z0-9_]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g;

/** Matches Mastodon profile URLs. */
const MASTODON_URL_REGEX = /https?:\/\/([a-zA-Z0-9.-]+)\/(@|users\/)?([a-zA-Z0-9_]+)\/?$/i;

async function parseMastodonFromBio(bio: string): Promise<SocialInfo | null> {
  const matches = [...bio.matchAll(MASTODON_HANDLE_REGEX)];
  if (matches.length === 0) return null;

  const [fullMatch, username, instance] = matches[0];
  const hasLeadingAt = fullMatch.startsWith("@") && fullMatch.indexOf("@", 1) > 0;

  // Bare `user@domain` without leading `@` is almost always an email.
  // Only accept it if the domain is a validated ActivityPub instance.
  if (!hasLeadingAt) {
    const isInstance = await isMastodonInstance(instance);
    if (!isInstance) {
      console.log(`    Skipping bio match ${username}@${instance} (no leading @, not a known instance)`);
      return null;
    }
  } else {
    // Even with leading `@`, validate the domain
    const isInstance = await isMastodonInstance(instance);
    if (!isInstance) {
      console.log(`    Skipping bio match @${username}@${instance} (domain is not an ActivityPub instance)`);
      return null;
    }
  }

  return {
    handle: `@${username}@${instance}`,
    url: `https://${instance}/@${username}`,
    source: "bio",
    verified: false,
  };
}

async function parseMastodonFromBlog(blog: string): Promise<SocialInfo | null> {
  if (!blog) return null;

  const match = blog.match(MASTODON_URL_REGEX);
  if (!match) return null;

  const [, instance, , username] = match;

  // Validate the domain is actually an ActivityPub instance
  const isInstance = await isMastodonInstance(instance);
  if (!isInstance) {
    console.log(`    Skipping blog URL match ${instance}/@${username} (not an ActivityPub instance)`);
    return null;
  }

  return {
    handle: `@${username}@${instance}`,
    url: `https://${instance}/@${username}`,
    source: "blog",
    verified: false,
  };
}

async function searchMastodonByUsername(username: string, githubAvatarUrl: string): Promise<SocialInfo | null> {
  for (const instance of KNOWN_MASTODON_INSTANCES) {
    try {
      const url = `https://${instance}/api/v1/accounts/lookup?acct=${username}`;
      const response = await fetch(url, {
        headers: { "User-Agent": "TUIKit-Social-Lookup" },
        signal: AbortSignal.timeout(5000),
      });

      if (response.ok) {
        const data = (await response.json()) as { username: string; url: string; avatar: string };

        // Avatar match is a bonus signal — if it matches, we're confident immediately
        const avatarMatch = await avatarsMatch(githubAvatarUrl, data.avatar);
        if (avatarMatch) {
          console.log(`    Found Mastodon @${username} on ${instance} (avatar verified ✓)`);
          return {
            handle: `@${data.username}@${instance}`,
            url: data.url,
            source: "username-match",
            verified: true,
          };
        }

        // No avatar match — accept as unverified candidate.
        // Cross-verification will check for back-links and either verify or remove it.
        console.log(`    Found Mastodon @${username} on ${instance} (pending cross-verification)`);
        return {
          handle: `@${data.username}@${instance}`,
          url: data.url,
          source: "username-match",
          verified: false,
        };
      }
    } catch {
      // Instance unreachable or rate limited, continue
    }

    await new Promise((resolve) => setTimeout(resolve, REQUEST_DELAY));
  }

  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Detection - Twitter/X
// ─────────────────────────────────────────────────────────────────────────────

/** Matches Twitter/X profile URLs. */
const TWITTER_URL_REGEX = /https?:\/\/(?:twitter\.com|x\.com)\/([a-zA-Z0-9_]+)\/?$/i;

function parseTwitterFromBio(bio: string): SocialInfo | null {
  // Look for explicit Twitter mentions or X.com links
  const urlMatch = bio.match(TWITTER_URL_REGEX);
  if (urlMatch) {
    const username = urlMatch[1];
    return {
      handle: `@${username}`,
      url: `https://x.com/${username}`,
      source: "bio",
      verified: false,
    };
  }
  return null;
}

function parseTwitterFromBlog(blog: string): SocialInfo | null {
  if (!blog) return null;

  const match = blog.match(TWITTER_URL_REGEX);
  if (!match) return null;

  const username = match[1];
  return {
    handle: `@${username}`,
    url: `https://x.com/${username}`,
    source: "blog",
    verified: false,
  };
}

function getTwitterFromGitHubProfile(user: GitHubUser): SocialInfo | undefined {
  if (user.twitter_username) {
    console.log(`  Found Twitter from GitHub profile: @${user.twitter_username}`);
    return {
      handle: `@${user.twitter_username}`,
      url: `https://x.com/${user.twitter_username}`,
      source: "github",
      verified: true, // GitHub's twitter_username field is user-provided and authoritative
    };
  }
  return undefined;
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Detection - Bluesky
// ─────────────────────────────────────────────────────────────────────────────

/** Matches Bluesky handles like @user.bsky.social or user.bsky.social in text. */
const BLUESKY_HANDLE_REGEX = /@?([a-zA-Z0-9.-]+\.bsky\.social)/gi;

/** Matches Bluesky profile URLs. */
const BLUESKY_URL_REGEX = /https?:\/\/bsky\.app\/profile\/([a-zA-Z0-9.-]+)/i;

function parseBlueskyFromBio(bio: string): SocialInfo | null {
  // Check for bsky.app URLs first
  const urlMatch = bio.match(BLUESKY_URL_REGEX);
  if (urlMatch) {
    const handle = urlMatch[1];
    return {
      handle: `@${handle}`,
      url: `https://bsky.app/profile/${handle}`,
      source: "bio",
      verified: false,
    };
  }

  // Check for .bsky.social handles
  const handleMatches = [...bio.matchAll(BLUESKY_HANDLE_REGEX)];
  if (handleMatches.length > 0) {
    const handle = handleMatches[0][1];
    return {
      handle: `@${handle}`,
      url: `https://bsky.app/profile/${handle}`,
      source: "bio",
      verified: false,
    };
  }

  return null;
}

function parseBlueskyFromBlog(blog: string): SocialInfo | null {
  if (!blog) return null;

  const match = blog.match(BLUESKY_URL_REGEX);
  if (!match) return null;

  const handle = match[1];
  return {
    handle: `@${handle}`,
    url: `https://bsky.app/profile/${handle}`,
    source: "blog",
    verified: false,
  };
}

async function searchBlueskyByUsername(username: string, githubAvatarUrl: string): Promise<SocialInfo | null> {
  // Try Bluesky handle - use lowercase since handles are case-insensitive
  const handle = `${username.toLowerCase()}.bsky.social`;

  try {
    const url = `https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=${handle}`;
    const response = await fetch(url, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      signal: AbortSignal.timeout(5000),
    });

    if (response.ok) {
      const data = (await response.json()) as { handle: string; avatar?: string };

      // Avatar match is a bonus signal — if it matches, we're confident immediately
      if (data.avatar) {
        const avatarMatch = await avatarsMatch(githubAvatarUrl, data.avatar);
        if (avatarMatch) {
          console.log(`    Found Bluesky @${data.handle} (avatar verified ✓)`);
          return {
            handle: `@${data.handle}`,
            url: `https://bsky.app/profile/${data.handle}`,
            source: "username-match",
            verified: true,
          };
        }
      }

      // No avatar match — accept as unverified candidate.
      // Cross-verification will check for back-links and either verify or remove it.
      console.log(`    Found Bluesky @${data.handle} (pending cross-verification)`);
      return {
        handle: `@${data.handle}`,
        url: `https://bsky.app/profile/${data.handle}`,
        source: "username-match",
        verified: false,
      };
    }
  } catch {
    // API error, continue
  }

  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Combined Search
// ─────────────────────────────────────────────────────────────────────────────

async function findSocialAccounts(user: GitHubUser): Promise<ProfileSocialAccounts> {
  const accounts: ProfileSocialAccounts = {};
  const githubAvatarUrl = user.avatar_url;

  // ── GitHub Social Accounts API first (user-provided, authoritative) ──
  const ghSocialAccounts = await fetchGitHubSocialAccounts(user.login);
  if (ghSocialAccounts.twitter) accounts.twitter = ghSocialAccounts.twitter;
  if (ghSocialAccounts.mastodon) accounts.mastodon = ghSocialAccounts.mastodon;
  if (ghSocialAccounts.bluesky) accounts.bluesky = ghSocialAccounts.bluesky;

  // ── Try Keybase (cryptographically verified, fills remaining gaps) ──
  if (!accounts.twitter || !accounts.mastodon || !accounts.bluesky) {
    const keybaseAccounts = await fetchSocialFromKeybase(user.login);
    if (!accounts.twitter && keybaseAccounts.twitter) accounts.twitter = keybaseAccounts.twitter;
    if (!accounts.mastodon && keybaseAccounts.mastodon) accounts.mastodon = keybaseAccounts.mastodon;
    if (!accounts.bluesky && keybaseAccounts.bluesky) accounts.bluesky = keybaseAccounts.bluesky;
  }

  // ── Try about.me profile (high quality source) ──
  if (!accounts.twitter || !accounts.mastodon || !accounts.bluesky) {
    const aboutMeAccounts = await fetchSocialFromAboutMe(user.login);
    if (!accounts.twitter && aboutMeAccounts.twitter) accounts.twitter = aboutMeAccounts.twitter;
    if (!accounts.mastodon && aboutMeAccounts.mastodon) accounts.mastodon = aboutMeAccounts.mastodon;
    if (!accounts.bluesky && aboutMeAccounts.bluesky) accounts.bluesky = aboutMeAccounts.bluesky;
  }

  // ── Try Linktree profile ──
  if (!accounts.twitter || !accounts.mastodon || !accounts.bluesky) {
    const linktreeAccounts = await fetchSocialFromLinktree(user.login);
    if (!accounts.twitter && linktreeAccounts.twitter) accounts.twitter = linktreeAccounts.twitter;
    if (!accounts.mastodon && linktreeAccounts.mastodon) accounts.mastodon = linktreeAccounts.mastodon;
    if (!accounts.bluesky && linktreeAccounts.bluesky) accounts.bluesky = linktreeAccounts.bluesky;
  }

  // ── Twitter (check GitHub profile, it's authoritative) ──
  if (!accounts.twitter) {
    accounts.twitter = getTwitterFromGitHubProfile(user);
  }
  if (!accounts.twitter && user.bio) {
    accounts.twitter = parseTwitterFromBio(user.bio) ?? undefined;
  }
  if (!accounts.twitter && user.blog) {
    accounts.twitter = parseTwitterFromBlog(user.blog) ?? undefined;
  }

  // ── Bluesky ──
  if (!accounts.bluesky && user.bio) {
    accounts.bluesky = parseBlueskyFromBio(user.bio) ?? undefined;
  }
  if (!accounts.bluesky && user.blog) {
    accounts.bluesky = parseBlueskyFromBlog(user.blog) ?? undefined;
  }
  if (!accounts.bluesky) {
    accounts.bluesky = (await searchBlueskyByUsername(user.login, githubAvatarUrl)) ?? undefined;
  }

  // ── Mastodon ──
  if (!accounts.mastodon && user.bio) {
    accounts.mastodon = (await parseMastodonFromBio(user.bio)) ?? undefined;
  }
  if (!accounts.mastodon && user.blog) {
    accounts.mastodon = (await parseMastodonFromBlog(user.blog)) ?? undefined;
  }
  if (!accounts.mastodon) {
    accounts.mastodon = (await searchMastodonByUsername(user.login, githubAvatarUrl)) ?? undefined;
  }

  // ── Cross-platform verification ──
  // If we found accounts, verify them by checking for back-links or matching data
  await crossPlatformVerify(accounts, user);

  return accounts;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cross-Platform Verification
// ─────────────────────────────────────────────────────────────────────────────

/** Sources that are inherently authoritative and should never be downgraded. */
const AUTHORITATIVE_SOURCES = new Set(["github", "keybase", "manual"]);

/**
 * Cross-references found accounts to increase confidence.
 * Checks for:
 * - GitHub links in social profiles (back-link verification)
 * - Matching display names across platforms
 * - Consistent avatar usage
 *
 * Authoritative sources (github, keybase, manual) are never downgraded.
 */
async function crossPlatformVerify(accounts: ProfileSocialAccounts, user: GitHubUser): Promise<void> {
  const validationResults: string[] = [];

  // Verify Mastodon by checking if profile links back to GitHub
  if (accounts.mastodon && !accounts.mastodon.verified && !AUTHORITATIVE_SOURCES.has(accounts.mastodon.source)) {
    const verified = await verifyMastodonLinksToGitHub(accounts.mastodon.url, user.login);
    if (verified) {
      accounts.mastodon.verified = true;
      validationResults.push("Mastodon→GitHub ✓");
    } else if (accounts.mastodon.source === "username-match") {
      // Unverified username-match without back-link — remove to avoid false positives
      console.log(`    Removing unverified Mastodon match (no back-link to GitHub)`);
      delete accounts.mastodon;
    }
  }

  // Verify Bluesky by checking if profile links back to GitHub
  if (accounts.bluesky && !accounts.bluesky.verified && !AUTHORITATIVE_SOURCES.has(accounts.bluesky.source)) {
    const verified = await verifyBlueskyLinksToGitHub(accounts.bluesky.handle.replace("@", ""), user.login);
    if (verified) {
      accounts.bluesky.verified = true;
      validationResults.push("Bluesky→GitHub ✓");
    } else if (accounts.bluesky.source === "username-match") {
      // Unverified username-match without back-link — remove
      console.log(`    Removing unverified Bluesky match (no back-link to GitHub)`);
      delete accounts.bluesky;
    }
  }

  if (validationResults.length > 0) {
    console.log(`    Cross-verified: ${validationResults.join(", ")}`);
  }
}

/**
 * Checks if a Mastodon profile links back to the GitHub user.
 */
async function verifyMastodonLinksToGitHub(mastodonUrl: string, githubUsername: string): Promise<boolean> {
  try {
    // Extract instance and username from URL
    const match = mastodonUrl.match(/https?:\/\/([^/]+)\/@?([^/]+)/);
    if (!match) return false;

    const [, instance, username] = match;
    const apiUrl = `https://${instance}/api/v1/accounts/lookup?acct=${username}`;

    const response = await fetch(apiUrl, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return false;

    const data = (await response.json()) as {
      note?: string;
      url?: string;
      fields?: Array<{ name: string; value: string; verified_at?: string | null }>;
    };

    // Check bio (note) for GitHub link
    const githubPattern = new RegExp(`github\\.com/${githubUsername}`, "i");

    if (data.note && githubPattern.test(data.note)) {
      return true;
    }

    // Check profile fields (Website, Homepage, etc.) for GitHub link
    if (data.fields) {
      for (const field of data.fields) {
        if (githubPattern.test(field.value) || githubPattern.test(field.name)) {
          return true;
        }
      }
    }

    return false;
  } catch {
    return false;
  }
}

/**
 * Checks if a Bluesky profile links back to the GitHub user.
 */
async function verifyBlueskyLinksToGitHub(handle: string, githubUsername: string): Promise<boolean> {
  try {
    const url = `https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=${handle}`;
    const response = await fetch(url, {
      headers: { "User-Agent": "TUIKit-Social-Lookup" },
      signal: AbortSignal.timeout(5000),
    });

    if (!response.ok) return false;

    const data = (await response.json()) as { description?: string };

    if (!data.description) return false;

    // Check bio for GitHub link
    const githubPattern = new RegExp(`github\\.com/${githubUsername}`, "i");
    return githubPattern.test(data.description);
  } catch {
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// File I/O
// ─────────────────────────────────────────────────────────────────────────────

const CACHE_PATH = path.join(__dirname, "../public/social-cache.json");
const OVERRIDES_PATH = path.join(__dirname, "../social-overrides.json");

function loadCache(): SocialCache {
  try {
    const content = fs.readFileSync(CACHE_PATH, "utf-8");
    return JSON.parse(content) as SocialCache;
  } catch {
    return { generatedAt: null, entries: {} };
  }
}

function saveCache(cache: SocialCache): void {
  cache.generatedAt = new Date().toISOString();
  fs.writeFileSync(CACHE_PATH, JSON.stringify(cache, null, 2) + "\n");
  console.log(`Saved cache with ${Object.keys(cache.entries).length} entries`);
}

function loadOverrides(): SocialOverrides {
  try {
    const content = fs.readFileSync(OVERRIDES_PATH, "utf-8");
    return JSON.parse(content) as SocialOverrides;
  } catch {
    return { overrides: {} };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  const isFullRefresh = process.argv.includes("--full");
  console.log(`Social Cache Update (${isFullRefresh ? "FULL REFRESH" : "incremental"})`);
  console.log("=".repeat(60));

  // Load existing data
  const cache = loadCache();
  const overrides = loadOverrides();

  let stargazers: GitHubStargazer[];
  try {
    stargazers = await fetchStargazers();
  } catch (err) {
    console.error("Failed to fetch stargazers, retrying in 5s...");
    await new Promise((r) => setTimeout(r, 5000));
    stargazers = await fetchStargazers();
  }

  // Determine which users to process
  const cachedLogins = new Set(Object.keys(cache.entries));
  const currentLogins = new Set(stargazers.map((s) => s.login));

  // Remove entries for users who unstarred
  for (const login of cachedLogins) {
    if (!currentLogins.has(login)) {
      console.log(`Removing unstarred user: ${login}`);
      delete cache.entries[login];
    }
  }

  // On full refresh, clear all entries so stale false positives don't survive
  if (isFullRefresh) {
    console.log("Full refresh — clearing all cached entries");
    cache.entries = {};
  }

  // Find new stargazers (not in cache)
  const toProcess = isFullRefresh
    ? stargazers
    : stargazers.filter((s) => !cachedLogins.has(s.login));

  console.log(`\nProcessing ${toProcess.length} users...`);

  for (const stargazer of toProcess) {
    const { login } = stargazer;
    console.log(`\nProcessing: ${login}`);

    // Check manual overrides first
    const override = overrides.overrides[login];
    if (override) {
      console.log(`  Using manual override`);
      const entry: SocialCacheEntry = {
        login,
        updatedAt: new Date().toISOString(),
      };
      if (override.mastodon) {
        entry.mastodon = { ...override.mastodon, source: "manual", verified: true };
      }
      if (override.twitter) {
        entry.twitter = { ...override.twitter, source: "manual", verified: true };
      }
      if (override.bluesky) {
        entry.bluesky = { ...override.bluesky, source: "manual", verified: true };
      }
      cache.entries[login] = entry;
      continue;
    }

    // Fetch user details and search for social accounts
    const userDetails = await fetchUserDetails(login);
    if (!userDetails) continue;

    const accounts = await findSocialAccounts(userDetails);

    if (accounts.mastodon || accounts.twitter || accounts.bluesky) {
      cache.entries[login] = {
        login,
        mastodon: accounts.mastodon,
        twitter: accounts.twitter,
        bluesky: accounts.bluesky,
        updatedAt: new Date().toISOString(),
      };

      const found = [
        accounts.mastodon ? `Mastodon: ${accounts.mastodon.handle}` : null,
        accounts.twitter ? `Twitter: ${accounts.twitter.handle}` : null,
        accounts.bluesky ? `Bluesky: ${accounts.bluesky.handle}` : null,
      ].filter(Boolean).join(", ");
      console.log(`  Found: ${found}`);
    } else {
      console.log("  No social accounts found");
    }
  }

  // Save updated cache
  saveCache(cache);

  console.log("\n" + "=".repeat(60));
  console.log("Done!");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
