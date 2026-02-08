import {
  IconTerminal2,
  IconBrush,
  IconKeyboardFilled,
  IconStack2Filled,
  IconBoltFilled,
  IconFileTextFilled,
  IconEyeFilled,
  IconArrowsExchange,
  IconCircleCheckFilled,
  IconBookFilled,
  IconCode,
  IconChevronRight,
  IconClockFilled,
  IconCalendarFilled,
  IconRefresh,
  IconChartBar,
  IconHash,
  IconStarFilled,
  IconGitPullRequest,
  IconGitMerge,
  IconGitBranch,
  IconTagFilled,
  IconUsers,
  IconPackage,
  IconList,
  IconServer,
  IconMessageFilled,
  IconMenu2,
  IconX,
  IconCopy,
  IconBrandSwift,
  IconBrandMastodon,
  IconBrandX,
  IconBrandBluesky,
  IconBrandGithubFilled,
} from "@tabler/icons-react";
import type { Icon as TablerIcon } from "@tabler/icons-react";
import { siXcode } from "simple-icons";

/** Map icon names to Tabler Icons components (filled where available). */
const tablerIcons: Record<string, TablerIcon> = {
  terminal: IconTerminal2,
  paintbrush: IconBrush,
  keyboard: IconKeyboardFilled,
  stack: IconStack2Filled,
  bolt: IconBoltFilled,
  document: IconFileTextFilled,
  eye: IconEyeFilled,
  arrows: IconArrowsExchange,
  checkmark: IconCircleCheckFilled,
  book: IconBookFilled,
  code: IconCode,
  chevronRight: IconChevronRight,
  clock: IconClockFilled,
  calendar: IconCalendarFilled,
  refresh: IconRefresh,
  chart: IconChartBar,
  numberCircle: IconHash,
  star: IconStarFilled,
  pullRequest: IconGitPullRequest,
  merge: IconGitMerge,
  branch: IconGitBranch,
  tag: IconTagFilled,
  person2: IconUsers,
  shippingbox: IconPackage,
  listBullet: IconList,
  serverRack: IconServer,
  issue: IconMessageFilled,
  line3Horizontal: IconMenu2,
  xmark: IconX,
  copy: IconCopy,
  swift: IconBrandSwift,
  mastodon: IconBrandMastodon,
  twitter: IconBrandX,
  bluesky: IconBrandBluesky,
  github: IconBrandGithubFilled,
} as const;

/** Simple Icons for brand logos not in Tabler. */
const simpleIcons = {
  xcode: siXcode,
} as const;

export type IconName = keyof typeof tablerIcons | keyof typeof simpleIcons;

interface IconProps {
  name: IconName;
  size?: number;
  className?: string;
}

/** Decorative icon wrapper: hidden from screen readers since adjacent text conveys meaning. */
export default function Icon({ name, size = 24, className }: IconProps) {
  // Check Simple Icons first
  if (name in simpleIcons) {
    const icon = simpleIcons[name as keyof typeof simpleIcons];
    return (
      <span aria-hidden="true" className={className}>
        <svg
          role="img"
          viewBox="0 0 24 24"
          width={size}
          height={size}
          fill="currentColor"
        >
          <path d={icon.path} />
        </svg>
      </span>
    );
  }

  // Fall back to Tabler Icons
  const TablerIconComponent = tablerIcons[name];

  if (!TablerIconComponent) {
    console.warn(`Icon "${name}" not found`);
    return null;
  }

  return (
    <span aria-hidden="true" className={className}>
      <TablerIconComponent size={size} stroke={1.5} />
    </span>
  );
}
