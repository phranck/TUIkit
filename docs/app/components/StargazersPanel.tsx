"use client";

import { useRef, useEffect } from "react";
import type { Stargazer } from "../hooks/useGitHubStats";
import { useHoverPopover } from "../hooks/useHoverPopover";
import HoverPopover from "./HoverPopover";
import Icon from "./Icon";

interface StargazersPanelProps {
  /** List of users who starred the repository. */
  stargazers: Stargazer[];
  /** Total number of stars (may exceed stargazers.length due to API pagination). */
  totalStars: number;
  /** Controls the expand/collapse animation. */
  open: boolean;
}

/** Number of avatars that receive high fetch priority. */
const EAGER_AVATAR_COUNT = 10;

/**
 * Expandable panel showing stargazer avatars in a wrapping grid.
 *
 * Animates height from 0 to auto via a measured ref. Designed to sit
 * between the two StatCard rows on the dashboard page.
 * Username is shown in a popover on hover, same pattern as the heatmap.
 */
export default function StargazersPanel({ stargazers, totalStars, open }: StargazersPanelProps) {
  const contentRef = useRef<HTMLDivElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const gridRef = useRef<HTMLDivElement>(null);
  const { hover, popover, show: showPopover, hide: hidePopover, cancelHide } = useHoverPopover<Stargazer>();

  useEffect(() => {
    const wrapper = wrapperRef.current;
    const content = contentRef.current;
    if (!wrapper || !content) return;

    if (open) {
      const height = content.scrollHeight;
      wrapper.style.height = `${height}px`;
      const onEnd = () => { wrapper.style.height = "auto"; };
      wrapper.addEventListener("transitionend", onEnd, { once: true });
      return () => wrapper.removeEventListener("transitionend", onEnd);
    } else {
      // Collapse: set explicit height first so transition works
      wrapper.style.height = `${content.scrollHeight}px`;
      // Force reflow, then set to 0
      requestAnimationFrame(() => {
        wrapper.style.height = "0px";
      });
    }
  }, [open]);

  function handleMouseEnter(event: React.MouseEvent<HTMLAnchorElement>, user: Stargazer) {
    const target = event.currentTarget;
    const grid = gridRef.current;
    if (!grid) return;

    const gridRect = grid.getBoundingClientRect();
    const targetRect = target.getBoundingClientRect();

    showPopover(
      user,
      targetRect.left - gridRect.left + targetRect.width / 2,
      targetRect.top - gridRect.top,
    );
  }

  return (
    <div
      ref={wrapperRef}
      className="transition-[height,opacity] duration-300 ease-in-out"
      style={{ height: 0, opacity: open ? 1 : 0, overflow: open ? "visible" : "hidden" }}
    >
      <div ref={contentRef} className="rounded-xl border border-border bg-frosted-glass p-6 backdrop-blur-xl">
        <h3 className="mb-4 flex items-center gap-2 text-lg font-semibold text-foreground">
          <Icon name="star" size={20} className="text-accent" />
          Stargazers
          <span className="text-sm font-normal text-muted">({totalStars})</span>
        </h3>

        {stargazers.length === 0 ? (
          <p className="text-base text-muted">No stargazers yet.</p>
        ) : (
          <div ref={gridRef} className="relative">
            <div
              className="grid justify-center gap-4"
              style={{ gridTemplateColumns: "repeat(auto-fill, minmax(130px, 130px))" }}
            >
              {stargazers.map((user, index) => (
                <a
                  key={user.login}
                  href={user.profileUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group flex aspect-square items-center justify-center rounded-2xl p-4 transition-all duration-200 ease-out hover:bg-accent/10"
                  onMouseEnter={(event) => handleMouseEnter(event, user)}
                  onMouseLeave={hidePopover}
                >
                  <img
                    src={`${user.avatarUrl}&s=192`}
                    alt={user.login}
                    width={100}
                    height={100}
                    className="avatar-tinted rounded-full ring-1 ring-border transition-all duration-200 ease-out group-hover:ring-2 group-hover:ring-accent/60 group-hover:scale-110 group-hover:-translate-y-1"
                    loading={index < EAGER_AVATAR_COUNT ? "eager" : "lazy"}
                    fetchPriority={index < EAGER_AVATAR_COUNT ? "high" : "auto"}
                  />
                </a>
              ))}
            </div>

            <HoverPopover
              visible={!!hover}
              x={popover?.x ?? 0}
              y={popover?.y ?? 0}
              minWidth="140px"
              onMouseEnter={cancelHide}
              onMouseLeave={hidePopover}
            >
              <div className="flex flex-col items-center gap-1.5">
                <p className="whitespace-nowrap text-center text-sm font-medium text-foreground">
                  {popover?.data?.login}
                </p>
                {(popover?.data?.mastodon || popover?.data?.twitter || popover?.data?.bluesky) && (
                  <div className="flex flex-col items-start gap-1">
                    {popover?.data?.mastodon && (
                      <a
                        href={popover.data.mastodon.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="pointer-events-auto flex items-center gap-1.5 text-muted hover:text-accent transition-colors text-xs"
                        onClick={(e) => e.stopPropagation()}
                        title={popover.data.mastodon.handle}
                      >
                        <Icon name="mastodon" size={14} />
                        <span>Mastodon</span>
                      </a>
                    )}
                    {popover?.data?.bluesky && (
                      <a
                        href={popover.data.bluesky.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="pointer-events-auto flex items-center gap-1.5 text-muted hover:text-accent transition-colors text-xs"
                        onClick={(e) => e.stopPropagation()}
                        title={popover.data.bluesky.handle}
                      >
                        <Icon name="bluesky" size={14} />
                        <span>Bluesky</span>
                      </a>
                    )}
                    {popover?.data?.twitter && (
                      <a
                        href={popover.data.twitter.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="pointer-events-auto flex items-center gap-1.5 text-muted hover:text-accent transition-colors text-xs"
                        onClick={(e) => e.stopPropagation()}
                        title={popover.data.twitter.handle}
                      >
                        <Icon name="twitter" size={14} />
                        <span>Twitter</span>
                      </a>
                    )}
                  </div>
                )}
              </div>
            </HoverPopover>
          </div>
        )}
      </div>
    </div>
  );
}
