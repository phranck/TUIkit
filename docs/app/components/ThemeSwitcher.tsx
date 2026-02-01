"use client";

import { useTheme, themes, type Theme } from "./ThemeProvider";

/** Color dot for each theme, matching Swift palette foreground colors. */
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
      {themes.map((themeOption) => (
        <button
          key={themeOption}
          onClick={() => setTheme(themeOption)}
          aria-label={`Switch to ${themeLabels[themeOption]} theme`}
          className="group relative flex h-7 w-7 cursor-pointer items-center justify-center rounded-full transition-transform hover:scale-110"
        >
          <span
            className="block h-3 w-3 rounded-full transition-all"
            style={{
              backgroundColor: themeColors[themeOption],
              boxShadow:
                theme !== null && theme === themeOption
                  ? `0 0 6px ${themeColors[themeOption]}, 0 0 14px ${themeColors[themeOption]}60`
                  : "none",
              opacity: theme === null ? 0.4 : theme === themeOption ? 1 : 0.4,
            }}
          />
        </button>
      ))}
    </div>
  );
}
