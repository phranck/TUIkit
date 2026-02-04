"use client";

import type { Stargazer } from "../hooks/useGitHubStats";
import Icon from "./Icon";

interface StargazerPopoverContentProps {
  user: Stargazer;
}

/**
 * Popover content for a stargazer, showing username and social links.
 */
export default function StargazerPopoverContent({ user }: StargazerPopoverContentProps) {
  const hasSocial = user.mastodon || user.twitter || user.bluesky;

  return (
    <div className="flex flex-col items-center gap-1.5">
      <p className="whitespace-nowrap text-center text-sm font-medium text-foreground">
        {user.login}
      </p>
      {hasSocial && (
        <div className="flex flex-col items-start gap-1">
          {user.mastodon && (
            <a
              href={user.mastodon.url}
              target="_blank"
              rel="noopener noreferrer"
              className="pointer-events-auto flex items-center gap-1.5 text-muted hover:text-accent transition-colors text-xs"
              onClick={(e) => e.stopPropagation()}
              title={user.mastodon.handle}
            >
              <Icon name="mastodon" size={14} />
              <span>Mastodon</span>
            </a>
          )}
          {user.bluesky && (
            <a
              href={user.bluesky.url}
              target="_blank"
              rel="noopener noreferrer"
              className="pointer-events-auto flex items-center gap-1.5 text-muted hover:text-accent transition-colors text-xs"
              onClick={(e) => e.stopPropagation()}
              title={user.bluesky.handle}
            >
              <Icon name="bluesky" size={14} />
              <span>Bluesky</span>
            </a>
          )}
          {user.twitter && (
            <a
              href={user.twitter.url}
              target="_blank"
              rel="noopener noreferrer"
              className="pointer-events-auto flex items-center gap-1.5 text-muted hover:text-accent transition-colors text-xs"
              onClick={(e) => e.stopPropagation()}
              title={user.twitter.handle}
            >
              <Icon name="twitter" size={14} />
              <span>Twitter</span>
            </a>
          )}
        </div>
      )}
    </div>
  );
}
