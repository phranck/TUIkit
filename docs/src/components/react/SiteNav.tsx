import { useState } from "react";
import Icon from "./Icon";
import ThemeSwitcher from "./ThemeSwitcher";
import { ThemeProvider } from "./ThemeProvider";

/** Identifies which page is currently active in the navigation. */
export type ActivePage = "home" | "dashboard";

interface SiteNavProps {
  /** Which nav item to highlight as active. */
  activePage?: ActivePage;
}

/** Navigation link definition. */
interface NavLink {
  href: string;
  label: string;
  icon?: Parameters<typeof Icon>[0]["name"];
  external?: boolean;
  /** If set, this link is rendered as active text (not a link) when matching. */
  page?: ActivePage;
}

const NAV_LINKS: NavLink[] = [
  { href: "/dashboard", label: "Dashboard", icon: "chart", page: "dashboard" },
  { href: "/documentation/tuikit", label: "Docs", icon: "book" },
  { href: "https://github.com/phranck/TUIkit", label: "GitHub", icon: "code", external: true },
];

/**
 * Navigation bar content (requires ThemeProvider wrapper).
 */
function SiteNavContent({ activePage }: SiteNavProps) {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <nav aria-label="Main navigation" className="fixed top-0 z-50 w-full border-b border-border/50 bg-background/80 backdrop-blur-xl">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3 sm:px-6 sm:py-4">
        {/* Logo + brand */}
        <div className="flex items-center gap-2 sm:gap-3">
          <img
            src="/tuikit-logo.png"
            alt="TUIkit Logo"
            width={28}
            height={28}
            className="rounded-lg sm:h-8 sm:w-8"
          />
          {activePage === "home" ? (
            <span className="text-xl font-semibold text-foreground sm:text-2xl">TUIkit</span>
          ) : (
            <a href="/" className="text-xl font-semibold text-foreground transition-colors hover:text-accent sm:text-2xl">
              TUIkit
            </a>
          )}
        </div>

        {/* Desktop nav links */}
        <div className="hidden items-center gap-4 sm:flex sm:gap-6">
          {NAV_LINKS.map((link) => {
            const isActive = link.page === activePage;

            if (isActive) {
return (
                <span
                  key={link.href}
                  className="flex items-center gap-1.5 text-base text-foreground sm:text-lg"
                  aria-current="page"
                >
                  {link.icon && <Icon name={link.icon} size={20} className="text-current" />}
                  {link.label}
                </span>
              );
            }

            return (
              <a
                key={link.href}
                href={link.href}
                {...(link.external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                className="flex items-center gap-1.5 text-base text-muted transition-colors hover:text-foreground sm:text-lg"
              >
                {link.icon && <Icon name={link.icon} size={20} className="text-current" />}
                {link.label}
              </a>
            );
          })}
          <div className="ml-2 border-l border-border pl-4">
            <ThemeSwitcher />
          </div>
        </div>

        {/* Mobile: theme switcher + hamburger */}
        <div className="flex items-center gap-3 sm:hidden">
          <ThemeSwitcher />
          <button
            type="button"
            onClick={() => setMenuOpen(!menuOpen)}
            className="flex h-9 w-9 items-center justify-center rounded-lg text-muted transition-colors hover:bg-accent/10 hover:text-foreground"
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            aria-expanded={menuOpen}
          >
            <Icon name={menuOpen ? "xmark" : "line3Horizontal"} size={20} />
          </button>
        </div>
      </div>

      {/* Mobile menu dropdown */}
      {menuOpen && (
        <div className="border-t border-border/50 bg-background/95 px-4 py-4 backdrop-blur-xl sm:hidden">
          <div className="flex flex-col gap-3">
            {NAV_LINKS.map((link) => {
              const isActive = link.page === activePage;

              if (isActive) {
                return (
                  <span
                    key={link.href}
                    className="flex items-center gap-2 rounded-lg bg-accent/10 px-3 py-2 text-base text-foreground"
                    aria-current="page"
                  >
                    {link.icon && <Icon name={link.icon} size={20} className="text-accent" />}
                    {link.label}
                  </span>
                );
              }

              return (
                <a
                  key={link.href}
                  href={link.href}
                  {...(link.external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                  onClick={() => setMenuOpen(false)}
                  className="flex items-center gap-2 rounded-lg px-3 py-2 text-base text-muted transition-colors hover:bg-accent/5 hover:text-foreground"
                >
                  {link.icon && <Icon name={link.icon} size={20} className="text-current" />}
                  {link.label}
                </a>
              );
            })}
          </div>
        </div>
      )}
    </nav>
  );
}

/**
 * Shared site navigation bar used by all pages.
 *
 * Renders the TUIkit logo as a home link, navigation items with optional
 * active state, and the theme switcher. Fixed at the top with backdrop blur.
 * On mobile, shows a hamburger menu that expands to show links.
 *
 * Wraps content in ThemeProvider for theme switching.
 */
export default function SiteNav({ activePage }: SiteNavProps) {
  return (
    <ThemeProvider>
      <SiteNavContent activePage={activePage} />
    </ThemeProvider>
  );
}
