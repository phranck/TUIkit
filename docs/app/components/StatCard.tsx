"use client";

import type { IconName } from "./Icon";
import Icon from "./Icon";

interface StatCardProps {
  /** The stat label shown next to the icon. */
  label: string;
  /** The numeric value to display. */
  value: number;
  /** SF Symbol icon name displayed next to the label. */
  icon: IconName;
  /** Whether data is still loading (shows skeleton). */
  loading?: boolean;
  /** Optional click handler: makes the card interactive. */
  onClick?: () => void;
  /** Whether this card is currently in active/expanded state. */
  active?: boolean;
  /** Optional ID for targeting (e.g., for arrow positioning). */
  id?: string;
}

/**
 * A single metric card with icon + label on top and the number below.
 *
 * On mobile: stacked vertically (icon+label top, number bottom center).
 * On larger screens: horizontal layout (icon+label left, number right).
 *
 * When `onClick` is provided, renders as a `<button>` with native keyboard
 * and focus support. Otherwise renders as a static `<div>`.
 */
export default function StatCard({ label, value, icon, loading = false, onClick, active = false, id }: StatCardProps) {
  const interactive = !!onClick;

  const baseClasses = "flex w-full flex-col items-center gap-2 rounded-xl border p-4 backdrop-blur-xl transition-all duration-300 sm:flex-row sm:items-center sm:justify-between sm:gap-3 sm:p-5";
  const stateClasses = active
    ? "border-accent/50 bg-accent/10"
    : "border-border bg-frosted-glass hover:border-accent/30";
  const interactiveClasses = interactive
    ? "cursor-pointer hover:bg-accent/5 hover:scale-[1.02] active:scale-[0.98]"
    : "";
  const className = `${baseClasses} ${stateClasses} ${interactiveClasses}`;

  const content = loading ? (
    <div className="flex w-full flex-col items-center gap-2 sm:flex-row sm:justify-between">
      <div className="flex items-center gap-2">
        <div className="h-5 w-5 rounded-md bg-accent/10 animate-skeleton sm:h-6 sm:w-6" />
        <div className="h-4 w-14 rounded-md bg-accent/10 animate-skeleton sm:h-5 sm:w-16" />
      </div>
      <div className="h-7 w-12 rounded-md bg-accent/10 animate-skeleton sm:h-8 sm:w-14" />
    </div>
  ) : (
    <>
      <p className="flex items-center gap-1.5 text-sm text-muted sm:gap-2 sm:text-lg">
        <Icon name={icon} size={18} className="text-accent sm:h-[22px] sm:w-[22px]" />
        <span className="whitespace-nowrap">{label}</span>
      </p>
      <p className="text-2xl font-bold text-foreground text-glow tabular-nums sm:text-3xl">
        {value.toLocaleString()}
      </p>
    </>
  );

  if (interactive) {
    return (
      <button type="button" id={id} onClick={onClick} className={className}>
        {content}
      </button>
    );
  }

  return <div id={id} className={className}>{content}</div>;
}
