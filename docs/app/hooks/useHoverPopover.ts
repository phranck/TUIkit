"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/** Position and content for a hover popover. */
export interface PopoverState<T> {
  data: T;
  x: number;
  y: number;
}

/**
 * Manages hover-triggered popover state with stable position on dismiss.
 *
 * Tracks the current hover target and remembers the last position so the
 * popover can fade out in place instead of jumping to (0, 0).
 *
 * @returns `hover` (current state or null), `popover` (last known state for rendering),
 *          `show` (set new hover), `hide` (clear hover).
 */
export function useHoverPopover<T>() {
  const [hover, setHover] = useState<PopoverState<T> | null>(null);
  const lastRef = useRef<PopoverState<T> | null>(null);

  useEffect(() => {
    if (hover) lastRef.current = hover;
  }, [hover]);

  const show = useCallback((data: T, x: number, y: number) => {
    setHover({ data, x, y });
  }, []);

  const hide = useCallback(() => {
    setHover(null);
  }, []);

  return {
    /** Current hover state — null when not hovering. */
    hover,
    /** Last known state for rendering (stable position during fade-out). */
    popover: hover ?? lastRef.current,
    show,
    hide,
  };
}
