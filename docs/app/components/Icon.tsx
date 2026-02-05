"use client";

import {
  SFSymbol,
  SFAppleTerminalFill,
  SFPaintbrushFill,
  SFKeyboardFill,
  SFSquareStack3dUpFill,
  SFBoltFill,
  SFDocumentFill,
  SFEyeFill,
  SFArrowLeftArrowRight,
  SFSwift,
  SFCheckmarkCircleFill,
  SFBookFill,
  SFChevronLeftForwardslashChevronRight,
  SFChevronRight,
  SFClockFill,
  SFCalendar,
  SFArrowClockwise,
  SFChartBarFill,
  SFNumberCircleFill,
  SFStarFill,
  SFArrowTriangleheadPull,
  SFArrowTriangleheadMerge,
  SFArrowTriangleheadBranch,
  SFTagFill,
  SFPerson2Fill,
  SFShippingboxFill,
  SFListBullet,
  SFServerRack,
  SFBubbleLeftAndExclamationmarkBubbleRightFill,
} from "sf-symbols-lib/hierarchical";

/** Maps of icon names to SF Symbol constants for type-safe usage. */
const sfIcons = {
  terminal: SFAppleTerminalFill,
  paintbrush: SFPaintbrushFill,
  keyboard: SFKeyboardFill,
  stack: SFSquareStack3dUpFill,
  bolt: SFBoltFill,
  document: SFDocumentFill,
  eye: SFEyeFill,
  arrows: SFArrowLeftArrowRight,
  swift: SFSwift,
  checkmark: SFCheckmarkCircleFill,
  book: SFBookFill,
  code: SFChevronLeftForwardslashChevronRight,
  chevronRight: SFChevronRight,
  clock: SFClockFill,
  calendar: SFCalendar,
  refresh: SFArrowClockwise,
  chart: SFChartBarFill,
  numberCircle: SFNumberCircleFill,
  star: SFStarFill,
  pullRequest: SFArrowTriangleheadPull,
  merge: SFArrowTriangleheadMerge,
  branch: SFArrowTriangleheadBranch,
  tag: SFTagFill,
  person2: SFPerson2Fill,
  shippingbox: SFShippingboxFill,
  listBullet: SFListBullet,
  serverRack: SFServerRack,
  issue: SFBubbleLeftAndExclamationmarkBubbleRightFill,
} as const;

/** Custom SVG icons not available in SF Symbols. */
const customIcons = {
  /** Two overlapping rectangles — standard copy-to-clipboard metaphor. */
  copy: (size: number) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
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
  ),
  /** Mastodon logo. */
  mastodon: (size: number) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
    >
      <path d="M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.053.053 0 0 1 .066-.054c1.517.363 3.072.546 4.632.546.376 0 .75 0 1.125-.01 1.57-.044 3.224-.124 4.768-.422.038-.008.077-.015.11-.024 2.435-.464 4.753-1.92 4.989-5.604.008-.145.03-1.52.03-1.67.002-.512.167-3.63-.024-5.545zm-3.748 9.195h-2.561V8.29c0-1.309-.55-1.976-1.67-1.976-1.23 0-1.846.79-1.846 2.35v3.403h-2.546V8.663c0-1.56-.617-2.35-1.848-2.35-1.112 0-1.668.668-1.668 1.977v6.218H4.822V8.102c0-1.31.337-2.35 1.011-3.12.696-.77 1.608-1.164 2.74-1.164 1.311 0 2.302.5 2.962 1.498l.638 1.06.638-1.06c.66-.999 1.65-1.498 2.96-1.498 1.13 0 2.043.395 2.74 1.164.675.77 1.012 1.81 1.012 3.12z" />
    </svg>
  ),
  /** Twitter/X logo. */
  twitter: (size: number) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
    >
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
  ),
  /** Bluesky logo. */
  bluesky: (size: number) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
    >
      <path d="M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479.815 2.736 3.713 3.66 6.383 3.364.136-.02.275-.039.415-.056-.138.022-.276.04-.415.056-3.912.58-7.387 2.005-2.83 7.078 5.013 5.19 6.87-1.113 7.823-4.308.953 3.195 2.05 9.271 7.733 4.308 4.267-4.308 1.172-6.498-2.74-7.078a8.741 8.741 0 0 1-.415-.056c.14.017.279.036.415.056 2.67.297 5.568-.628 6.383-3.364.246-.828.624-5.79.624-6.478 0-.69-.139-1.861-.902-2.206-.659-.298-1.664-.62-4.3 1.24C16.046 4.748 13.087 8.687 12 10.8z" />
    </svg>
  ),
} as const;

export type IconName = keyof typeof sfIcons | keyof typeof customIcons;

interface IconProps {
  name: IconName;
  size?: number;
  className?: string;
}

/** Decorative icon wrapper — hidden from screen readers since adjacent text conveys meaning. */
export default function Icon({ name, size = 20, className }: IconProps) {
  if (name in customIcons) {
    return (
      <span aria-hidden="true" className={className}>
        {customIcons[name as keyof typeof customIcons](size)}
      </span>
    );
  }
  return (
    <span aria-hidden="true">
      <SFSymbol name={sfIcons[name as keyof typeof sfIcons]} size={size} className={className} />
    </span>
  );
}
