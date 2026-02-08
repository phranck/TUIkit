import { IconBrandSwift, IconCopy, IconCheck } from "@tabler/icons-react";
import { useCopyToClipboard } from "../../hooks/useCopyToClipboard";

const VERSION = import.meta.env.PUBLIC_TUIKIT_VERSION ?? "0.1.0";
const PACKAGE_LINE = `.package(url: "https://github.com/phranck/TUIkit.git", from: "${VERSION}")`;

/** SPM package dependency badge with copy-to-clipboard. */
export default function PackageBadge() {
  const { copied, copy } = useCopyToClipboard();

  return (
    <div className="flex w-full items-center justify-between gap-2 rounded-full border border-border bg-container-body/50 px-4 py-2 text-muted backdrop-blur-sm">

      <code className="font-mono text-lg text-glow" style={{ color: "var(--foreground)" }}>
        {PACKAGE_LINE}
      </code>
      <button
        onClick={() => copy(PACKAGE_LINE)}
        aria-label="Copy to clipboard"
        className="ml-1 rounded-md p-1.5 text-muted transition-colors hover:bg-foreground/10 hover:text-foreground focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background shrink-0"
      >
        {copied ? (
          <IconCheck size={20} className="text-accent" />
        ) : (
          <IconCopy size={20} />
        )}
      </button>
    </div>
  );
}
