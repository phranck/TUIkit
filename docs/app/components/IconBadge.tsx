"use client";

import type { IconName } from "./Icon";
import Icon from "./Icon";

interface IconBadgeProps {
  /** Icon name to display. */
  name: IconName;
  /** Icon size in pixels (default: 24). */
  size?: number;
  /** Optional CSS class for the wrapper. */
  className?: string;
  /** Size variant for the badge (default: 'md'). */
  variant?: "sm" | "md" | "lg";
}

const variantClasses = {
  sm: "h-8 w-8",
  md: "h-10 w-10",
  lg: "h-12 w-12",
} as const;

/** Icon badge with background — unified display for SF Symbols across the dashboard and pages. */
export default function IconBadge({
  name,
  size = 24,
  className = "",
  variant = "md",
}: IconBadgeProps) {
  return (
    <div
      className={`flex shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent transition-colors group-hover:bg-accent/15 ${variantClasses[variant]} ${className}`}
    >
      <Icon name={name} size={size} />
    </div>
  );
}
