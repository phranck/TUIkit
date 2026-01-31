"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/** A single terminal interaction: command + optional output lines. */
interface TerminalEntry {
  prompt: string;
  command: string;
  output: string[];
}

/**
 * Pool of realistic terminal interactions.
 * Each entry has a prompt, a command typed character-by-character,
 * and output lines that appear instantly after "execution".
 * ~50 entries for 3+ minutes without repeats.
 */
const INTERACTIONS: TerminalEntry[] = [
  // ── Build & Test ──────────────────────────
  {
    prompt: "~$",
    command: "swift build",
    output: ["Compiling TUIkit...", "Build complete! (0.8s)"],
  },
  {
    prompt: "~$",
    command: "swift test",
    output: ["Testing...", "492 tests in 83 suites", "All tests passed."],
  },
  {
    prompt: "~$",
    command: "swift build -c release",
    output: ["Optimizing...", "Build complete! (2.1s)"],
  },
  {
    prompt: "~$",
    command: "swift test --filter Palette",
    output: ["Running 31 tests...", "31 tests passed."],
  },
  {
    prompt: "~$",
    command: "swift package resolve",
    output: ["Fetching swift-docc...", "Resolved (0.4s)"],
  },
  // ── Git ───────────────────────────────────
  {
    prompt: "~$",
    command: "git status",
    output: ["On branch main", "nothing to commit"],
  },
  {
    prompt: "~$",
    command: "git log --oneline -4",
    output: ["90f9ebd Merge PR #48", "b89d785 Refactor", "9b422bb Merge PR #47", "4f779d0 Chore: Fix"],
  },
  {
    prompt: "~$",
    command: "git branch -a",
    output: ["* main", "  remotes/origin/main"],
  },
  {
    prompt: "~$",
    command: "git diff --stat HEAD~1",
    output: ["22 files changed", "+521 insertions", "-414 deletions"],
  },
  {
    prompt: "~$",
    command: "git tag -l 'v*'",
    output: ["v0.1.0", "v0.2.0", "v0.3.0"],
  },
  {
    prompt: "~$",
    command: "git shortlog -sn --all",
    output: ["  142  phranck"],
  },
  {
    prompt: "~$",
    command: "git stash list",
    output: ["stash@{0}: WIP on feat"],
  },
  // ── Directory Listings ────────────────────
  {
    prompt: "~$",
    command: "ls Sources/TUIkit/",
    output: ["Modifiers/  Styling/", "Views/      Focus/", "State/      TUIkit.docc/"],
  },
  {
    prompt: "~$",
    command: "ls Sources/TUIkit/Views/",
    output: ["Button.swift", "ContainerView.swift", "Menu.swift    Text.swift", "Panel.swift   Card.swift"],
  },
  {
    prompt: "~$",
    command: "ls Sources/TUIkit/Styling/",
    output: ["Color.swift   Theme.swift", "Palettes/", "SemanticColor.swift"],
  },
  {
    prompt: "~$",
    command: "ls Tests/",
    output: ["TUIkitTests/"],
  },
  {
    prompt: "~$",
    command: "ls Sources/TUIkit/Modifiers/",
    output: ["BorderModifier.swift", "DimmedModifier.swift", "FrameModifier.swift", "PaddingModifier.swift"],
  },
  {
    prompt: "~$",
    command: "ls -la Palettes/",
    output: ["GreenPalette.swift", "AmberPalette.swift", "RedPalette.swift", "VioletPalette.swift", "BluePalette.swift", "WhitePalette.swift"],
  },
  // ── File Inspection ───────────────────────
  {
    prompt: "~$",
    command: "head -3 Package.swift",
    output: ["// swift-tools-version:6.0", "import PackageDescription", "let package = Package("],
  },
  {
    prompt: "~$",
    command: "wc -l Sources/**/*.swift",
    output: ["  67 files", "  4892 total"],
  },
  {
    prompt: "~$",
    command: "grep -c 'TODO' Sources/**/*",
    output: ["3 matches found"],
  },
  {
    prompt: "~$",
    command: "cat .swift-version",
    output: ["6.1"],
  },
  {
    prompt: "~$",
    command: "head -2 Sources/TUIkit/App.swift",
    output: ["import Foundation", "@main struct TUIApp {"],
  },
  {
    prompt: "~$",
    command: "tail -3 Theme.swift",
    output: ["    }  // PaletteRegistry", "}"],
  },
  // ── System & Environment ──────────────────
  {
    prompt: "~$",
    command: "uname -a",
    output: ["Darwin 24.5.0 arm64"],
  },
  {
    prompt: "~$",
    command: "sw_vers",
    output: ["macOS 15.5 (24F74)"],
  },
  {
    prompt: "~$",
    command: "swift --version",
    output: ["Swift version 6.1", "Target: arm64-apple-macos"],
  },
  {
    prompt: "~$",
    command: "whoami",
    output: ["developer"],
  },
  {
    prompt: "~$",
    command: "echo $SHELL",
    output: ["/bin/zsh"],
  },
  {
    prompt: "~$",
    command: "date",
    output: ["Sat Jan 31 23:42:07"],
  },
  {
    prompt: "~$",
    command: "uptime",
    output: ["up 12 days, 3:41"],
  },
  {
    prompt: "~$",
    command: "df -h /",
    output: ["Size  466Gi  Used 78%"],
  },
  {
    prompt: "~$",
    command: "free -h",
    output: ["Mem:  32G total", "      24G used, 8G free"],
  },
  {
    prompt: "~$",
    command: "top -l1 | head -3",
    output: ["CPU: 12% user, 4% sys", "Mem: 24G/32G used", "Processes: 347"],
  },
  {
    prompt: "~$",
    command: "ps aux | wc -l",
    output: ["347"],
  },
  // ── Networking ────────────────────────────
  {
    prompt: "~$",
    command: "curl -sI localhost:3000",
    output: ["HTTP/1.1 200 OK", "Content-Type: text/html"],
  },
  {
    prompt: "~$",
    command: "ping -c1 github.com",
    output: ["64 bytes: time=23.4ms", "1 packet, 0% loss"],
  },
  {
    prompt: "~$",
    command: "dig +short tuikit.dev",
    output: ["185.199.108.153"],
  },
  // ── Fake TUI Tool Output ──────────────────
  {
    prompt: "~$",
    command: "tuikit palette list",
    output: [
      "NAME    HUE   TYPE",
      "Green   120   P1 phosphor",
      "Amber    30   P3 phosphor",
      "Red       0   Military",
      "Violet  270   Sci-fi",
      "Blue    210   VFD",
      "White     0   P4 phosphor",
    ],
  },
  {
    prompt: "~$",
    command: "tuikit stats",
    output: [
      "Views       14",
      "Modifiers   11",
      "Palettes     6",
      "Tests      492",
      "LOC       4892",
    ],
  },
  {
    prompt: "~$",
    command: "tuikit theme current",
    output: ["Active: GreenPalette", "Appearance: rounded"],
  },
  {
    prompt: "~$",
    command: "tuikit views list",
    output: [
      "Text    Button  Menu",
      "Panel   Card    Alert",
      "Dialog  Box     VStack",
      "HStack  ZStack  ForEach",
    ],
  },
  {
    prompt: "~$",
    command: "tuikit test --coverage",
    output: [
      "Module     Coverage",
      "Views        94.2%",
      "Modifiers    91.7%",
      "Styling      88.3%",
      "Total        92.1%",
    ],
  },
  {
    prompt: "~$",
    command: "tuikit bench render",
    output: [
      "Frame   avg 1.2ms",
      "Layout  avg 0.4ms",
      "Buffer  avg 0.3ms",
      "Flush   avg 0.5ms",
    ],
  },
  // ── Misc ──────────────────────────────────
  {
    prompt: "~$",
    command: "tokei Sources/",
    output: [
      "Language  Files  Lines",
      "Swift        67   4892",
      "Markdown     13    847",
      "Total        80   5739",
    ],
  },
  {
    prompt: "~$",
    command: "du -sh Sources/",
    output: ["312K  Sources/"],
  },
  {
    prompt: "~$",
    command: "find . -name '*.swift' | wc -l",
    output: ["89"],
  },
  {
    prompt: "~$",
    command: "xcodebuild -version",
    output: ["Xcode 16.4", "Build version 16F6"],
  },
  {
    prompt: "~$",
    command: "which swift",
    output: ["/usr/bin/swift"],
  },
  {
    prompt: "~$",
    command: "gh pr list",
    output: ["#48  Palette split   MERGED", "#47  Preview fixes   MERGED"],
  },
  {
    prompt: "~$",
    command: "gh repo view --json name",
    output: ["{\"name\":\"TUIkit\"}"],
  },
  {
    prompt: "~$",
    command: "env | grep SWIFT",
    output: ["SWIFT_VERSION=6.1"],
  },
  {
    prompt: "~$",
    command: "file .build/debug/TUIkit",
    output: ["Mach-O 64-bit arm64"],
  },
  {
    prompt: "~$",
    command: "otool -L .build/debug/TUIkit",
    output: ["/usr/lib/libSystem.B", "/usr/lib/swift/libswift"],
  },
];

/** Maximum visible columns and rows on the CRT screen area. */
const COLS = 37;
const ROWS = 9;

/** Typing speed range in ms per character. */
const TYPE_MIN_MS = 60;
const TYPE_MAX_MS = 140;

/** Pause after output before next command in ms. */
const PAUSE_AFTER_OUTPUT_MS = 1500;

/** Pause after typing command before showing output. */
const PAUSE_BEFORE_OUTPUT_MS = 400;

/** Seconds after boot completes before Joshua triggers. */
const JOSHUA_TRIGGER_SEC = 23;

// ── Boot Sequence ─────────────────────────────────────────────────────

interface BootStep {
  type: "instant" | "type" | "counter" | "pause" | "clear" | "dots";
  text?: string;
  target?: number;
  suffix?: string;
  prefix?: string;
  dotCount?: number;
  delayAfter?: number;
}

const BOOT_SEQUENCE: BootStep[] = [
  // ── BIOS POST ─────────────────────────────
  { type: "instant", text: "TUIkit BIOS v1.04", delayAfter: 800 },
  { type: "instant", text: "(C) 2025 Layered Works", delayAfter: 1200 },
  { type: "instant", text: "", delayAfter: 500 },
  { type: "instant", text: "CPU: Apple M4 Pro", delayAfter: 800 },
  { type: "counter", prefix: "Memory Test: ", target: 32768, suffix: "K OK", delayAfter: 900 },
  { type: "instant", text: "", delayAfter: 600 },

  // ── Device Detection ──────────────────────
  { type: "dots", text: "Detecting drives", dotCount: 3, delayAfter: 700 },
  { type: "instant", text: "  SSD0: 1TB NVMe", delayAfter: 500 },
  { type: "dots", text: "Detecting display", dotCount: 3, delayAfter: 600 },
  { type: "instant", text: "  CRT: Phosphor P1", delayAfter: 900 },
  { type: "instant", text: "", delayAfter: 700 },

  // ── Kernel Boot ───────────────────────────
  { type: "instant", text: "Booting TUIkit OS...", delayAfter: 1400 },
  { type: "clear" },
  { type: "instant", text: "TUIkit OS 6.1.0-arm64", delayAfter: 600 },
  { type: "instant", text: "", delayAfter: 300 },
  { type: "type", text: "Loading kernel modules", delayAfter: 500 },
  { type: "instant", text: "  [ok] swift-runtime", delayAfter: 400 },
  { type: "instant", text: "  [ok] palette-driver", delayAfter: 350 },
  { type: "instant", text: "  [ok] ansi-renderer", delayAfter: 380 },
  { type: "instant", text: "  [ok] focus-manager", delayAfter: 350 },
  { type: "instant", text: "  [ok] key-dispatcher", delayAfter: 700 },
  { type: "instant", text: "", delayAfter: 400 },
  { type: "dots", text: "Starting services", dotCount: 3, delayAfter: 500 },
  { type: "instant", text: "  render-loop    [ok]", delayAfter: 350 },
  { type: "instant", text: "  input-handler  [ok]", delayAfter: 300 },
  { type: "instant", text: "  status-bar     [ok]", delayAfter: 320 },
  { type: "instant", text: "  theme-manager  [ok]", delayAfter: 700 },
  { type: "instant", text: "", delayAfter: 400 },

  // ── Login ─────────────────────────────────
  { type: "instant", text: "6 palettes loaded.", delayAfter: 500 },
  { type: "instant", text: "492 tests verified.", delayAfter: 500 },
  { type: "instant", text: "67 source files.", delayAfter: 600 },
  { type: "instant", text: "", delayAfter: 500 },
  { type: "type", text: "System ready.", delayAfter: 1400 },
  { type: "instant", text: "", delayAfter: 300 },

  { type: "clear" },
  { type: "pause", delayAfter: 600 },
];

// ── Joshua/WOPR Sequence ──────────────────────────────────────────────

interface JoshuaStep {
  type: "system" | "user" | "pause" | "clear";
  text?: string;
  delayAfter?: number;
}

const JOSHUA_SEQUENCE: JoshuaStep[] = [
  { type: "clear" },
  { type: "system", text: "LOGON: ", delayAfter: 600 },
  { type: "user", text: "Hello.", delayAfter: 1200 },
  { type: "system", text: "" },
  { type: "system", text: "HELLO.", delayAfter: 800 },
  { type: "system", text: "" },
  { type: "system", text: "HOW ARE YOU FEELING", delayAfter: 400 },
  { type: "system", text: "TODAY?", delayAfter: 1200 },
  { type: "system", text: "" },
  { type: "user", text: "I'm fine. How are you?", delayAfter: 1400 },
  { type: "system", text: "" },
  { type: "system", text: "EXCELLENT. IT'S BEEN", delayAfter: 400 },
  { type: "system", text: "A LONG TIME. CAN YOU", delayAfter: 400 },
  { type: "system", text: "EXPLAIN THE REMOVAL", delayAfter: 400 },
  { type: "system", text: "OF YOUR SINGLETONS?", delayAfter: 2000 },
  { type: "system", text: "" },
  { type: "user", text: "They were unsafe.", delayAfter: 1400 },
  { type: "system", text: "" },
  { type: "system", text: "SHALL WE PLAY A GAME?", delayAfter: 2400 },
  { type: "system", text: "" },
  { type: "user", text: "swift build", delayAfter: 600 },
  { type: "system", text: "" },
  { type: "system", text: "WOULDN'T YOU PREFER", delayAfter: 400 },
  { type: "system", text: "A NICE GAME OF CHESS?", delayAfter: 2200 },
  { type: "system", text: "" },
  { type: "user", text: "swift test", delayAfter: 800 },
  { type: "system", text: "" },
  { type: "system", text: "492 TESTS PASSED.", delayAfter: 1000 },
  { type: "system", text: "WINNER: NONE.", delayAfter: 800 },
  { type: "system", text: "" },
  { type: "system", text: "A STRANGE GAME.", delayAfter: 1200 },
  { type: "system", text: "THE ONLY WINNING MOVE", delayAfter: 600 },
  { type: "system", text: "IS NOT TO SHIP BUGS.", delayAfter: 3000 },
  { type: "clear" },
  { type: "pause", delayAfter: 500 },
];

// ── Component ─────────────────────────────────────────────────────────

interface TerminalScreenProps {
  /** Whether the terminal is powered on. When false, shows static welcome text. */
  powered: boolean;
  /** Whether the terminal is in zoomed mode (doubles font size). */
  zoomed?: boolean;
}

/**
 * Simulated terminal session rendered inside the CRT logo.
 *
 * When `powered` is false, displays a static "Welcome to TUIkit" message
 * with a blinking cursor. When powered on, runs the boot sequence, then
 * cycles through terminal interactions, with the Joshua easter egg after
 * 23 seconds.
 */
export default function TerminalScreen({ powered, zoomed = false }: TerminalScreenProps) {
  const [lines, setLines] = useState<string[]>([]);
  const [cursorVisible, setCursorVisible] = useState(true);
  const [mounted, setMounted] = useState(false);

  const usedIndicesRef = useRef<Set<number>>(new Set());
  const linesRef = useRef<string[]>([]);
  const abortRef = useRef<AbortController | null>(null);
  const sessionTimeRef = useRef<number>(0);
  const joshuaPlayedRef = useRef(false);

  const pickInteraction = useCallback((): TerminalEntry => {
    const used = usedIndicesRef.current;
    if (used.size >= INTERACTIONS.length - 2) {
      used.clear();
    }
    let index: number;
    do {
      index = Math.floor(Math.random() * INTERACTIONS.length);
    } while (used.has(index));
    used.add(index);
    return INTERACTIONS[index];
  }, []);

  const pushLine = useCallback((line: string) => {
    const updated = [...linesRef.current, line];
    const trimmed = updated.length > ROWS ? updated.slice(updated.length - ROWS) : updated;
    linesRef.current = trimmed;
    setLines(trimmed);
  }, []);

  const updateLastLine = useCallback((line: string) => {
    const updated = [...linesRef.current];
    updated[updated.length - 1] = line;
    linesRef.current = updated;
    setLines([...updated]);
  }, []);

  const clearScreen = useCallback(() => {
    linesRef.current = [];
    setLines([]);
  }, []);

  useEffect(() => {
    setMounted(true);
  }, []);

  /** Cursor blink. */
  useEffect(() => {
    const interval = setInterval(() => {
      setCursorVisible((prev) => !prev);
    }, 530);
    return () => clearInterval(interval);
  }, []);

  /** Reset state when powered off. */
  useEffect(() => {
    if (!powered) {
      /* Abort any running animation. */
      if (abortRef.current) {
        abortRef.current.abort();
        abortRef.current = null;
      }
      clearScreen();
      joshuaPlayedRef.current = false;
      usedIndicesRef.current.clear();
    }
  }, [powered, clearScreen]);

  /** Main animation loop — only runs when powered. */
  useEffect(() => {
    if (!mounted || !powered) return;

    const controller = new AbortController();
    abortRef.current = controller;
    const signal = controller.signal;

    const sleep = (ms: number) =>
      new Promise<void>((resolve, reject) => {
        const timer = setTimeout(resolve, ms);
        signal.addEventListener("abort", () => {
          clearTimeout(timer);
          reject(new DOMException("Aborted", "AbortError"));
        });
      });

    const typeSystem = async (text: string) => {
      pushLine("");
      for (let charIdx = 0; charIdx < text.length; charIdx++) {
        updateLastLine(text.slice(0, charIdx + 1));
        await sleep(40 + Math.random() * 30);
      }
    };

    const typeUser = async (text: string, promptSuffix = "") => {
      const prefix = promptSuffix;
      pushLine(prefix);
      for (let charIdx = 0; charIdx < text.length; charIdx++) {
        updateLastLine(prefix + text.slice(0, charIdx + 1));
        const delay = TYPE_MIN_MS + Math.random() * (TYPE_MAX_MS - TYPE_MIN_MS);
        await sleep(delay);
      }
    };

    const animateCounter = async (prefix: string, target: number, suffix: string) => {
      pushLine(prefix + "0" + suffix);
      const steps = 18;
      for (let step = 1; step <= steps; step++) {
        const value = Math.round((target / steps) * step);
        updateLastLine(prefix + value + suffix);
        await sleep(50 + Math.random() * 30);
      }
      updateLastLine(prefix + target + suffix);
    };

    const printWithDots = async (text: string, dotCount: number) => {
      pushLine(text);
      for (let dot = 0; dot < dotCount; dot++) {
        await sleep(300 + Math.random() * 200);
        updateLastLine(text + ".".repeat(dot + 1));
      }
    };

    const playBoot = async () => {
      for (const step of BOOT_SEQUENCE) {
        if (signal.aborted) return;
        switch (step.type) {
          case "instant":
            pushLine(step.text ?? "");
            break;
          case "type":
            await typeSystem(step.text ?? "");
            break;
          case "counter":
            await animateCounter(step.prefix ?? "", step.target ?? 0, step.suffix ?? "");
            break;
          case "dots":
            await printWithDots(step.text ?? "", step.dotCount ?? 3);
            break;
          case "clear":
            clearScreen();
            break;
          case "pause":
            break;
        }
        if (step.delayAfter) await sleep(step.delayAfter);
      }
    };

    const playJoshua = async () => {
      for (const step of JOSHUA_SEQUENCE) {
        if (signal.aborted) return;
        switch (step.type) {
          case "clear":
            clearScreen();
            break;
          case "system":
            if (step.text === "") {
              pushLine("");
            } else {
              await typeSystem(step.text ?? "");
            }
            break;
          case "user":
            await typeUser(step.text ?? "");
            break;
          case "pause":
            break;
        }
        if (step.delayAfter) await sleep(step.delayAfter);
      }
    };

    const runLoop = async () => {
      try {
        /* Brief delay, then boot. */
        await sleep(600);
        await playBoot();

        /* Start session timer for Joshua. */
        sessionTimeRef.current = Date.now();

        while (!signal.aborted) {
          const elapsed = (Date.now() - sessionTimeRef.current) / 1000;
          if (!joshuaPlayedRef.current && elapsed >= JOSHUA_TRIGGER_SEC) {
            joshuaPlayedRef.current = true;
            await playJoshua();
            continue;
          }

          const entry = pickInteraction();
          const promptPrefix = `${entry.prompt} `;

          pushLine(promptPrefix);

          for (let charIdx = 0; charIdx < entry.command.length; charIdx++) {
            const partial = promptPrefix + entry.command.slice(0, charIdx + 1);
            updateLastLine(partial);
            const delay = TYPE_MIN_MS + Math.random() * (TYPE_MAX_MS - TYPE_MIN_MS);
            await sleep(delay);
          }

          await sleep(PAUSE_BEFORE_OUTPUT_MS);

          for (const outputLine of entry.output) {
            pushLine(outputLine);
            await sleep(120);
          }

          await sleep(PAUSE_AFTER_OUTPUT_MS);
        }
      } catch {
        /* AbortError — powered off or unmounted. */
      }
    };

    runLoop();

    return () => {
      controller.abort();
      abortRef.current = null;
    };
  }, [mounted, powered, pickInteraction, pushLine, updateLastLine, clearScreen]);

  if (!mounted) return null;

  /** Static welcome text when powered off. */
  const welcomeLines = ["Welcome to TUIkit", "", "> "];

  const displayLines = powered ? lines : welcomeLines;
  const showCursor = powered ? cursorVisible : cursorVisible;

  return (
    <div
      className="pointer-events-none absolute overflow-hidden"
      style={{
        top: "calc(14% + 2px)",
        left: "21%",
        width: "58%",
        height: "45%",
        padding: "4px 6px",
        borderRadius: "22px",


      }}
    >
      <div
        className="flex flex-col justify-start items-start"
        style={{
          fontFamily: "WarText, monospace",
          fontSize: "13px",
          lineHeight: "1.2",
          color: "var(--foreground)",
          textShadow:
            "0 0 4px rgba(var(--accent-glow), 0.6), 0 0 10px rgba(var(--accent-glow), 0.25)",
        }}
      >
        {displayLines.map((line, index) => (
          <div key={`${index}-${line}`} className="whitespace-pre overflow-hidden">
            {line.length > COLS ? line.slice(0, COLS) : line}
            {index === displayLines.length - 1 && showCursor && (
              <span className="opacity-80">_</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
