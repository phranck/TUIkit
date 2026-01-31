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
} from "sf-symbols-lib/hierarchical";

/** Maps of icon names to SF Symbol constants for type-safe usage. */
const icons = {
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
} as const;

export type IconName = keyof typeof icons;

interface IconProps {
  name: IconName;
  size?: number;
  className?: string;
}

/** Wrapper around SFSymbol that works in both server and client contexts. */
export default function Icon({ name, size = 20, className }: IconProps) {
  return <SFSymbol name={icons[name]} size={size} className={className} />;
}
