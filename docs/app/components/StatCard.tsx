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
  /** Optional click handler — makes the card interactive. */
  onClick?: () => void;
  /** Whether this card is currently in active/expanded state. */
  active?: boolean;
}

/**
 * A single metric card with icon + label on top and the number on the right.
 *
 * When `onClick` is provided, renders as a `<button>` with native keyboard
 * and focus support. Otherwise renders as a static `<div>`.
 */
export default function StatCard({ label, value, icon, loading = false, onClick, active = false }: StatCardProps) {
  const interactive = !!onClick;

  const baseClasses = "flex w-full items-center justify-between rounded-xl border p-5 backdrop-blur-xl transition-all duration-300";
  const stateClasses = active
    ? "border-accent/50 bg-accent/10"
    : "border-border bg-frosted-glass hover:border-accent/30";
  const interactiveClasses = interactive
    ? "cursor-pointer hover:bg-accent/5 hover:scale-[1.02] active:scale-[0.98]"
    : "";
  const className = `${baseClasses} ${stateClasses} ${interactiveClasses}`;

  const content = loading ? (
    <div className="flex w-full items-center justify-between">
      <div className="flex items-center gap-2">
        <div className="h-6 w-6 rounded-md bg-accent/10 animate-skeleton" />
        <div className="h-5 w-16 rounded-md bg-accent/10 animate-skeleton" />
      </div>
      <div className="h-8 w-14 rounded-md bg-accent/10 animate-skeleton" />
    </div>
  ) : (
    <>
      <p className="flex items-center gap-2 text-lg text-muted">
        <Icon name={icon} size={22} className="text-accent" />
        {label}
      </p>
      <p className="text-3xl font-bold text-foreground text-glow tabular-nums">
        {value.toLocaleString()}
      </p>
    </>
  );

  if (interactive) {
    return (
      <button type="button" onClick={onClick} className={className}>
        {content}
      </button>
    );
  }

  return <div className={className}>{content}</div>;
}
