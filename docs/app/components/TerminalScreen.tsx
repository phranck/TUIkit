"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { TERMINAL_SCRIPT } from "./terminal-data";

/** A single terminal interaction: command + optional output lines. */
interface TerminalEntry {
  prompt: string;
  command: string;
  output: string[];
}

/**
 * Pool of classic UNIX terminal interactions.
 * Each entry has a prompt, a command typed character-by-character,
 * and output lines that appear instantly after "execution".
 * ~50 entries for 3+ minutes without repeats.
 */
const INTERACTIONS: TerminalEntry[] = TERMINAL_SCRIPT.unixCommands;

/** Maximum visible columns and rows on the CRT screen area. */
const COLS = 37;
const ROWS = 9;

/** Load configuration from parsed script. */
const { config } = TERMINAL_SCRIPT;
const TYPE_MIN_MS = config.typeMin;
const TYPE_MAX_MS = config.typeMax;
const PAUSE_AFTER_OUTPUT_MS = config.pauseAfterOutput;
const PAUSE_BEFORE_OUTPUT_MS = config.pauseBeforeOutput;
const SCHOOL_TRIGGER_SEC = config.schoolTrigger;
const JOSHUA_TRIGGER_SEC = config.joshuaTrigger;

// ── Load sequences from parsed script ────────────────────────────────────

interface BootStep {
  type: "instant" | "type" | "counter" | "pause" | "clear" | "dots";
  text?: string;
  target?: number;
  prefix?: string;
  suffix?: string;
  dotCount?: number;
  delayAfter?: number;
}

const BOOT_SEQUENCE: BootStep[] = TERMINAL_SCRIPT.bootSequence as BootStep[];

// ── School Computer Grade Change Sequence ─────────────────────────────

interface SchoolStep {
  type: "system" | "user" | "inline" | "pause" | "clear";
  prompt?: string;  // For inline type: the prompt text
  text?: string;
  delayAfter?: number;
}

const SCHOOL_SEQUENCE: SchoolStep[] = TERMINAL_SCRIPT.schoolSequence as SchoolStep[];

// ── Joshua/WOPR Sequence ──────────────────────────────────────────────

interface JoshuaStep {
  type: "system" | "user" | "pause" | "clear" | "barrage";
  text?: string;
  delayAfter?: number;
}

const JOSHUA_SEQUENCE: JoshuaStep[] = TERMINAL_SCRIPT.joshuaSequence as JoshuaStep[];

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
  const [terminalOpacity, setTerminalOpacity] = useState(0);

  const usedIndicesRef = useRef<Set<number>>(new Set());
  const linesRef = useRef<string[]>([]);
  const abortRef = useRef<AbortController | null>(null);
  const sessionTimeRef = useRef<number>(0);
  const schoolPlayedRef = useRef(false);
  const joshuaPlayedRef = useRef(false);

  const pickInteraction = useCallback((): TerminalEntry => {
    const used = usedIndicesRef.current;
    if (used.size >= INTERACTIONS.length) {
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
    lineRefsRef.current = [];
    setLines([]);
  }, []);

  /** Cursor blink. */
  useEffect(() => {
    const interval = setInterval(() => {
      setCursorVisible((prev) => !prev);
    }, 530);
    return () => clearInterval(interval);
  }, []);

  /** Fade in entire terminal over 6 seconds when powered on. */
  useEffect(() => {
    if (powered) {
      setTerminalOpacity(0);
      
      const startTime = Date.now();
      const duration = 6000; // 6 seconds
      
      const fadeIn = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        setTerminalOpacity(progress);
        
        if (progress < 1) {
          requestAnimationFrame(fadeIn);
        }
      };
      
      requestAnimationFrame(fadeIn);
    } else {
      setTerminalOpacity(0);
    }
  }, [powered]);

  /** Reset state when powered off. */
  useEffect(() => {
    if (!powered) {
      /* Abort any running animation. */
      if (abortRef.current) {
        abortRef.current.abort();
        abortRef.current = null;
      }
      clearScreen();
      schoolPlayedRef.current = false;
      joshuaPlayedRef.current = false;
      usedIndicesRef.current.clear();
    }
  }, [powered, clearScreen]);

  /** Main animation loop — only runs when powered. */
  useEffect(() => {
    if (!powered) return;

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

    /**
     * Simulates a human typing at a physical keyboard.
     *
     * Varies timing per character to mimic real keystrokes:
     * - Short bursts of fast typing (50–80ms) for familiar sequences
     * - Thinking pauses (300–600ms) after spaces and punctuation
     * - Occasional mid-word hesitation (200–350ms, ~15% chance)
     * - Slightly faster within a word, slower at boundaries
     */
    const typeUser = async (text: string, prefix = "") => {
      pushLine(prefix);
      for (let charIdx = 0; charIdx < text.length; charIdx++) {
        updateLastLine(prefix + text.slice(0, charIdx + 1));
        const char = text[charIdx];
        const nextChar = text[charIdx + 1];

        let delay: number;
        if (char === " " || char === "." || char === "," || char === "?") {
          /* Pause after word boundary or punctuation — thinking time. */
          delay = 250 + Math.random() * 350;
        } else if (nextChar === " " || charIdx === text.length - 1) {
          /* Slightly slower on last char of a word — finger lifting. */
          delay = 100 + Math.random() * 120;
        } else if (Math.random() < 0.15) {
          /* Occasional mid-word hesitation — hunting for the right key. */
          delay = 180 + Math.random() * 170;
        } else {
          /* Fast burst within a word. */
          delay = 45 + Math.random() * 55;
        }
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

    /** Rapid barrage of random hex/data to simulate the WOPR handshake. */
    const playBarrage = async () => {
      const chars = "0123456789ABCDEF.:/<>[]{}#@!$%&*";
      const frames = 30;
      for (let frame = 0; frame < frames; frame++) {
        if (signal.aborted) return;
        clearScreen();
        const lineCount = Math.floor(Math.random() * 3) + ROWS - 2;
        for (let row = 0; row < lineCount; row++) {
          const len = Math.floor(Math.random() * (COLS - 4)) + 8;
          let line = "";
          for (let col = 0; col < len; col++) {
            line += chars[Math.floor(Math.random() * chars.length)];
          }
          pushLine(line);
        }
        await sleep(60 + Math.random() * 40);
      }
    };

    const playSchool = async () => {
      for (const step of SCHOOL_SEQUENCE) {
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
            await typeUser(step.text ?? "", "");
            break;
          case "inline":
            // Prompt and user input on same line
            await typeUser(step.text ?? "", step.prompt ?? "");
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
          case "barrage":
            await playBarrage();
            break;
          case "system":
            if (step.text === "") {
              pushLine("");
            } else {
              await typeSystem(step.text ?? "");
            }
            break;
          case "user":
            await typeUser(step.text ?? "", "> ");
            break;
          case "pause":
            break;
        }
        if (step.delayAfter) await sleep(step.delayAfter);
      }
    };

    const runLoop = async () => {
      try {
        /* Show only prompt with blinking cursor for 18 seconds */
        pushLine("> ");
        await sleep(18000);
        
        /* Clear and start boot sequence */
        clearScreen();
        await playBoot();

        /* Start session timer for scenes. */
        sessionTimeRef.current = Date.now();

        while (!signal.aborted) {
          const elapsed = (Date.now() - sessionTimeRef.current) / 1000;
          
          /* Trigger school computer scene after 12 seconds of UNIX commands */
          if (!schoolPlayedRef.current && elapsed >= SCHOOL_TRIGGER_SEC) {
            schoolPlayedRef.current = true;
            await playSchool();
            sessionTimeRef.current = Date.now(); // Reset timer for next scene
            continue;
          }
          
          /* Trigger Joshua/WOPR scene after another 12 seconds of UNIX commands */
          if (schoolPlayedRef.current && !joshuaPlayedRef.current && elapsed >= JOSHUA_TRIGGER_SEC) {
            joshuaPlayedRef.current = true;
            await playJoshua();
            sessionTimeRef.current = Date.now(); // Reset timer, continue normal loop
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
  }, [powered, pickInteraction, pushLine, updateLastLine, clearScreen]);

  const lineRefsRef = useRef<(HTMLDivElement | null)[]>([]);

  /**
   * CRT scanline glitch — randomly shifts multiple text lines
   * horizontally in independent directions for a few frames,
   * simulating an unstable electron beam. Each glitched line
   * gets its own random offset. Fires every 3–8 seconds.
   */
  useEffect(() => {
    if (!powered) return;
    let timeout: ReturnType<typeof setTimeout>;

    const triggerGlitch = () => {
      const lineElements = lineRefsRef.current.filter(Boolean) as HTMLDivElement[];
      if (lineElements.length === 0) {
        timeout = setTimeout(triggerGlitch, 3000 + Math.random() * 5000);
        return;
      }

      const glitched: HTMLDivElement[] = [];

      /* Glitch 2–5 random lines, each with its own direction and intensity. */
      const count = 2 + Math.floor(Math.random() * 4);
      const indices = new Set<number>();
      while (indices.size < Math.min(count, lineElements.length)) {
        indices.add(Math.floor(Math.random() * lineElements.length));
      }

      for (const idx of indices) {
        const element = lineElements[idx];
        const shift = (Math.random() - 0.5) * 16;
        element.style.transform = `translateX(${shift}px)`;
        element.style.transition = "none";
        glitched.push(element);
      }

      /* Reset after 50–120ms. */
      setTimeout(() => {
        for (const element of glitched) {
          element.style.transition = "transform 0.05s";
          element.style.transform = "translateX(0)";
        }
      }, 50 + Math.random() * 70);

      timeout = setTimeout(triggerGlitch, 3000 + Math.random() * 5000);
    };

    timeout = setTimeout(triggerGlitch, 2000 + Math.random() * 3000);
    return () => clearTimeout(timeout);
  }, [powered]);

  /* Powered off — no content, just dark glass. */
  if (!powered) return null;

  return (
    <div
      className="pointer-events-none overflow-hidden"
      style={{
        width: "100%",
        height: "100%",
        padding: "4px 6px",
        opacity: terminalOpacity,
        transition: "none", // Use requestAnimationFrame instead of CSS transition
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
        {lines.map((line, index) => (
          <div
            key={index}
            ref={(element) => { lineRefsRef.current[index] = element; }}
            className="whitespace-pre overflow-hidden"
          >
            {line.length > COLS ? line.slice(0, COLS) : line}
            {index === lines.length - 1 && cursorVisible && (
              <span className="opacity-80">_</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
