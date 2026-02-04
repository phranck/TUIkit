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
}

/**
 * A floating popover with arrow that fades in/out at a given position.
 *
 * Must be placed inside a `position: relative` container.
 * Centers horizontally on `x` and positions above `y` by default.
 */
export default function HoverPopover({ visible, x, y, offsetY = -10, minWidth, children }: HoverPopoverProps) {
  return (
    <div
      className="pointer-events-none absolute z-20 rounded-lg border border-border px-4 py-2 shadow-lg shadow-black/30 transition-opacity duration-150"
      style={{
        left: x,
        top: y + offsetY,
        transform: "translateX(-50%) translateY(-100%)",
        minWidth,
        backgroundColor: "var(--container-body)",
        opacity: visible ? 1 : 0,
      }}
    >
      {children}
      <div
        className="absolute left-1/2 -bottom-[7px] h-3 w-3 -translate-x-1/2 rotate-45 border-b border-r border-border"
        style={{ backgroundColor: "var(--container-body)" }}
      />
    </div>
  );
}
