"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/**
 * Hook for copy-to-clipboard with auto-reset feedback.
 *
 * Returns `copied` (true for `resetDelayMs` after copy) and an async `copy` function.
 * Handles rapid clicks (cancels previous timer), clipboard API errors, and
 * cleanup on unmount. Used by CodePreview and PackageBadge.
 */
export function useCopyToClipboard(resetDelayMs = 2000) {
  const [copied, setCopied] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  /** Clear any pending reset timer. */
  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  const copy = useCallback(async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      // Cancel previous timer on rapid clicks
      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(() => setCopied(false), resetDelayMs);
    } catch {
      // Clipboard API unavailable or permission denied: silently degrade
    }
  }, [resetDelayMs]);

  return { copied, copy };
}
