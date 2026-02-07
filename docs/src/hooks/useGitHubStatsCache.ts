

import { useCallback, useEffect, useRef, useState } from "react";
import { useGitHubStats, type GitHubStats } from "./useGitHubStats";

/** How often fresh data is fetched automatically (milliseconds). */
const REFRESH_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

/** Minimum time between force-refresh clicks (milliseconds). */
const FORCE_REFRESH_COOLDOWN_MS = 60 * 1000; // 60 seconds

/** Key used to persist cached stats in localStorage. */
const CACHE_KEY = "tuikit-dashboard-cache";

/** Shape of the localStorage cache entry. */
interface CacheEntry {
  data: GitHubStats;
  fetchedAt: number;
}

/** Return type of the caching wrapper hook. */
export interface UseGitHubStatsCacheReturn extends GitHubStats {
  /** Bypass the cache and fetch fresh data (respects cooldown). */
  forceRefresh: () => void;
  /** Unix timestamp (ms) of the last successful fetch, or null if none yet. */
  lastFetchedAt: number | null;
  /** Unix timestamp (ms) when the next auto-refresh will fire, or null during initial load. */
  nextRefreshAt: number | null;
  /** Whether the force-refresh button is currently allowed (cooldown elapsed). */
  canForceRefresh: boolean;
  /** Whether the currently displayed data was served from localStorage cache. */
  isFromCache: boolean;
  /** Whether a background refresh is in progress (for showing a subtle indicator). */
  isRefreshing: boolean;
}

// ---------------------------------------------------------------------------
// localStorage helpers: all reads/writes are wrapped in try/catch to handle
// Safari Private Mode, full storage, or disabled storage gracefully.
// ---------------------------------------------------------------------------

/** Read and validate the cached entry from localStorage. */
function readCache(): CacheEntry | null {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as CacheEntry;
    if (!parsed || typeof parsed.fetchedAt !== "number" || !parsed.data) {
      localStorage.removeItem(CACHE_KEY);
      return null;
    }
    return parsed;
  } catch {
    // Corrupt data or storage unavailable: clear and move on
    try {
      localStorage.removeItem(CACHE_KEY);
    } catch {
      /* ignore */
    }
    return null;
  }
}

/** Persist stats to localStorage with a timestamp. */
function writeCache(data: GitHubStats): number {
  const fetchedAt = Date.now();
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify({ data, fetchedAt }));
  } catch {
    /* Storage full or unavailable: silently continue without cache */
  }
  return fetchedAt;
}

/**
 * Caching wrapper around `useGitHubStats` that prevents redundant API calls.
 *
 * On mount the hook checks localStorage for a recent cache entry (< 5 min old).
 * If valid cached data exists it is served immediately: no GitHub API call.
 * A background interval automatically refreshes data every 5 minutes.
 *
 * The `forceRefresh` function bypasses the cache but enforces a 60-second
 * cooldown to prevent accidental rate-limit exhaustion.
 */
export function useGitHubStatsCache(): UseGitHubStatsCacheReturn {
  // Skip the automatic fetch on mount: we decide whether to fetch based on cache freshness
  const { fetchData, ...rawStats } = useGitHubStats({ skipInitialFetch: true });

  const [overrideStats, setOverrideStats] = useState<GitHubStats | null>(null);
  const [lastFetchedAt, setLastFetchedAt] = useState<number | null>(null);
  const [nextRefreshAt, setNextRefreshAt] = useState<number | null>(null);
  const [isFromCache, setIsFromCache] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const initializedRef = useRef(false);

  // The stats to expose: override (cached) data takes priority while it's set
  // Force loading: false when we have data, so components don't show skeletons during background refresh
  const activeStats = overrideStats ?? rawStats;
  const hasData = lastFetchedAt !== null;

  // -------------------------------------------------------------------------
  // Core fetch + cache-write logic
  // -------------------------------------------------------------------------

  const doFetchAndCache = useCallback(async () => {
    setIsRefreshing(true);
    try {
      const freshData = await fetchData();
      const timestamp = writeCache(freshData);
      setLastFetchedAt(timestamp);
      setNextRefreshAt(timestamp + REFRESH_INTERVAL_MS);
      setIsFromCache(false);
      // Store the fresh data as override with loading: false to prevent skeleton flash
      setOverrideStats({ ...freshData, loading: false });
    } catch {
      // On error, keep showing previous data (overrideStats stays as-is)
      // Errors are also reflected in rawStats.error via useGitHubStats if needed
    } finally {
      setIsRefreshing(false);
    }
  }, [fetchData]);

  // -------------------------------------------------------------------------
  // Mount: check cache: serve cached data or trigger a fresh fetch
  // -------------------------------------------------------------------------

  useEffect(() => {
    if (initializedRef.current) return;
    initializedRef.current = true;

    const cached = readCache();
    const now = Date.now();

    if (cached && now - cached.fetchedAt < REFRESH_INTERVAL_MS) {
      // Cache is fresh: serve it immediately, no API call needed
      setOverrideStats({ ...cached.data, loading: false, error: null });
      setLastFetchedAt(cached.fetchedAt);
      setNextRefreshAt(cached.fetchedAt + REFRESH_INTERVAL_MS);
      setIsFromCache(true);
    } else {
      // No valid cache: fetch fresh data now
      doFetchAndCache();
    }
  }, [doFetchAndCache]);

  // -------------------------------------------------------------------------
  // Auto-refresh: schedule based on remaining TTL, then repeat every interval
  // -------------------------------------------------------------------------

  const timerInitializedRef = useRef(false);

  useEffect(() => {
    // Only set up the timer once on mount
    if (timerInitializedRef.current) return;
    timerInitializedRef.current = true;

    // Calculate delay until first refresh based on cache age
    const cached = readCache();
    let initialDelay = REFRESH_INTERVAL_MS;
    if (cached) {
      const elapsed = Date.now() - cached.fetchedAt;
      const remaining = REFRESH_INTERVAL_MS - elapsed;
      initialDelay = Math.max(0, remaining);
    }

    // First refresh after remaining TTL
    const timeoutId = setTimeout(() => {
      doFetchAndCache();
      // Then repeat every REFRESH_INTERVAL_MS
      intervalRef.current = setInterval(() => {
        doFetchAndCache();
      }, REFRESH_INTERVAL_MS);
    }, initialDelay);

    return () => {
      clearTimeout(timeoutId);
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [doFetchAndCache]);

  // -------------------------------------------------------------------------
  // Force refresh with cooldown
  // -------------------------------------------------------------------------

  const canForceRefresh = lastFetchedAt === null || Date.now() - lastFetchedAt >= FORCE_REFRESH_COOLDOWN_MS;

  const forceRefresh = useCallback(() => {
    if (lastFetchedAt !== null && Date.now() - lastFetchedAt < FORCE_REFRESH_COOLDOWN_MS) {
      return; // Cooldown active: ignore
    }
    // Reset the interval so the next auto-refresh is a full REFRESH_INTERVAL_MS from now
    if (intervalRef.current) clearInterval(intervalRef.current);
    doFetchAndCache();
    intervalRef.current = setInterval(() => {
      doFetchAndCache();
    }, REFRESH_INTERVAL_MS);
  }, [lastFetchedAt, doFetchAndCache]);

  // Override loading to false if we already have data: prevents skeleton flash during background refresh
  const statsWithLoadingOverride = hasData
    ? { ...activeStats, loading: false }
    : activeStats;

  return {
    ...statsWithLoadingOverride,
    forceRefresh,
    lastFetchedAt,
    nextRefreshAt,
    canForceRefresh,
    isFromCache,
    isRefreshing,
  };
}
