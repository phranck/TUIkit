"use client";

import { useEffect, useRef, useState } from "react";
import type { WeeklyActivity } from "../hooks/useGitHubStats";
import { useHoverPopover } from "../hooks/useHoverPopover";
import HoverPopover from "./HoverPopover";
import Icon from "./Icon";

interface ActivityHeatmapProps {
  /** 52 weeks of commit activity data. */
  weeks: WeeklyActivity[];
  /** Whether data is still loading. */
  loading?: boolean;
}

const DAY_LABELS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** Pixel gap between cells. */
const CELL_GAP = 3;
/** Width of the day-label column including right padding. */
const LABEL_WIDTH = 32;
/** Minimum cell size to prevent cells from becoming invisible. */
const MIN_CELL_SIZE = 6;

/**
 * Formats a Unix timestamp (seconds) + day offset into a readable date.
 */
function formatDate(weekTimestamp: number, dayIndex: number): string {
  const date = new Date((weekTimestamp + dayIndex * 86400) * 1000);
  return date.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", year: "numeric" });
}

/**
 * Builds month labels with pixel offsets relative to the cell grid.
 */
function buildMonthLabels(weeks: WeeklyActivity[], cellSize: number): { label: string; offset: number }[] {
  const labels: { label: string; offset: number }[] = [];
  let lastMonth = -1;

  for (let idx = 0; idx < weeks.length; idx++) {
    const date = new Date(weeks[idx].week * 1000);
    const month = date.getMonth();
    if (month !== lastMonth) {
      labels.push({
        label: MONTH_NAMES[month],
        offset: idx * (cellSize + CELL_GAP),
      });
      lastMonth = month;
    }
  }

  return labels;
}

/** Data displayed in the hover popover. */
interface HeatmapHover {
  date: string;
  count: number;
}

/** Maps intensity level (0–4) to a Tailwind opacity class. */
const OPACITY_MAP: Record<number, string> = {
  0: "opacity-[0.06]",
  1: "opacity-[0.25]",
  2: "opacity-[0.45]",
  3: "opacity-[0.7]",
  4: "opacity-100",
};

/** Returns an intensity level (0–4) for a commit count relative to the maximum. */
function intensityLevel(count: number, maxCommits: number): number {
  if (count === 0) return 0;
  const ratio = count / maxCommits;
  if (ratio <= 0.25) return 1;
  if (ratio <= 0.5) return 2;
  if (ratio <= 0.75) return 3;
  return 4;
}

/**
 * Calculates the cell size that fills the available container width.
 * Formula: floor((availableWidth - LABEL_WIDTH - (colCount - 1) * CELL_GAP) / colCount)
 */
function computeCellSize(containerWidth: number, colCount: number): number {
  const availableForCells = containerWidth - LABEL_WIDTH - (colCount - 1) * CELL_GAP;
  return Math.max(MIN_CELL_SIZE, Math.floor(availableForCells / colCount));
}

/**
 * A GitHub-style commit activity heatmap showing 52 weeks of daily commit counts.
 *
 * Cell size is dynamically calculated to fill the available container width.
 * Layout: day labels on the left, a column-flow grid of square cells on the right.
 * Month labels are positioned above the grid using pixel offsets.
 */
export default function ActivityHeatmap({ weeks, loading = false }: ActivityHeatmapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [cellSize, setCellSize] = useState(0);
  const { hover, popover, show: showPopover, hide: hidePopover } = useHoverPopover<HeatmapHover>();

  const colCount = weeks.length;

  useEffect(() => {
    const container = containerRef.current;
    if (!container || colCount === 0) return;

    const observer = new ResizeObserver((entries) => {
      for (const entry of entries) {
        setCellSize(computeCellSize(entry.contentRect.width, colCount));
      }
    });

    observer.observe(container);
    // Initial measurement
    setCellSize(computeCellSize(container.clientWidth, colCount));

    return () => observer.disconnect();
  }, [colCount]);

  if (loading) {
    return (
      <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
          <Icon name="calendar" size={22} className="text-muted" />
          Commit Activity
        </h3>
        <div className="h-32 w-full rounded-md bg-accent/10 animate-skeleton" />
      </div>
    );
  }

  if (weeks.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
          <Icon name="calendar" size={22} className="text-muted" />
          Commit Activity
        </h3>
        <p className="text-lg text-muted">No activity data available yet.</p>
      </div>
    );
  }

  const maxCommits = Math.max(1, ...weeks.flatMap((week) => week.days));
  const monthLabels = buildMonthLabels(weeks, cellSize);

  function handleMouseEnter(event: React.MouseEvent<HTMLDivElement>, weekTimestamp: number, dayIdx: number, count: number) {
    const cell = event.currentTarget;
    const wrapper = cell.closest("[data-heatmap-grid]");
    if (!wrapper) return;

    const wrapperRect = wrapper.getBoundingClientRect();
    const cellRect = cell.getBoundingClientRect();

    showPopover(
      { date: formatDate(weekTimestamp, dayIdx), count },
      cellRect.left - wrapperRect.left + cellRect.width / 2,
      cellRect.top - wrapperRect.top,
    );
  }

  const gridHeight = 7 * cellSize + 6 * CELL_GAP;

  return (
    <div ref={containerRef} className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
      <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
        <Icon name="calendar" size={22} className="text-muted" />
        Commit Activity
      </h3>

      {cellSize > 0 && (
        <div className="relative" data-heatmap-grid onMouseLeave={hidePopover}>

          {/* Month labels — absolutely positioned above the cell grid */}
          <div className="relative h-5" style={{ marginLeft: LABEL_WIDTH }}>
            {monthLabels.map(({ label, offset }) => (
              <span
                key={`${label}-${offset}`}
                className="absolute bottom-0 text-xs text-muted"
                style={{ left: offset }}
              >
                {label}
              </span>
            ))}
          </div>

          {/* Day labels (left) + Cell grid (right) */}
          <div className="flex">
            {/* Day labels */}
            <div
              className="flex shrink-0 flex-col"
              style={{
                width: LABEL_WIDTH,
                height: gridHeight,
                justifyContent: "space-around",
              }}
            >
              {DAY_LABELS.map((day) => (
                <span
                  key={day}
                  className="text-right text-xs leading-none text-muted"
                  style={{ height: cellSize, lineHeight: `${cellSize}px`, paddingRight: 6 }}
                >
                  {day}
                </span>
              ))}
            </div>

            {/* Cell grid — column-flow: 7 rows, columns auto-created per week */}
            <div
              className="grid"
              style={{
                gridTemplateRows: `repeat(7, ${cellSize}px)`,
                gridAutoFlow: "column",
                gridAutoColumns: `${cellSize}px`,
                gap: CELL_GAP,
              }}
            >
              {weeks.map((week) =>
                week.days.map((count, dayIdx) => {
                  const level = intensityLevel(count, maxCommits);
                  return (
                    <div
                      key={`${week.week}-${dayIdx}`}
                      className={`rounded-sm bg-accent ${OPACITY_MAP[level]} transition-opacity hover:ring-1 hover:ring-accent/60`}
                      style={{ width: cellSize, height: cellSize }}
                      onMouseEnter={(event) => count > 0 && handleMouseEnter(event, week.week, dayIdx, count)}
                      onMouseLeave={hidePopover}
                    />
                  );
                })
              )}
            </div>
          </div>

          {/* Popover */}
          <HoverPopover
            visible={!!hover}
            x={popover?.x ?? 0}
            y={popover?.y ?? 0}
            offsetY={-11}
            minWidth="10rem"
          >
            <p className="whitespace-nowrap text-center text-sm font-medium text-foreground">{popover?.data.date}</p>
            <p className="whitespace-nowrap text-center text-sm text-muted">
              <span className="font-bold text-accent">{popover?.data.count ?? 0}</span> commit{popover?.data.count !== 1 ? "s" : ""}
            </p>
          </HoverPopover>
        </div>
      )}

      {/* Legend */}
      <div className="mt-6 flex items-center justify-center gap-1.5 text-xs text-muted">
        <span>Less</span>
        {[0, 1, 2, 3, 4].map((level) => (
          <div
            key={level}
            className={`rounded-sm bg-accent ${OPACITY_MAP[level]}`}
            style={{ width: 11, height: 11 }}
          />
        ))}
        <span>More</span>
      </div>
    </div>
  );
}
