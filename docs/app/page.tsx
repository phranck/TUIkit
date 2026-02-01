import Image from "next/image";
import CloudBackground from "./components/CloudBackground";
import RainOverlay from "./components/RainOverlay";
import SpinnerLights from "./components/SpinnerLights";
import CodePreview from "./components/CodePreview";
import FeatureCard from "./components/FeatureCard";
import HeroTerminal from "./components/HeroTerminal";
import Icon from "./components/Icon";
import PackageBadge from "./components/PackageBadge";
import ThemeSwitcher from "./components/ThemeSwitcher";

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
      {/* Navigation */}
      <nav className="fixed top-0 z-50 w-full border-b border-border/50 bg-background/80 backdrop-blur-xl">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <Image
              src="/tuikit-logo.png"
              alt="TUIkit Logo"
              width={32}
              height={32}
              className="rounded-lg"
            />
            <span className="text-2xl font-semibold text-foreground">
              TUIkit
            </span>
          </div>
          <div className="flex items-center gap-6">
            <a
              href="/documentation/tuikit"
              className="text-lg text-muted transition-colors hover:text-foreground"
            >
              Documentation
            </a>
            <a
              href="https://github.com/phranck/TUIkit"
              target="_blank"
              rel="noopener noreferrer"
              className="text-lg text-muted transition-colors hover:text-foreground"
            >
              GitHub
            </a>
            <div className="ml-2 border-l border-border pl-4">
              <ThemeSwitcher />
            </div>
          </div>
        </div>
      </nav>

      {/* Main content */}
      <main id="main-content">
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
          <a
            href="/documentation/tuikit"
            className="inline-flex items-center justify-center gap-2 rounded-full bg-accent px-7 py-2.5 text-xl font-semibold text-background transition-all hover:bg-accent-secondary hover:shadow-lg hover:shadow-accent/20"
          >
            <Icon name="document" size={22} />
            Read the Docs
          </a>
          <a
            href="https://github.com/phranck/TUIkit"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-full border border-border px-7 py-2.5 text-xl font-semibold text-foreground transition-all hover:border-accent/40 hover:bg-white/5"
          >
            View on GitHub
          </a>
        </div>

        {/* Swift Package badge */}
        <p className="mt-20 mb-4 max-w-2xl text-xl leading-relaxed text-muted">
          Getting started is simple. Add TUIkit as a dependency to your
          Swift package — no extra configuration, no system libraries to install:
        </p>
        <PackageBadge />
      </section>

      {/* Code Preview Section */}
      <section className="mx-auto max-w-3xl px-6 pb-28">
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
            icon={<Icon name="terminal" size={28} />}
            title="Declarative Syntax"
            description="Build UIs with VStack, HStack, Text, Button, and more — the same patterns you know from SwiftUI."
          />
          <FeatureCard
            icon={<Icon name="paintbrush" size={28} />}
            title="Theming System"
            description="Multiple built-in phosphor themes with full RGB color support. Cycle at runtime or create custom palettes."
          />
          <FeatureCard
            icon={<Icon name="keyboard" size={28} />}
            title="Keyboard-Driven"
            description="Focus management, key event handlers, customizable status bar with shortcut display."
          />
          <FeatureCard
            icon={<Icon name="stack" size={28} />}
            title="Rich Components"
            description="Panel, Card, Dialog, Alert, Menu, Button, ForEach — container and interactive views out of the box."
          />
          <FeatureCard
            icon={<Icon name="bolt" size={28} />}
            title="Zero Dependencies"
            description="Pure Swift. No ncurses, no C libraries. Just add the Swift package and go."
          />
          <FeatureCard
            icon={<Icon name="arrows" size={28} />}
            title="Cross-Platform"
            description="Runs on macOS and Linux. Same code, same API, same results."
          />
        </div>
      </section>

      {/* Architecture highlights */}
      <section className="mx-auto max-w-6xl px-6 pb-28">
        <div
          className="rounded-2xl border border-border p-8 backdrop-blur-xl md:p-12"
          style={{ backgroundColor: "color-mix(in srgb, var(--container-body) 50%, transparent)" }}
        >
          <h2 className="mb-8 text-center text-4xl font-bold text-foreground">
            Built right
          </h2>
          <div className="grid gap-8 md:grid-cols-2">
            <div className="flex gap-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent">
                <Icon name="swift" size={24} />
              </div>
              <div>
                <h3 className="mb-1 text-xl font-semibold text-foreground">
                  Swift 6.0 + Strict Concurrency
                </h3>
                <p className="text-xl leading-relaxed text-muted">
                  Full Sendable compliance. No data races, no unsafe globals.
                  Modern Swift from top to bottom.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent">
                <Icon name="eye" size={24} />
              </div>
              <div>
                <h3 className="mb-1 text-xl font-semibold text-foreground">
                  5 Border Appearances
                </h3>
                <p className="text-xl leading-relaxed text-muted">
                  Line, rounded, double-line, heavy, and block style. Cycle with
                  a single keystroke.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent">
                <Icon name="checkmark" size={24} />
              </div>
              <div>
                <h3 className="mb-1 text-xl font-semibold text-foreground">
                  498 Tests
                </h3>
                <p className="text-xl leading-relaxed text-muted">
                  Comprehensive test suite covering views, modifiers, rendering,
                  state management, and more.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-accent/10 text-accent">
                <Icon name="document" size={24} />
              </div>
              <div>
                <h3 className="mb-1 text-xl font-semibold text-foreground">
                  13 DocC Articles
                </h3>
                <p className="text-xl leading-relaxed text-muted">
                  Architecture guides, API references, theming, focus system,
                  keyboard shortcuts, and palette documentation.
                </p>
              </div>
            </div>
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
            <a
              href="/documentation/tuikit/gettingstarted"
              className="inline-flex items-center justify-center gap-2 rounded-full bg-accent px-7 py-2.5 text-xl font-semibold text-background transition-all hover:bg-accent-secondary hover:shadow-lg hover:shadow-accent/20"
            >
              Getting Started Guide
            </a>
            <a
              href="/documentation/tuikit"
              className="inline-flex items-center justify-center gap-2 rounded-full border border-border px-7 py-2.5 text-xl font-semibold text-foreground transition-all hover:border-accent/40 hover:bg-white/5"
            >
              Browse Documentation
            </a>
          </div>
        </div>
      </section>

      </main>

      {/* Footer */}
      <footer className="border-t border-border bg-container-body/30 backdrop-blur-sm">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-0.5 px-6 py-8 text-center">
          <span className="text-base text-muted">
            Made with ❤️ in Bregenz
          </span>
          <span className="text-base text-muted">
            at Lake Constance
          </span>
          <span className="text-base text-muted">
            Austria
          </span>
          <a
            href="https://creativecommons.org/licenses/by-nc-sa/4.0/"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-6 text-xs text-muted/70 transition-colors hover:text-foreground"
          >
            CC BY-NC-SA 4.0
          </a>
        </div>
      </footer>
      </div>
    </div>
  );
}
