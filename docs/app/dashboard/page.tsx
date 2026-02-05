"use client";

import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useGitHubStatsCache } from "../hooks/useGitHubStatsCache";
import CloudBackground from "../components/CloudBackground";
import RainOverlay from "../components/RainOverlay";
import SpinnerLights from "../components/SpinnerLights";
import Icon from "../components/Icon";
import SiteNav from "../components/SiteNav";
import SiteFooter from "../components/SiteFooter";
import StatCard from "../components/StatCard";
import StargazersPanel from "../components/StargazersPanel";
import ActivityHeatmap from "../components/ActivityHeatmap";
import LanguageBar from "../components/LanguageBar";
import CommitList from "../components/CommitList";
import RepoInfo from "../components/RepoInfo";

/**
 * Formats a relative time string like "2 min ago" or "just now".
 *
 * Uses simple second/minute thresholds — no need for Intl.RelativeTimeFormat
 * since the maximum age before auto-refresh is 5 minutes.
 */
function formatTimeAgo(timestampMs: number): string {
  const seconds = Math.floor((Date.now() - timestampMs) / 1000);
  if (seconds < 5) return "just now";
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  if (remainingSeconds === 0) return `${minutes} min ago`;
  return `${minutes} min ${remainingSeconds}s ago`;
}

/**
 * Formats a countdown string like "3:12" from a future timestamp.
 *
 * Returns "now" if the target is in the past or within 1 second.
 */
function formatCountdown(targetMs: number): string {
  const remainingSeconds = Math.max(0, Math.floor((targetMs - Date.now()) / 1000));
  if (remainingSeconds <= 0) return "now";
  const minutes = Math.floor(remainingSeconds / 60);
  const seconds = remainingSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

/**
 * Project Dashboard page — displays live GitHub metrics for the TUIKit repository.
 *
 * Data is cached in localStorage for 5 minutes. Page reloads within that window
 * serve cached data without hitting the GitHub API. A background timer
 * auto-refreshes every 5 minutes. An animated refresh icon appears during loading.
 */
export default function DashboardPage() {
  const {
    lastFetchedAt,
    nextRefreshAt,
    isFromCache,
    isRefreshing,
    ...stats
  } = useGitHubStatsCache();

  const [showStargazers, setShowStargazers] = useState(false);

  // Tick every second to update the "last updated" and countdown displays
  const [, setTick] = useState(0);
  useEffect(() => {
    const timer = setInterval(() => setTick((prev) => prev + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  // Preload stargazer avatar images in background so the panel opens instantly
  useEffect(() => {
    if (!stats.stargazers || stats.stargazers.length === 0) return;
    const head = document.head || document.getElementsByTagName('head')[0];
    const existing = new Set(Array.from(head.querySelectorAll('link[rel="preload"][as="image"]')).map((l) => (l as HTMLLinkElement).href));

    stats.stargazers.slice(0, 100).forEach((s) => {
      const url = s.avatarUrl + '&s=128';
      if (existing.has(url)) return;
      const link = document.createElement('link');
      link.rel = 'preload';
      link.as = 'image';
      link.href = url;
      head.appendChild(link);
    });
  }, [stats.stargazers]);

  const toggleStargazers = useCallback(() => setShowStargazers((prev) => !prev), []);
  const closeStargazers = useCallback(() => setShowStargazers(false), []);

  return (
    <div className="relative min-h-screen">
      <CloudBackground />
      <RainOverlay />
      <SpinnerLights />

      {/* Skip navigation */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[9999] focus:rounded-lg focus:bg-background focus:px-4 focus:py-2 focus:text-foreground focus:ring-2 focus:ring-accent"
      >
        Skip to main content
      </a>

      <div className="relative z-10 flex min-h-screen flex-col">
        <SiteNav activePage="dashboard" />

        <main id="main-content" tabIndex={-1} className="mx-auto w-full max-w-6xl flex-1 px-6 pt-28 pb-20">
          {/* Header with loading indicator */}
          <div className="mb-6 flex flex-col items-center text-center sm:mb-10 sm:flex-row sm:items-center sm:justify-between sm:text-left">
            <div>
              <h1 className="text-3xl font-bold text-foreground sm:text-4xl">Project Dashboard</h1>
              <p className="mt-1 text-base text-muted sm:text-lg">
                Live metrics · <a href="https://github.com/phranck/TUIkit" target="_blank" rel="noopener noreferrer" className="text-accent transition-colors hover:text-foreground">phranck/TUIkit</a>
              </p>
            </div>
            {/* Animated refresh icon — fades in while refreshing, spins, then fades out */}
            <AnimatePresence>
              {isRefreshing && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8 }}
                  transition={{ duration: 0.2 }}
                  className="mt-3 flex items-center justify-center sm:mt-0"
                  aria-label="Refreshing data"
                >
                  <span className="animate-spin-slow text-muted">
                    <Icon name="refresh" size={20} />
                  </span>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Error state */}
          {stats.error && (
            <div className="mb-8 rounded-xl border border-red-500/30 bg-red-500/10 p-4 text-base text-red-400">
              <strong>Error:</strong> {stats.error}
              <span className="ml-3 text-muted/60">Will retry automatically</span>
            </div>
          )}

          {/* Stat cards — row 1 */}
          <div className="mb-4 grid grid-cols-2 gap-4 md:grid-cols-4">
            <StatCard id="stat-card-stars" label="Stars" value={stats.stars} icon="star" loading={stats.loading} onClick={toggleStargazers} active={showStargazers} />
            <StatCard id="stat-card-contributors" label="Contributors" value={stats.contributors} icon="person2" loading={stats.loading} />
            <StatCard label="Forks" value={stats.forks} icon="branch" loading={stats.loading} />
            <StatCard label="Releases" value={stats.releases} icon="shippingbox" loading={stats.loading} />
          </div>

          {/* Stargazers panel — expands between the two rows */}
          <div className={showStargazers ? "mb-4" : ""}>
            <StargazersPanel
              stargazers={stats.stargazers}
              totalStars={stats.stars}
              open={showStargazers}
              onClose={closeStargazers}
            />
          </div>

          {/* Stat cards — row 2 */}
          <div className="mb-8 grid grid-cols-2 gap-4 md:grid-cols-4">
            <StatCard label="Commits" value={stats.totalCommits} icon="numberCircle" loading={stats.loading} />
            <StatCard label="Open Issues" value={stats.openIssues} icon="issue" loading={stats.loading} />
            <StatCard label="Open PRs" value={stats.openPRs} icon="pullRequest" loading={stats.loading} />
            <StatCard label="Merged PRs" value={stats.mergedPRs} icon="merge" loading={stats.loading} />
          </div>

          {/* Activity heatmap — hidden on mobile */}
          <div className="mb-8 hidden sm:block">
            <ActivityHeatmap weeks={stats.weeklyActivity} loading={stats.loading} />
          </div>

          {/* Languages + Repo Info + Commits */}
          <div className="mb-8 grid gap-8 lg:grid-cols-[1fr_2fr]">
            <div className="flex flex-col gap-8">
              <LanguageBar languages={stats.languages} loading={stats.loading} />
              <RepoInfo
                createdAt={stats.createdAt}
                license={stats.license}
                size={stats.size}
                defaultBranch={stats.defaultBranch}
                pushedAt={stats.pushedAt}
                loading={stats.loading}
              />
            </div>
            <CommitList commits={stats.recentCommits} loading={stats.loading} />
          </div>

          {/* Footer: cache status (centered on mobile) + rate limit (desktop only) */}
          <div className="flex flex-col items-center gap-2 font-mono text-xs text-muted/60 sm:flex-row sm:justify-between sm:text-sm">
            <div className="flex flex-wrap items-center justify-center gap-x-2 gap-y-1 text-center sm:justify-start sm:text-left">
              {lastFetchedAt && (
                <>
                  <span>
                    Updated {formatTimeAgo(lastFetchedAt)}
                    {isFromCache && (
                      <span className="ml-1 rounded bg-white/5 px-1 py-0.5 text-[10px] text-muted/40 sm:ml-1.5 sm:px-1.5 sm:text-xs">
                        cached
                      </span>
                    )}
                  </span>
                  {nextRefreshAt && (
                    <span className="text-muted/40">
                      · Next in {formatCountdown(nextRefreshAt)}
                    </span>
                  )}
                </>
              )}
            </div>
            {stats.rateLimit && (
              <div className="hidden sm:block">
                API rate limit: {stats.rateLimit.remaining}/{stats.rateLimit.limit} remaining
              </div>
            )}
          </div>
        </main>

        <SiteFooter />
      </div>
    </div>
  );
}
