"use client";

import Icon from "./Icon";
import { useCopyToClipboard } from "../hooks/useCopyToClipboard";

const VERSION = process.env.TUIKIT_VERSION ?? "0.1.0";
const PACKAGE_LINE = `.package(url: "https://github.com/phranck/TUIkit.git", from: "${VERSION}")`;

/** SPM package dependency badge with copy-to-clipboard. */
export default function PackageBadge() {
  const { copied, copy } = useCopyToClipboard();

  return (
    <div className="inline-flex items-center gap-3 rounded-full border border-border bg-container-body/50 px-6 py-3 text-muted backdrop-blur-sm">
      <Icon name="swift" size={20} className="text-accent" />
      <code
        className="font-mono text-xl"
        style={{
          color: "var(--foreground)",
          textShadow:
            "0 0 4px rgba(var(--accent-glow), 0.5), 0 0 12px rgba(var(--accent-glow), 0.2)",
        }}
      >
        {PACKAGE_LINE}
      </code>
      <button
        onClick={() => copy(PACKAGE_LINE)}
        aria-label="Copy to clipboard"
        className="ml-1 rounded-md p-1.5 text-muted transition-colors hover:bg-foreground/10 hover:text-foreground focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background"
      >
        {copied ? (
          <Icon name="checkmark" size={18} className="text-accent" />
        ) : (
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
          </svg>
        )}
      </button>
    </div>
  );
}
