import {
  CommandLineIcon,
  PaintBrushIcon,
  ComputerDesktopIcon,
  Square3Stack3DIcon,
  BoltIcon,
  DocumentTextIcon,
  EyeIcon,
  ArrowsRightLeftIcon,
  CheckCircleIcon,
  BookOpenIcon,
  CodeBracketIcon,
  ChevronRightIcon,
  ClockIcon,
  CalendarIcon,
  ArrowPathIcon,
  ChartBarIcon,
  HashtagIcon,
  StarIcon,
  ArrowUpOnSquareIcon,
  ArrowsPointingInIcon,
  ShareIcon,
  TagIcon,
  UsersIcon,
  CubeIcon,
  ListBulletIcon,
  ServerIcon,
  ChatBubbleLeftRightIcon,
  Bars3Icon,
  XMarkIcon,
  ClipboardDocumentIcon,
} from "@heroicons/react/24/solid";

/** Map icon names to Heroicons solid components. */
const heroIcons = {
  terminal: CommandLineIcon,
  paintbrush: PaintBrushIcon,
  keyboard: ComputerDesktopIcon,
  stack: Square3Stack3DIcon,
  bolt: BoltIcon,
  document: DocumentTextIcon,
  eye: EyeIcon,
  arrows: ArrowsRightLeftIcon,
  checkmark: CheckCircleIcon,
  book: BookOpenIcon,
  code: CodeBracketIcon,
  chevronRight: ChevronRightIcon,
  clock: ClockIcon,
  calendar: CalendarIcon,
  refresh: ArrowPathIcon,
  chart: ChartBarIcon,
  numberCircle: HashtagIcon,
  star: StarIcon,
  pullRequest: ArrowUpOnSquareIcon,
  merge: ArrowsPointingInIcon,
  branch: ShareIcon,
  tag: TagIcon,
  person2: UsersIcon,
  shippingbox: CubeIcon,
  listBullet: ListBulletIcon,
  serverRack: ServerIcon,
  issue: ChatBubbleLeftRightIcon,
  line3Horizontal: Bars3Icon,
  xmark: XMarkIcon,
  copy: ClipboardDocumentIcon,
} as const;

/** Custom SVG icons not available in Heroicons. */
const customIcons = {
  /** Swift logo. */
  swift: (size: number) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
    >
      <path d="M7.508 0c-.287 0-.573 0-.86.002-.241.002-.483.003-.724.01-.132.003-.263.009-.395.015A9.154 9.154 0 0 0 4.348.2 5.084 5.084 0 0 0 2.985.63 4.989 4.989 0 0 0 .63 2.984 5.15 5.15 0 0 0 .2 4.348a9.209 9.209 0 0 0-.168 1.181c-.006.132-.012.263-.015.395-.007.241-.008.483-.01.724C.002 6.935 0 7.221 0 7.508v8.984c0 .287 0 .573.002.86.002.241.003.483.01.724.003.132.009.263.015.395.021.413.07.823.168 1.181.096.361.238.7.43 1.007a4.989 4.989 0 0 0 2.354 2.354 5.15 5.15 0 0 0 1.181.428c.357.099.768.147 1.181.168.132.006.263.012.395.015.241.007.483.008.724.01.287.002.573.002.86.002h8.984c.287 0 .573 0 .86-.002.241-.002.483-.003.724-.01.132-.003.263-.009.395-.015a9.2 9.2 0 0 0 1.181-.168 5.1 5.1 0 0 0 1.181-.428 4.989 4.989 0 0 0 2.354-2.354 5.15 5.15 0 0 0 .428-1.181c.099-.357.147-.768.168-1.181.006-.132.012-.263.015-.395.007-.241.008-.483.01-.724.002-.287.002-.573.002-.86V7.508c0-.287 0-.573-.002-.86a28.35 28.35 0 0 0-.01-.724 13.52 13.52 0 0 0-.015-.395 9.21 9.21 0 0 0-.168-1.181 5.084 5.084 0 0 0-.43-1.007A4.989 4.989 0 0 0 21.016.63a5.08 5.08 0 0 0-1.007-.43 9.209 9.209 0 0 0-1.181-.168c-.132-.006-.263-.012-.395-.015a28.29 28.29 0 0 0-.724-.01C17.422 0 17.137 0 16.85 0H7.508zm5.78 3.149a.127.127 0 0 1 .18-.002l.02.022.002.002a.127.127 0 0 1 .017.14.123.123 0 0 1-.027.034c-3.648 3.281-3.32 9.152.002 11.543-.016.015-4.663-2.85-4.506-7.69.062-1.898.996-3.14 1.98-3.769a4.31 4.31 0 0 1 2.332-.28zm3.342.987c.02-.006.04-.003.057.008l.017.018c.025.028.02.06.018.079-.135.83.086 2.332.866 3.803 1.348 2.546 4.323 5.116 5.407 5.983.085.068.104.198.041.292l-.002.003c-.034.048-.086.081-.144.092-1.04.205-3.142.399-5.84-.605-.01-.004-.014-.019-.007-.028l.001-.001c.017-.02.04-.032.064-.034a7.1 7.1 0 0 0 2.63-.847.007.007 0 0 0 .001-.011c-.003-.002-.005-.003-.008-.002C15.08 11.947 9.893 8.15 7.905 4.6a.132.132 0 0 1 .037-.168l.004-.003a.132.132 0 0 1 .107-.023l.002.001a27.426 27.426 0 0 0 5.89 3.074C16.2 6.39 17.1 4.246 16.63 4.136z" />
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

export type IconName = keyof typeof heroIcons | keyof typeof customIcons;

interface IconProps {
  name: IconName;
  size?: number;
  className?: string;
}

/** Decorative icon wrapper: hidden from screen readers since adjacent text conveys meaning. */
export default function Icon({ name, size = 24, className }: IconProps) {
  if (name in customIcons) {
    return (
      <span aria-hidden="true" className={className}>
        {customIcons[name as keyof typeof customIcons](size)}
      </span>
    );
  }

  const HeroIcon = heroIcons[name as keyof typeof heroIcons];
  return (
    <span aria-hidden="true" className={className}>
      <HeroIcon width={size} height={size} />
    </span>
  );
}
