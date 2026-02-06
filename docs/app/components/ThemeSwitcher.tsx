"use client";

import { useTheme, themes, type Theme } from "./ThemeProvider";

/**
 * Fixed foreground color per theme: used for the color dots so each dot
 * always shows its own theme color regardless of the currently active theme.
 * Values mirror the --foreground CSS variables in globals.css.
 */
const themeColors: Record<Theme, string> = {
  green: "#33ff33",
  amber: "#ffaa00",
  red: "#ff4444",
  violet: "#bb77ff",
  blue: "#00aaff",
  white: "#e8e8e8",
};

/** Theme labels for accessibility. */
const themeLabels: Record<Theme, string> = {
  green: "Green",
  amber: "Amber",
  red: "Red",
  violet: "Violet",
  blue: "Blue",
  white: "White",
};

/** Compact theme switcher with colored dots and active indicator. */
export default function ThemeSwitcher() {
  const { theme, setTheme } = useTheme();

  return (
    <div className="flex items-center gap-1.5">
      {themes.map((themeOption) => {
        const isActive = theme === themeOption;
        return (
          <button
            key={themeOption}
            onClick={() => setTheme(themeOption)}
            aria-label={`${themeLabels[themeOption]} theme`}
            aria-pressed={isActive}
            className="group relative flex h-7 w-7 cursor-pointer items-center justify-center rounded-full transition-transform hover:scale-110 focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background"
          >
            <span
              className={`block h-3 w-3 rounded-full ${isActive ? "animate-[theme-pulse_3s_ease-in-out_infinite]" : "transition-all"}`}
              style={{
                backgroundColor: themeColors[themeOption],
                boxShadow: isActive
                  ? `0 0 8px ${themeColors[themeOption]}, 0 0 20px ${themeColors[themeOption]}90, 0 0 36px ${themeColors[themeOption]}40`
                  : "none",
                opacity: isActive ? 1 : 0.35,
              }}
            />
          </button>
        );
      })}
    </div>
  );
}
