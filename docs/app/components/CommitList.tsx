"use client";

import { useEffect, useRef, useState } from "react";
import type { CommitEntry } from "../hooks/useGitHubStats";
import Icon from "./Icon";

/** Number of commits shown before the "show more" toggle. */
const INITIAL_COUNT = 8;

interface CommitListProps {
  /** List of recent commits to display. */
  commits: CommitEntry[];
  /** Whether data is still loading. */
  loading?: boolean;
}

/**
 * Formats an ISO date string into separate date and time strings.
 *
 * Returns `{ date: "Feb 03", time: "14:32" }` for stacked display.
 */
function formatDateParts(isoDate: string): { date: string; time: string } {
  const parsed = new Date(isoDate);
  const month = parsed.toLocaleDateString("en-US", { month: "short" });
  const day = parsed.getDate().toString().padStart(2, "0");
  const hours = parsed.getHours().toString().padStart(2, "0");
  const minutes = parsed.getMinutes().toString().padStart(2, "0");
  return { date: `${month} ${day}`, time: `${hours}:${minutes}` };
}

/**
 * Animated collapsible container.
 *
 * Measures content height via ResizeObserver so it correctly tracks
 * changes from nested expansions (e.g. commit bodies opening inside).
 */
function AnimatedCollapse({ expanded, children }: { expanded: boolean; children: React.ReactNode }) {
  const contentRef = useRef<HTMLDivElement>(null);
  const [height, setHeight] = useState(0);

  useEffect(() => {
    const element = contentRef.current;
    if (!element) return;

    if (!expanded) {
      setHeight(0);
      return;
    }

    // Set initial height
    setHeight(element.scrollHeight);

    // Watch for content size changes (e.g. nested commit body expanding)
    const observer = new ResizeObserver(() => {
      setHeight(element.scrollHeight);
    });
    observer.observe(element);

    return () => observer.disconnect();
  }, [expanded]);

  return (
    <div
      className="overflow-hidden transition-all duration-300 ease-in-out"
      style={{ maxHeight: expanded ? height : 0, opacity: expanded ? 1 : 0 }}
    >
      <div ref={contentRef}>
        {children}
      </div>
    </div>
  );
}

/** A single commit row with date/time, title, disclosure chevron, and SHA. */
function CommitRow({
  commit,
  isBodyExpanded,
  onToggleBody,
}: {
  commit: CommitEntry;
  isBodyExpanded: boolean;
  onToggleBody: () => void;
}) {
  const hasBody = commit.body !== null;
  const { date, time } = formatDateParts(commit.date);

  return (
    <li className="py-2.5 first:pt-0 last:pb-0">
      <div className="flex items-center gap-3 min-w-0">
        {/* Date/time — left, stacked with icon */}
        <div className="shrink-0 flex items-start gap-1.5">
          <Icon name="clock" size={16} className="mt-0.5 text-muted/50" />
          <div className="flex flex-col items-end font-mono text-xs leading-tight tabular-nums">
            <span className="text-muted/70">{date}</span>
            <span className="text-muted/50">{time}</span>
          </div>
        </div>

        {/* Disclosure chevron + title — center */}
        <div className="flex items-center gap-1.5 min-w-0 flex-1 overflow-hidden">
          {hasBody ? (
            <button
              onClick={onToggleBody}
              className="shrink-0 flex h-5 w-5 items-center justify-center rounded text-muted transition-colors hover:text-foreground hover:bg-accent/10"
              aria-label={isBodyExpanded ? "Collapse commit body" : "Expand commit body"}
            >
              <span className={`transition-transform duration-200 ${isBodyExpanded ? "rotate-90" : ""}`}>
                <Icon name="chevronRight" size={14} />
              </span>
            </button>
          ) : (
            <span className="w-5 shrink-0" />
          )}
          <span className="block truncate text-base text-foreground/90">{commit.title}</span>
        </div>

        {/* SHA — right */}
        <a
          href={commit.url}
          target="_blank"
          rel="noopener noreferrer"
          className="shrink-0 font-mono text-sm text-accent/70 transition-colors hover:text-accent"
        >
          {commit.sha}
        </a>
      </div>

      {/* Expandable body */}
      {hasBody && (
        <AnimatedCollapse expanded={isBodyExpanded}>
          <pre className="mt-2 ml-7 whitespace-pre-wrap break-words rounded-lg border border-border/20 bg-background/40 px-4 py-3 font-mono text-sm leading-relaxed text-muted/80">
            {commit.body}
          </pre>
        </AnimatedCollapse>
      )}
    </li>
  );
}

/**
 * Displays the most recent commits with title, expandable body, and date/time + SHA.
 *
 * Initially shows 8 commits. A chevron at the bottom toggles the remaining commits
 * with a smooth animation. All expand/collapse actions are animated.
 */
export default function CommitList({ commits, loading = false }: CommitListProps) {
  const [expandedSha, setExpandedSha] = useState<Set<string>>(new Set());
  const [showAll, setShowAll] = useState(false);

  function toggleExpanded(sha: string) {
    setExpandedSha((prev) => {
      const next = new Set(prev);
      if (next.has(sha)) {
        next.delete(sha);
      } else {
        next.add(sha);
      }
      return next;
    });
  }

  const commitsWithBody = commits.filter((commit) => commit.body !== null);
  const allBodiesExpanded = commitsWithBody.length > 0 && commitsWithBody.every((commit) => expandedSha.has(commit.sha));

  function toggleAll() {
    if (allBodiesExpanded) {
      setExpandedSha(new Set());
    } else {
      setExpandedSha(new Set(commitsWithBody.map((commit) => commit.sha)));
      // Also show all commits so hidden bodies become visible
      if (!showAll && commits.length > INITIAL_COUNT) {
        setShowAll(true);
      }
    }
  }

  if (loading) {
    return (
      <div className="overflow-hidden rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
          <Icon name="listBullet" size={22} className="text-muted" />
          Recent Commits
        </h3>
        <div className="flex flex-col gap-3">
          {Array.from({ length: INITIAL_COUNT }).map((_, idx) => (
            <div key={idx} className="flex items-center gap-3">
              <div className="h-5 flex-1 rounded-md bg-accent/10 animate-skeleton" />
              <div className="h-8 w-20 shrink-0 rounded-md bg-accent/10 animate-skeleton" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (commits.length === 0) {
    return (
      <div className="overflow-hidden rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
          <Icon name="listBullet" size={22} className="text-muted" />
          Recent Commits
        </h3>
        <p className="text-lg text-muted">No commits found.</p>
      </div>
    );
  }

  const initialCommits = commits.slice(0, INITIAL_COUNT);
  const extraCommits = commits.slice(INITIAL_COUNT);
  const hasMore = extraCommits.length > 0;

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="flex items-center gap-2 text-xl font-semibold text-foreground">
          <Icon name="listBullet" size={22} className="text-muted" />
          Recent Commits
        </h3>
        {commitsWithBody.length > 0 && (
          <button
            onClick={toggleAll}
            className="flex items-center gap-1.5 rounded-lg px-3 py-1 text-sm text-muted transition-colors hover:bg-accent/5 hover:text-foreground"
          >
            <span className={`transition-transform duration-200 ${allBodiesExpanded ? "rotate-90" : ""}`}>
              <Icon name="chevronRight" size={12} />
            </span>
            {allBodiesExpanded ? "Collapse all" : "Expand all"}
          </button>
        )}
      </div>

      {/* Always-visible commits */}
      <ul className="flex flex-col divide-y divide-border/30">
        {initialCommits.map((commit) => (
          <CommitRow
            key={commit.sha}
            commit={commit}
            isBodyExpanded={expandedSha.has(commit.sha)}
            onToggleBody={() => toggleExpanded(commit.sha)}
          />
        ))}
      </ul>

      {/* Animated extra commits */}
      {hasMore && (
        <AnimatedCollapse expanded={showAll}>
          <ul className="flex flex-col divide-y divide-border/30 border-t border-border/30">
            {extraCommits.map((commit) => (
              <CommitRow
                key={commit.sha}
                commit={commit}
                isBodyExpanded={expandedSha.has(commit.sha)}
                onToggleBody={() => toggleExpanded(commit.sha)}
              />
            ))}
          </ul>
        </AnimatedCollapse>
      )}

      {/* Show more / less toggle */}
      {hasMore && (
        <button
          onClick={() => setShowAll((prev) => !prev)}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg py-2 text-sm text-muted transition-colors hover:bg-accent/5 hover:text-foreground"
          aria-label={showAll ? "Show fewer commits" : "Show all commits"}
        >
          <span className={`transition-transform duration-300 ${showAll ? "rotate-180" : ""}`}>
            <Icon name="chevronRight" size={14} className="rotate-90" />
          </span>
          <span>{showAll ? "Show less" : `Show ${extraCommits.length} more`}</span>
        </button>
      )}
    </div>
  );
}
