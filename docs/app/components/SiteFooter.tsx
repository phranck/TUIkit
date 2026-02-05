/**
 * Shared site footer used by all pages.
 *
 * Displays location info. Accepts optional children for page-specific
 * additions (e.g. API rate limit display).
 */
export default function SiteFooter({ children, className }: { children?: React.ReactNode; className?: string }) {
  return (
    <footer className={`border-t border-border bg-container-body/30 backdrop-blur-sm ${className ?? ""}`}>
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
        {children}
      </div>
    </footer>
  );
}
