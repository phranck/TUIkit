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

/** Type guard: validates that a string is a known theme name. */
function isTheme(value: string | null): value is Theme {
  return !!value && (themes as readonly string[]).includes(value);
}

/**
 * Reads the persisted theme from localStorage (set by the blocking script
 * in BaseLayout.astro), then checks the DOM attribute as fallback.
 * Returns "green" on first visit or during SSR.
 *
 * NOTE: The valid theme list here must match the blocking script in BaseLayout.astro.
 */
function getInitialTheme(): Theme {
  if (typeof window !== "undefined") {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (isTheme(stored)) return stored;
    } catch { /* localStorage unavailable */ }
    const attr = document.documentElement.getAttribute("data-theme");
    if (isTheme(attr)) return attr;
  }
  return "green";
}

/** Provides theme state and applies it to the document root via data-theme attribute. */
export function ThemeProvider({ children }: { children: ReactNode }) {
  /**
   * Start with null on both server and client to avoid hydration mismatch.
   * The blocking script in BaseLayout.astro already sets data-theme on <html> before
   * first paint, so there is no FOUC. React state catches up in useEffect below.
   */
  const [theme, setThemeState] = useState<Theme | null>(null);

  /**
   * After hydration, read the actual theme from DOM/localStorage.
   * This is a legitimate hydration-sync pattern: the server cannot know
   * which theme the user has stored in localStorage, so we must read it
   * on the client and update React state to match reality.
   */
  useEffect(() => {
    const actual = getInitialTheme();
    setThemeState(actual);
    document.documentElement.setAttribute("data-theme", actual);
  }, []);

  const setTheme = useCallback((next: Theme) => {
    setThemeState(next);
    document.documentElement.setAttribute("data-theme", next);
    try { localStorage.setItem(STORAGE_KEY, next); } catch { /* quota exceeded or blocked */ }
  }, []);

  /** Cycle to the next theme when "t" is pressed (skip if user is typing in an input). */
  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key !== "t") return;
      if (theme === null) return;
      const target = event.target;
      if (target instanceof HTMLElement) {
        if (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable) return;
      }

      const currentIndex = themes.indexOf(theme);
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
