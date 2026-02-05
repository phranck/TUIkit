import type { ReactNode } from "react";
import type { IconName } from "./components/Icon";
import IconBadge from "./components/IconBadge";
import CloudBackground from "./components/CloudBackground";
import RainOverlay from "./components/RainOverlay";
import SpinnerLights from "./components/SpinnerLights";
import CodePreview from "./components/CodePreview";
import FeatureCard from "./components/FeatureCard";
import HeroTerminal from "./components/HeroTerminal";
import Icon from "./components/Icon";
import PackageBadge from "./components/PackageBadge";
import SiteNav from "./components/SiteNav";
import SiteFooter from "./components/SiteFooter";

/** Shared button class strings to avoid duplication across Hero and CTA sections. */
const BTN_PRIMARY =
  "inline-flex items-center justify-center gap-2 rounded-full bg-accent px-7 py-2.5 text-xl font-semibold text-background transition-all hover:bg-accent-secondary hover:shadow-lg hover:shadow-accent/20";
const BTN_SECONDARY =
  "inline-flex items-center justify-center gap-2 rounded-full border border-border px-7 py-2.5 text-xl font-semibold text-foreground transition-all hover:border-accent/40 hover:bg-white/5";

/** Test and suite counts injected at build-time by the prebuild script. */
const TEST_COUNT = process.env.TUIKIT_TEST_COUNT ?? "0";

/** A single "Built right" highlight row with icon, title, and description. */
function ArchHighlight({ icon, title, children }: { icon: IconName; title: string; children: ReactNode }) {
  return (
    <div className="flex gap-4">
      <IconBadge name={icon} size={24} variant="sm" className="!bg-accent/10" />
      <div>
        <h3 className="mb-1 text-xl font-semibold text-foreground">{title}</h3>
        <p className="text-xl leading-relaxed text-muted">{children}</p>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <div className="relative min-h-screen">
      <CloudBackground />
      <RainOverlay />
      <SpinnerLights />

      {/* Skip navigation for keyboard/screen reader users */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[9999] focus:rounded-lg focus:bg-background focus:px-4 focus:py-2 focus:text-foreground focus:ring-2 focus:ring-accent"
      >
        Skip to main content
      </a>

      {/* All page content above atmosphere layers */}
      <div className="relative z-10">
        <SiteNav activePage="home" />

        {/* Main content */}
        <main id="main-content" tabIndex={-1}>
          {/* Hero Section */}
          <section className="relative mx-auto flex max-w-6xl flex-col items-center px-6 pt-40 pb-24 text-center">
            <div className="mb-10">
              <HeroTerminal />
            </div>

            <h1
              className="mb-6 max-w-4xl text-5xl leading-tight tracking-wide transition-all duration-500 md:text-7xl"
              style={{
                fontFamily: "WarText, monospace",
                color: "var(--headline-color)",
                textShadow:
                  "0 0 7px rgba(var(--headline-glow),0.6), 0 0 20px rgba(var(--headline-glow),0.35), 0 0 42px rgba(var(--headline-glow),0.15)",
              }}
            >
              &gt; Terminal UIs, the Swift way<span className="animate-cursor-blink">_</span>
            </h1>

            <p className="mb-10 max-w-2xl text-2xl leading-relaxed text-muted">
              A declarative, SwiftUI-like framework for building Terminal User
              Interfaces. No ncurses, no C dependencies — pure Swift on macOS and
              Linux.
            </p>

            <div className="flex flex-col gap-4 sm:flex-row">
              <a href="/documentation/tuikit" className={BTN_PRIMARY}>
                <Icon name="document" size={22} />
                Read the Docs
              </a>
              <a
                href="https://github.com/phranck/TUIkit"
                target="_blank"
                rel="noopener noreferrer"
                className={BTN_SECONDARY}
              >
                View on GitHub
              </a>
            </div>

            {/* Swift Package badge — hidden on mobile */}
            <div className="hidden sm:block">
              <p className="mt-20 mb-4 max-w-2xl text-xl leading-relaxed text-muted">
                Getting started is simple. Add TUIkit as a dependency to your
                Swift package — no extra configuration, no system libraries to install:
              </p>
              <PackageBadge />
            </div>
          </section>

          {/* Code Preview Section — hidden on mobile */}
          <section className="mx-auto hidden max-w-3xl px-6 pb-28 sm:block">
            <CodePreview />
          </section>

          {/* Features Grid */}
          <section className="mx-auto max-w-6xl px-6 pb-28">
            <div className="mb-12 text-center">
              <h2 className="mb-4 text-4xl font-bold text-foreground">
                Everything you need
              </h2>
              <p className="mx-auto max-w-2xl text-2xl text-muted">
                Built from the ground up for the terminal, with APIs you already
                know from SwiftUI.
              </p>
            </div>

            <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
              <FeatureCard
                icon="terminal"
                title="Declarative Syntax"
                description="Build UIs with VStack, HStack, Text, Button, and more — the same patterns you know from SwiftUI."
              />
              <FeatureCard
                icon="paintbrush"
                title="Theming System"
                description="Multiple built-in phosphor themes with full RGB color support. Cycle at runtime or create custom palettes."
              />
              <FeatureCard
                icon="keyboard"
                title="Keyboard-Driven"
                description="Focus management, key event handlers, customizable status bar with shortcut display."
              />
              <FeatureCard
                icon="stack"
                title="Rich Components"
                description="Panel, Card, Dialog, Alert, Menu, Button, ForEach — container and interactive views out of the box."
              />
              <FeatureCard
                icon="bolt"
                title="Zero Dependencies"
                description="Pure Swift. No ncurses, no C libraries. Just add the Swift package and go."
              />
              <FeatureCard
                icon="arrows"
                title="Cross-Platform"
                description="Runs on macOS and Linux. Same code, same API, same results."
              />
            </div>
          </section>

          {/* Architecture highlights */}
          <section className="mx-auto max-w-6xl px-6 pb-28">
            <div className="rounded-2xl border border-border bg-frosted-glass p-8 backdrop-blur-xl md:p-12">
              <h2 className="mb-8 text-center text-4xl font-bold text-foreground">
                Built right
              </h2>
              <div className="grid gap-8 md:grid-cols-2">
                <ArchHighlight icon="swift" title="Swift 6.0 + Strict Concurrency">
                  Full Sendable compliance. No data races, no unsafe globals.
                  Modern Swift from top to bottom.
                </ArchHighlight>
                <ArchHighlight icon="eye" title="5 Border Appearances">
                  Line, rounded, double-line, heavy, and block style. Cycle with
                  a single keystroke.
                </ArchHighlight>
                <ArchHighlight icon="checkmark" title={`${TEST_COUNT} Tests`}>
                  Comprehensive test suite covering views, modifiers, rendering,
                  state management, and more.
                </ArchHighlight>
                <ArchHighlight icon="document" title="13 DocC Articles">
                  Architecture guides, API references, theming, focus system,
                  keyboard shortcuts, and palette documentation.
                </ArchHighlight>
              </div>
            </div>
          </section>

          {/* CTA Section */}
          <section className="mx-auto max-w-6xl px-6 pb-20">
            <div className="text-center">
              <h2 className="mb-4 text-4xl font-bold text-foreground">
                Ready to build?
              </h2>
              <p className="mb-8 text-2xl text-muted">
                Get started with TUIkit in minutes. Add the package, write your
                first view, run it.
              </p>
              <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
                <a href="/documentation/tuikit/gettingstarted" className={BTN_PRIMARY}>
                  Getting Started Guide
                </a>
                <a href="/documentation/tuikit" className={BTN_SECONDARY}>
                  Browse Documentation
                </a>
              </div>
            </div>
          </section>
        </main>

        <SiteFooter />
      </div>
    </div>
  );
}
