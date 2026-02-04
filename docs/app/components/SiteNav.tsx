"use client";

import Image from "next/image";
import Link from "next/link";
import Icon from "./Icon";
import ThemeSwitcher from "./ThemeSwitcher";

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
  { href: "/documentation/tuikit", label: "Documentation", icon: "book" },
  { href: "https://github.com/phranck/TUIkit", label: "GitHub", icon: "code", external: true },
];

/**
 * Shared site navigation bar used by all pages.
 *
 * Renders the TUIkit logo as a home link, navigation items with optional
 * active state, and the theme switcher. Fixed at the top with backdrop blur.
 */
export default function SiteNav({ activePage }: SiteNavProps) {
  return (
    <nav aria-label="Main navigation" className="fixed top-0 z-50 w-full border-b border-border/50 bg-background/80 backdrop-blur-xl">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <div className="flex items-center gap-3">
          <Image
            src="/tuikit-logo.png"
            alt="TUIkit Logo"
            width={32}
            height={32}
            className="rounded-lg"
          />
          {activePage === "home" ? (
            <span className="text-2xl font-semibold text-foreground">TUIkit</span>
          ) : (
            <Link href="/" className="text-2xl font-semibold text-foreground transition-colors hover:text-accent">
              TUIkit
            </Link>
          )}
        </div>
        <div className="flex items-center gap-6">
          {NAV_LINKS.map((link) => {
            const isActive = link.page === activePage;

            if (isActive) {
              return (
                <span
                  key={link.href}
                  className="flex items-center gap-1.5 text-lg text-foreground"
                  aria-current="page"
                >
                  {link.icon && <Icon name={link.icon} size={18} className="text-current" />}
                  {link.label}
                </span>
              );
            }

            return (
              <a
                key={link.href}
                href={link.href}
                {...(link.external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                className="flex items-center gap-1.5 text-lg text-muted transition-colors hover:text-foreground"
              >
                {link.icon && <Icon name={link.icon} size={18} className="text-current" />}
                {link.label}
              </a>
            );
          })}
          <div className="ml-2 border-l border-border pl-4">
            <ThemeSwitcher />
          </div>
        </div>
      </div>
    </nav>
  );
}
