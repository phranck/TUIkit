"use client";

import {
  createContext,
  useCallback,
  useContext,
  useState,
  type ReactNode,
} from "react";

/** Available phosphor themes matching TUIkit's built-in palettes. */
export const themes = ["green", "amber", "white", "red"] as const;
export type Theme = (typeof themes)[number];

interface ThemeContextValue {
  theme: Theme;
  setTheme: (theme: Theme) => void;
}

const ThemeContext = createContext<ThemeContextValue>({
  theme: "amber",
  setTheme: () => {},
});

const STORAGE_KEY = "tuikit-theme";

/**
 * Reads the theme that the blocking script already applied to the DOM.
 * Falls back to "amber" if nothing is set yet (SSR or first visit).
 */
function getInitialTheme(): Theme {
  if (typeof document !== "undefined") {
    const attr = document.documentElement.getAttribute("data-theme") as Theme | null;
    if (attr && themes.includes(attr)) return attr;
  }
  return "amber";
}

/** Provides theme state and applies it to the document root via data-theme attribute. */
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(getInitialTheme);

  const setTheme = useCallback((next: Theme) => {
    setThemeState(next);
    document.documentElement.setAttribute("data-theme", next);
    localStorage.setItem(STORAGE_KEY, next);
  }, []);

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
