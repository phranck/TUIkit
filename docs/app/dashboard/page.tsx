"use client";

import { useState, useCallback } from "react";
import { useGitHubStats } from "../hooks/useGitHubStats";
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
 * Project Dashboard page — displays live GitHub metrics for the TUIKit repository.
 *
 * All data is fetched client-side via the GitHub REST API (no token required).
 * Supports manual refresh via button. Rate limit is displayed in the footer.
 */
export default function DashboardPage() {
  const { refresh, ...stats } = useGitHubStats();
  const [showStargazers, setShowStargazers] = useState(false);

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
          {/* Header with refresh */}
          <div className="mb-10 flex items-center justify-between">
            <div>
              <h1 className="text-4xl font-bold text-foreground">Project Dashboard</h1>
              <p className="mt-1 text-lg text-muted">
                Live metrics · <a href="https://github.com/phranck/TUIkit" target="_blank" rel="noopener noreferrer" className="text-accent transition-colors hover:text-foreground">phranck/TUIkit</a>
              </p>
            </div>
            <button
              onClick={refresh}
              disabled={stats.loading}
              className="flex cursor-pointer items-center gap-2 rounded-full border border-border px-5 py-2 text-base font-medium text-foreground transition-all hover:border-accent/40 hover:bg-white/5 disabled:cursor-not-allowed disabled:opacity-50"
              aria-label="Refresh data"
            >
              <span className={stats.loading ? "animate-spin-slow" : ""}>
                <Icon name="refresh" size={16} />
              </span>
              Refresh
            </button>
          </div>

          {/* Error state */}
          {stats.error && (
            <div className="mb-8 rounded-xl border border-red-500/30 bg-red-500/10 p-4 text-base text-red-400">
              <strong>Error:</strong> {stats.error}
              <button onClick={refresh} className="ml-3 text-accent underline transition-colors hover:text-foreground">
                Retry
              </button>
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
            <StatCard label="Branches" value={stats.branches} icon="branch" loading={stats.loading} />
            <StatCard label="Open PRs" value={stats.openPRs} icon="pullRequest" loading={stats.loading} />
            <StatCard label="Merged PRs" value={stats.mergedPRs} icon="merge" loading={stats.loading} />
          </div>

          {/* Activity heatmap */}
          <div className="mb-8">
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

          {/* Rate limit */}
          {stats.rateLimit && (
            <div className="text-right font-mono text-sm text-muted/60">
              API rate limit: {stats.rateLimit.remaining}/{stats.rateLimit.limit} remaining
            </div>
          )}
        </main>

        <SiteFooter />
      </div>
    </div>
  );
}
