"use client";

import { useCallback, useEffect, useRef, useState } from "react";

const OWNER = "phranck";
const REPO = "TUIkit";
const API = `https://api.github.com/repos/${OWNER}/${REPO}`;

/** Single commit entry from the GitHub API. */
export interface CommitEntry {
  sha: string;
  /** First line of the commit message (title). */
  title: string;
  /** Lines after the first blank line (body), or null if single-line commit. */
  body: string | null;
  author: string;
  date: string;
  url: string;
}

/** Language breakdown (bytes per language). */
export interface LanguageBreakdown {
  [language: string]: number;
}

/** A user who starred the repository. */
export interface Stargazer {
  login: string;
  avatarUrl: string;
  profileUrl: string;
  mastodon?: {
    handle: string;
    url: string;
  };
  twitter?: {
    handle: string;
    url: string;
  };
  bluesky?: {
    handle: string;
    url: string;
  };
}

/** Social account cache entry from the pre-generated JSON. */
interface SocialCacheEntry {
  login: string;
  mastodon?: {
    handle: string;
    url: string;
    source: string;
    verified: boolean;
  };
  twitter?: {
    handle: string;
    url: string;
    source: string;
    verified: boolean;
  };
  bluesky?: {
    handle: string;
    url: string;
    source: string;
    verified: boolean;
  };
  updatedAt: string;
}

/** Structure of the social-cache.json file. */
interface SocialCache {
  generatedAt: string | null;
  entries: Record<string, SocialCacheEntry>;
}

/** Weekly commit activity (52 weeks). */
export interface WeeklyActivity {
  week: number; // Unix timestamp
  total: number;
  days: number[]; // Sun–Sat
}

/** All GitHub stats fetched client-side. */
export interface GitHubStats {
  // Repo overview
  stars: number;
  forks: number;
  watchers: number;
  openIssues: number;
  size: number; // KB
  defaultBranch: string;
  license: string | null;
  createdAt: string;
  updatedAt: string;
  pushedAt: string;

  // Counts
  totalCommits: number;
  openPRs: number;
  closedPRs: number;
  mergedPRs: number;
  closedIssues: number;
  releases: number;
  contributors: number;
  branches: number;
  tags: number;

  // Details
  recentCommits: CommitEntry[];
  languages: LanguageBreakdown;
  weeklyActivity: WeeklyActivity[];
  stargazers: Stargazer[];

  // Meta
  loading: boolean;
  error: string | null;
  rateLimit: { remaining: number; limit: number } | null;
}

/** Return type of the hook — stats plus manual refresh and data-fetch functions. */
export interface UseGitHubStatsReturn extends GitHubStats {
  /** Re-fetch all data from the GitHub API (fire-and-forget, updates internal state). */
  refresh: () => void;
  /** Fetch all data and return it as a resolved promise (for external caching). */
  fetchData: () => Promise<GitHubStats>;
}

const initialStats: GitHubStats = {
  stars: 0,
  forks: 0,
  watchers: 0,
  openIssues: 0,
  size: 0,
  defaultBranch: "",
  license: null,
  createdAt: "",
  updatedAt: "",
  pushedAt: "",
  totalCommits: 0,
  openPRs: 0,
  closedPRs: 0,
  mergedPRs: 0,
  closedIssues: 0,
  releases: 0,
  contributors: 0,
  branches: 0,
  tags: 0,
  recentCommits: [],
  languages: {},
  weeklyActivity: [],
  stargazers: [],
  loading: true,
  error: null,
  rateLimit: null,
};

/**
 * Builds common request headers for all GitHub API calls.
 *
 * Includes a Bearer token from `NEXT_PUBLIC_GITHUB_TOKEN` if available,
 * raising the rate limit from 60 to 5,000 requests per hour.
 */
function ghHeaders(): Record<string, string> {
  const headers: Record<string, string> = { Accept: "application/vnd.github+json" };
  const token = process.env.NEXT_PUBLIC_GITHUB_TOKEN;
  if (token && token.length > 0) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

/** Fetch JSON from the GitHub API with rate-limit tracking. */
async function ghFetch<T>(
  path: string,
  signal: AbortSignal,
): Promise<{ data: T; remaining: number; limit: number }> {
  const response = await fetch(`${API}${path}`, {
    signal,
    headers: ghHeaders(),
  });

  if (!response.ok) {
    throw new Error(`GitHub API ${response.status}: ${response.statusText}`);
  }

  const remaining = Number(response.headers.get("x-ratelimit-remaining") ?? 0);
  const limit = Number(response.headers.get("x-ratelimit-limit") ?? 60);
  const data = (await response.json()) as T;

  return { data, remaining, limit };
}

/** Extract the last page number from a GitHub Link header for pagination count. */
function extractLastPage(response: Response): number {
  const link = response.headers.get("link");
  if (!link) return 0;
  const match = link.match(/page=(\d+)>; rel="last"/);
  return match ? Number(match[1]) : 0;
}

/** Count total items via GET request + Link header pagination. */
async function ghCount(path: string, signal: AbortSignal): Promise<number> {
  const response = await fetch(`${API}${path}?per_page=1`, {
    signal,
    method: "GET",
    headers: ghHeaders(),
  });

  if (!response.ok) return 0;

  const lastPage = extractLastPage(response);
  if (lastPage > 0) return lastPage;

  // If no Link header, count the items in the response
  const data = await response.json();
  return Array.isArray(data) ? data.length : 0;
}

/**
 * Splits a full commit message into title and optional body.
 *
 * Git convention: first line is title, blank line separator, then body.
 */
function splitCommitMessage(fullMessage: string): { title: string; body: string | null } {
  const firstNewline = fullMessage.indexOf("\n");
  if (firstNewline === -1) return { title: fullMessage, body: null };

  const title = fullMessage.slice(0, firstNewline);
  const rest = fullMessage.slice(firstNewline + 1).replace(/^\n+/, "");
  return { title, body: rest.length > 0 ? rest : null };
}

/** Raw repository data from the GitHub REST API. */
interface GitHubRepoResponse {
  stargazers_count: number;
  forks_count: number;
  subscribers_count: number;
  open_issues_count: number;
  size: number;
  default_branch: string;
  license: { spdx_id: string } | null;
  created_at: string;
  updated_at: string;
  pushed_at: string;
}

/** Raw stargazer entry from the GitHub REST API. */
interface GitHubStargazerResponse {
  login: string;
  avatar_url: string;
  html_url: string;
}

/** Options for configuring the `useGitHubStats` hook. */
export interface UseGitHubStatsOptions {
  /**
   * When `true`, suppresses the automatic fetch on mount.
   *
   * Useful when a caching layer wants to decide whether to fetch based on
   * cached data freshness. The caller can trigger a fetch manually via
   * `fetchData()` or `refresh()`.
   *
   * @default false
   */
  skipInitialFetch?: boolean;
}

/**
 * Fetches live GitHub stats for the TUIKit repository.
 *
 * Makes ~13 parallel API requests on mount (unless `skipInitialFetch` is set).
 * All data comes from the public GitHub REST API (no token required for
 * public repos). Rate limit: 60 requests/hour per IP.
 *
 * Returns stats plus a `refresh()` function for manual re-fetch and a
 * `fetchData()` function that returns a promise with the assembled stats.
 */
export function useGitHubStats(options?: UseGitHubStatsOptions): UseGitHubStatsReturn {
  const skipInitialFetch = options?.skipInitialFetch ?? false;
  const [stats, setStats] = useState<GitHubStats>(initialStats);
  const controllerRef = useRef<AbortController | null>(null);

  /**
   * Fetches all GitHub stats and returns the result.
   *
   * Updates internal state AND returns the assembled `GitHubStats` object
   * so external consumers (e.g. a caching wrapper) can store the data.
   */
  const doFetch = useCallback(async (): Promise<GitHubStats> => {
    // Abort any in-flight request
    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;
    const { signal } = controller;

    setStats((prev) => ({ ...prev, loading: true, error: null }));

    try {
      const [
        repoResult,
        commitsResult,
        languagesResult,
        activityResult,
        openPRsCount,
        closedPRsCount,
        closedIssuesCount,
        releasesCount,
        contributorsCount,
        branchesCount,
        tagsCount,
        stargazersResult,
      ] = await Promise.all([
        ghFetch<GitHubRepoResponse>("", signal),

        ghFetch<
          Array<{
            sha: string;
            commit: {
              message: string;
              author: { name: string; date: string };
            };
            html_url: string;
          }>
        >("/commits?per_page=20", signal),

        ghFetch<LanguageBreakdown>("/languages", signal),

        // Try fetching weekly activity; on failure or empty response, fall back to local cache if available
        (async () => {
          try {
            const res = await ghFetch<WeeklyActivity[]>("/stats/commit_activity", signal);
            // If GitHub returns an empty array, the stats endpoint may be pending (202) — try cache
            if (Array.isArray(res.data) && res.data.length > 0) return res;

            // Attempt to read cached weeklyActivity from public JSON
            try {
              const cacheResp = await fetch('/weekly-activity-cache.json', { signal });
              if (cacheResp.ok) {
                const cached = await cacheResp.json();
                return { data: cached as WeeklyActivity[], remaining: res.remaining, limit: res.limit };
              }
            } catch {
              // ignore cache read errors
            }

            return { data: [] as WeeklyActivity[], remaining: res.remaining, limit: res.limit };
          } catch {
            // On network/API failure, attempt cache
            try {
              const cacheResp = await fetch('/weekly-activity-cache.json', { signal });
              if (cacheResp.ok) {
                const cached = await cacheResp.json();
                return { data: cached as WeeklyActivity[], remaining: 0, limit: 60 };
              }
            } catch {
              // ignore
            }
            return { data: [] as WeeklyActivity[], remaining: 0, limit: 60 };
          }
        })(),

        ghCount("/pulls?state=open", signal),
        ghCount("/pulls?state=closed", signal),
        ghCount("/issues?state=closed", signal),
        ghCount("/releases", signal),
        ghCount("/contributors", signal),
        ghCount("/branches", signal),
        ghCount("/tags", signal),

        ghFetch<GitHubStargazerResponse[]>(
          "/stargazers?per_page=100",
          signal,
        ).catch(() => ({ data: [] as GitHubStargazerResponse[], remaining: 0, limit: 60 })),
      ]);

      // Count total commits via Link header
      const commitCountResponse = await fetch(
        `${API}/commits?per_page=1`,
        { signal, headers: ghHeaders() },
      );
      const totalCommits = extractLastPage(commitCountResponse);

      // Count merged PRs (GitHub search API)
      let mergedPRs = 0;
      try {
        const searchResult = await fetch(
          `https://api.github.com/search/issues?q=repo:${OWNER}/${REPO}+is:pr+is:merged&per_page=1`,
          { signal, headers: ghHeaders() },
        );
        if (searchResult.ok) {
          const searchData = await searchResult.json();
          mergedPRs = searchData.total_count ?? 0;
        }
      } catch {
        /* search API can be rate-limited separately */
      }

      // Fetch social cache to merge with stargazers
      let socialCache: SocialCache = { generatedAt: null, entries: {} };
      try {
        const cacheResponse = await fetch("/social-cache.json", { signal });
        if (cacheResponse.ok) {
          socialCache = await cacheResponse.json();
        }
      } catch {
        /* Cache not available, continue without social info */
      }

      const repo = repoResult.data;

      const recentCommits: CommitEntry[] = commitsResult.data.map((commit) => {
        const { title, body } = splitCommitMessage(commit.commit.message);
        return {
          sha: commit.sha.slice(0, 7),
          title,
          body,
          author: commit.commit.author.name,
          date: commit.commit.author.date,
          url: commit.html_url,
        };
      });

      const result: GitHubStats = {
        stars: repo.stargazers_count,
        forks: repo.forks_count,
        watchers: repo.subscribers_count,
        openIssues: repo.open_issues_count,
        size: repo.size,
        defaultBranch: repo.default_branch,
        license: repo.license?.spdx_id ?? null,
        createdAt: repo.created_at,
        updatedAt: repo.updated_at,
        pushedAt: repo.pushed_at,
        totalCommits,
        openPRs: openPRsCount,
        closedPRs: closedPRsCount,
        mergedPRs,
        closedIssues: closedIssuesCount,
        releases: releasesCount,
        contributors: contributorsCount,
        branches: branchesCount,
        tags: tagsCount,
        recentCommits,
        languages: languagesResult.data,
        weeklyActivity: Array.isArray(activityResult.data)
          ? activityResult.data
          : [],
        stargazers: stargazersResult.data.map((user) => {
          const cacheEntry = socialCache.entries[user.login];
          return {
            login: user.login,
            avatarUrl: user.avatar_url,
            profileUrl: user.html_url,
            mastodon: cacheEntry?.mastodon
              ? { handle: cacheEntry.mastodon.handle, url: cacheEntry.mastodon.url }
              : undefined,
            twitter: cacheEntry?.twitter
              ? { handle: cacheEntry.twitter.handle, url: cacheEntry.twitter.url }
              : undefined,
            bluesky: cacheEntry?.bluesky
              ? { handle: cacheEntry.bluesky.handle, url: cacheEntry.bluesky.url }
              : undefined,
          };
        }),
        loading: false,
        error: null,
        rateLimit: {
          remaining: repoResult.remaining,
          limit: repoResult.limit,
        },
      };

      setStats(result);
      return result;
    } catch (err) {
      if (signal.aborted) throw err;
      setStats((prev) => ({
        ...prev,
        loading: false,
        error: err instanceof Error ? err.message : "Unknown error",
      }));
      throw err;
    }
  }, []);

  /** Fire-and-forget refresh — triggers fetch but ignores the returned promise. */
  const refresh = useCallback(() => {
    doFetch().catch(() => {
      /* errors are reflected in stats.error */
    });
  }, [doFetch]);

  useEffect(() => {
    if (!skipInitialFetch) {
      refresh();
    }
    return () => controllerRef.current?.abort();
  }, [refresh, skipInitialFetch]);

  return { ...stats, refresh, fetchData: doFetch };
}
