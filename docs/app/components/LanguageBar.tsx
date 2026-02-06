"use client";

import type { LanguageBreakdown } from "../hooks/useGitHubStats";
import Icon from "./Icon";

interface LanguageBarProps {
  /** Language byte counts from the GitHub API. */
  languages: LanguageBreakdown;
  /** Whether data is still loading. */
  loading?: boolean;
}

/**
 * Color palette for up to 6 languages, using theme-consistent colors.
 *
 * Swift gets the accent color, others get progressively muted tones.
 */
const LANG_COLORS = [
  "bg-accent",
  "bg-accent-secondary",
  "bg-muted",
  "bg-border",
  "bg-foreground/30",
  "bg-foreground/15",
];

/**
 * A horizontal stacked bar showing the language breakdown of the repository.
 *
 * Each segment is proportional to the byte count. A legend below the bar lists
 * each language with its percentage.
 */
export default function LanguageBar({ languages, loading = false }: LanguageBarProps) {
  if (loading) {
    return (
      <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-3 text-xl font-semibold text-foreground">
          <Icon name="swift" size={20} className="text-accent" />
          Languages
        </h3>
        <div className="h-4 w-full rounded-full bg-accent/10 animate-skeleton" />
        <div className="mt-3 flex gap-4">
          <div className="h-4 w-16 rounded-md bg-accent/10 animate-skeleton" />
          <div className="h-4 w-12 rounded-md bg-accent/10 animate-skeleton" />
        </div>
      </div>
    );
  }

  const entries = Object.entries(languages).sort((entryA, entryB) => entryB[1] - entryA[1]);
  const totalBytes = entries.reduce((sum, [, bytes]) => sum + bytes, 0);

  if (totalBytes === 0) {
    return (
      <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-3 text-xl font-semibold text-foreground">
          <Icon name="swift" size={20} className="text-accent" />
          Languages
        </h3>
        <p className="text-lg text-muted">No language data available.</p>
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
      <h3 className="mb-4 flex items-center gap-3 text-xl font-semibold text-foreground">
        <Icon name="swift" size={20} className="text-accent" />
        Languages
      </h3>

      {/* Stacked bar */}
      <div className="flex h-4 w-full overflow-hidden rounded-full">
        {entries.map(([lang, bytes], idx) => {
          const pct = (bytes / totalBytes) * 100;
          return (
            <div
              key={lang}
              className={`${LANG_COLORS[idx % LANG_COLORS.length]} transition-all duration-300`}
              style={{ width: `${Math.max(pct, 0.5)}%` }}
              title={`${lang}: ${pct.toFixed(1)}%`}
            />
          );
        })}
      </div>

      {/* Legend */}
      <div className="mt-3 flex flex-wrap gap-x-5 gap-y-1">
        {entries.map(([lang, bytes], idx) => {
          const pct = (bytes / totalBytes) * 100;
          return (
            <div key={lang} className="flex items-center gap-1.5 text-base text-muted">
              <span className={`inline-block h-3 w-3 rounded-sm ${LANG_COLORS[idx % LANG_COLORS.length]}`} />
              <span>{lang}</span>
              <span className="text-foreground/60">{pct < 0.1 ? "<0.1" : pct.toFixed(1)}%</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
