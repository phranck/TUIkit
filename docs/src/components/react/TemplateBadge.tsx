import Icon from "./Icon";
import { useCopyToClipboard } from "../../hooks/useCopyToClipboard";

const INSTALL_COMMAND = 'curl -fsSL https://raw.githubusercontent.com/phranck/TUIkit/main/project-template/install.sh | bash';

/** CLI installer badge with copy-to-clipboard. */
export default function TemplateBadge() {
  const { copied, copy } = useCopyToClipboard();

  return (
    <div className="flex w-full items-center justify-between gap-2 rounded-full border border-border bg-container-body/50 px-4 py-2 text-muted backdrop-blur-sm">

      <code className="font-mono text-base text-glow" style={{ color: "var(--foreground)" }}>
        {INSTALL_COMMAND}
      </code>
      <button
        onClick={() => copy(INSTALL_COMMAND)}
        aria-label="Copy to clipboard"
        className="ml-1 rounded-md p-1.5 text-muted transition-colors hover:bg-foreground/10 hover:text-foreground focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background shrink-0"
      >
        {copied ? (
          <Icon name="checkmark" size={20} className="text-accent" />
        ) : (
          <Icon name="copy" size={20} />
        )}
      </button>
    </div>
  );
}
