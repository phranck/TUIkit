

import { useCallback } from "react";
import type { Stargazer } from "../../../hooks/useGitHubStats";
import AvatarMarquee from "./AvatarMarquee";
import StargazerPopoverContent from "./StargazerPopoverContent";

interface StargazersPanelProps {
  /** List of users who starred the repository. */
  stargazers: Stargazer[];
  /** Total number of stars (may exceed stargazers.length due to API pagination). */
  totalStars: number;
  /** Controls the expand/collapse animation. */
  open: boolean;
  /** Callback when panel requests to close. */
  onClose?: () => void;
}

/**
 * Horizontally scrolling marquee of stargazer avatars.
 *
 * Displays between the two StatCard rows when the Stars card is clicked.
 * Uses the generic AvatarMarquee component with stargazer-specific popover content.
 */
export default function StargazersPanel({ stargazers, open, onClose }: StargazersPanelProps) {
  const getAvatarUrl = useCallback((s: Stargazer) => s.avatarUrl, []);
  const getLabel = useCallback((s: Stargazer) => s.login, []);
  const getProfileUrl = useCallback((s: Stargazer) => s.profileUrl, []);
  const renderPopover = useCallback((s: Stargazer) => <StargazerPopoverContent user={s} />, []);

  return (
    <AvatarMarquee
      items={stargazers}
      getAvatarUrl={getAvatarUrl}
      getLabel={getLabel}
      getProfileUrl={getProfileUrl}
      renderPopover={renderPopover}
      open={open}
      title="Stargazers"
      onClose={onClose}
    />
  );
}
