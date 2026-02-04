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
