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
 *          `show` (set new hover), `hide` (clear hover), `cancelHide` (cancel pending hide).
 */
export function useHoverPopover<T>(showDelay = 300, hideDelay = 150) {
  const [hover, setHover] = useState<PopoverState<T> | null>(null);
  const lastRef = useRef<PopoverState<T> | null>(null);
  const showTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const hideTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (hover) lastRef.current = hover;
  }, [hover]);

  const cancelShow = useCallback(() => {
    if (showTimeoutRef.current) {
      clearTimeout(showTimeoutRef.current);
      showTimeoutRef.current = null;
    }
  }, []);

  const cancelHide = useCallback(() => {
    if (hideTimeoutRef.current) {
      clearTimeout(hideTimeoutRef.current);
      hideTimeoutRef.current = null;
    }
  }, []);

  const show = useCallback((data: T, x: number, y: number) => {
    cancelHide();
    cancelShow();
    showTimeoutRef.current = setTimeout(() => {
      setHover({ data, x, y });
    }, showDelay);
  }, [cancelHide, cancelShow, showDelay]);

  const hide = useCallback(() => {
    cancelShow();
    cancelHide();
    hideTimeoutRef.current = setTimeout(() => {
      setHover(null);
    }, hideDelay);
  }, [cancelShow, cancelHide, hideDelay]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (showTimeoutRef.current) clearTimeout(showTimeoutRef.current);
      if (hideTimeoutRef.current) clearTimeout(hideTimeoutRef.current);
    };
  }, []);

  return {
    /** Current hover state — null when not hovering. */
    hover,
    /** Last known state for rendering (stable position during fade-out). */
    popover: hover ?? lastRef.current,
    show,
    hide,
    /** Cancel a pending hide (call when mouse enters popover). */
    cancelHide,
  };
}
