"use client";

import type { ReactNode } from "react";

interface HoverPopoverProps {
  /** Whether the popover is currently visible. */
  visible: boolean;
  /** Horizontal center position relative to the positioned parent. */
  x: number;
  /** Top edge position relative to the positioned parent. */
  y: number;
  /** Vertical offset from y (negative = above). */
  offsetY?: number;
  /** Minimum width of the popover. */
  minWidth?: string;
  /** Content rendered inside the popover bubble. */
  children: ReactNode;
  /** Called when mouse enters the popover (to cancel hide). */
  onMouseEnter?: () => void;
  /** Called when mouse leaves the popover. */
  onMouseLeave?: () => void;
}

/**
 * A floating popover with arrow that fades in/out at a given position.
 *
 * Must be placed inside a `position: relative` container.
 * Centers horizontally on `x` and positions above `y` by default.
 */
export default function HoverPopover({
  visible,
  x,
  y,
  offsetY = -10,
  minWidth,
  children,
  onMouseEnter,
  onMouseLeave,
}: HoverPopoverProps) {
  return (
    <div
      className="absolute z-20"
      style={{
        left: x,
        top: y + offsetY,
        transform: "translateX(-50%) translateY(-100%)",
        pointerEvents: visible ? "auto" : "none",
      }}
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
    >
      {/* Invisible bridge area to help mouse travel from avatar to popover */}
      <div
        className="absolute left-1/2 -translate-x-1/2 w-16"
        style={{ height: Math.abs(offsetY) + 20, bottom: -Math.abs(offsetY) - 10 }}
      />
      <div
        className="rounded-lg border border-border px-4 py-2 shadow-lg shadow-black/30"
        style={{
          minWidth,
          backgroundColor: "var(--container-body)",
          opacity: visible ? 1 : 0,
          transform: visible ? "translateY(0)" : "translateY(15%)",
          transition: "opacity 200ms ease-out, transform 200ms ease-out",
        }}
      >
        {children}
        <div
          className="absolute left-1/2 -bottom-[7px] h-3 w-3 -translate-x-1/2 rotate-45 border-b border-r border-border"
          style={{ backgroundColor: "var(--container-body)" }}
        />
      </div>
    </div>
  );
}
