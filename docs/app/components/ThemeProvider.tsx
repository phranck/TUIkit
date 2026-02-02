"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";

/** Available phosphor themes matching TUIkit's built-in palettes. */
export const themes = ["green", "amber", "red", "violet", "blue", "white"] as const;
export type Theme = (typeof themes)[number];

interface ThemeContextValue {
  /** Current theme, or null while hydrating (before localStorage is read). */
  theme: Theme | null;
  setTheme: (theme: Theme) => void;
}

const ThemeContext = createContext<ThemeContextValue>({
  theme: null,
  setTheme: () => {},
});

const STORAGE_KEY = "tuikit-theme";

/**
 * Reads the persisted theme from localStorage (set by the blocking script
 * in layout.tsx), then checks the DOM attribute as fallback.
 * Returns "green" on first visit or during SSR.
 */
function getInitialTheme(): Theme {
  if (typeof window !== "undefined") {
    try {
      const stored = localStorage.getItem(STORAGE_KEY) as Theme | null;
      if (stored && themes.includes(stored)) return stored;
    } catch { /* localStorage unavailable */ }
    const attr = document.documentElement.getAttribute("data-theme") as Theme | null;
    if (attr && themes.includes(attr)) return attr;
  }
  return "green";
}

/** Provides theme state and applies it to the document root via data-theme attribute. */
export function ThemeProvider({ children }: { children: ReactNode }) {
  /**
   * Start with null on both server and client to avoid hydration mismatch.
   * The blocking script in layout.tsx already sets data-theme on <html> before
   * first paint, so there is no FOUC. React state catches up in useEffect below.
   */
  const [theme, setThemeState] = useState<Theme | null>(null);

  /**
   * After hydration, read the actual theme from DOM/localStorage.
   * This runs once on mount and sets the React state to match reality.
   */
  useEffect(() => {
    const actual = getInitialTheme();
    setThemeState(actual);
    document.documentElement.setAttribute("data-theme", actual);
  }, []);

  const setTheme = useCallback((next: Theme) => {
    setThemeState(next);
    document.documentElement.setAttribute("data-theme", next);
    localStorage.setItem(STORAGE_KEY, next);
  }, []);

  /** Cycle to the next theme when "t" is pressed (skip if user is typing in an input). */
  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key !== "t") return;
      const target = event.target as HTMLElement;
      if (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable) return;

      const currentIndex = themes.indexOf(theme as Theme);
      const nextIndex = (currentIndex + 1) % themes.length;
      setTheme(themes[nextIndex]);
    }

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [theme, setTheme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

/** Hook to access the current theme and setter. */
export function useTheme() {
  return useContext(ThemeContext);
}
