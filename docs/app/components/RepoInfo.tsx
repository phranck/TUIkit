"use client";

import Icon from "./Icon";

interface RepoInfoProps {
  createdAt: string;
  license: string | null;
  size: number;
  defaultBranch: string;
  pushedAt: string;
  loading?: boolean;
}

/**
 * Formats a file size from kilobytes to a human-readable string.
 *
 * GitHub reports repo size in KB. This converts to KB, MB, or GB as appropriate.
 */
function formatSize(sizeKB: number): string {
  if (sizeKB < 1024) return `${sizeKB} KB`;
  if (sizeKB < 1048576) return `${(sizeKB / 1024).toFixed(1)} MB`;
  return `${(sizeKB / 1048576).toFixed(1)} GB`;
}

/**
 * Formats an ISO date string into a human-readable relative time.
 *
 * Produces strings like "3 hours ago" or "2 days ago".
 */
function relativeTime(isoDate: string): string {
  if (!isoDate) return "—";
  const now = Date.now();
  const then = new Date(isoDate).getTime();
  const diffSeconds = Math.floor((now - then) / 1000);

  const rtf = new Intl.RelativeTimeFormat("en", { numeric: "auto" });

  if (diffSeconds < 60) return rtf.format(-diffSeconds, "second");
  if (diffSeconds < 3600) return rtf.format(-Math.floor(diffSeconds / 60), "minute");
  if (diffSeconds < 86400) return rtf.format(-Math.floor(diffSeconds / 3600), "hour");
  if (diffSeconds < 2592000) return rtf.format(-Math.floor(diffSeconds / 86400), "day");
  if (diffSeconds < 31536000) return rtf.format(-Math.floor(diffSeconds / 2592000), "month");
  return rtf.format(-Math.floor(diffSeconds / 31536000), "year");
}

/**
 * Formats an ISO date string into a short date (e.g., "Jan 28, 2026").
 */
function formatDate(isoDate: string): string {
  if (!isoDate) return "—";
  return new Date(isoDate).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

/** A single metadata row with label and value. */
function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-border/30 py-2 last:border-0">
      <span className="text-base text-muted">{label}</span>
      <span className="text-base font-medium text-foreground">{value}</span>
    </div>
  );
}

/**
 * Displays repository metadata in a clean key-value layout.
 *
 * Shows creation date, license, size, default branch, and last push time.
 */
export default function RepoInfo({
  createdAt,
  license,
  size,
  defaultBranch,
  pushedAt,
  loading = false,
}: RepoInfoProps) {
  if (loading) {
    return (
      <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
          <Icon name="serverRack" size={22} className="text-muted" />
          Repository
        </h3>
        <div className="flex flex-col gap-2">
          {Array.from({ length: 5 }).map((_, idx) => (
            <div key={idx} className="h-5 w-full rounded-md bg-accent/10 animate-skeleton" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
      <h3 className="mb-4 flex items-center gap-2 text-xl font-semibold text-foreground">
        <Icon name="serverRack" size={22} className="text-muted" />
        Repository
      </h3>
      <div className="flex flex-col">
        <InfoRow label="Created" value={formatDate(createdAt)} />
        <InfoRow label="License" value={license ?? "None"} />
        <InfoRow label="Size" value={formatSize(size)} />
        <InfoRow label="Default Branch" value={defaultBranch || "—"} />
        <InfoRow label="Last Push" value={relativeTime(pushedAt)} />
      </div>
    </div>
  );
}
