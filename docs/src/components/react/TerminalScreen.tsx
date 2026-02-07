import { useCallback, useEffect, useRef, useState } from "react";
import { TERMINAL_SCRIPT } from "./terminal-data";
import type { BootStep, SchoolStep, JoshuaStep, TerminalEntry } from "../../lib/terminal-parser";

/**
 * Parse simple HTML-like tags in terminal text for formatting.
 * Supports: <b>, <u>, <s>, <i>
 */
function parseTerminalFormatting(text: string): React.ReactNode[] {
  const parts: React.ReactNode[] = [];
  let lastIndex = 0;
  let partKey = 0;
  
  // If no tags found, return plain text
  if (!text.includes('<')) {
    return [text];
  }
  
  // Match <b>, <u>, <s>, <i> tags
  // Use [\s\S] instead of . to match any character including newlines
  // Use non-greedy match to capture content including spaces
  const regex = /<(b|u|s|i)>([\s\S]+?)<\/\1>/g;
  let match: RegExpExecArray | null;
  
  while ((match = regex.exec(text)) !== null) {
    // Add text before tag
    if (match.index > lastIndex) {
      parts.push(text.slice(lastIndex, match.index));
    }
    
    // Add formatted text
    const tag = match[1];
    const content = match[2];
    
    switch (tag) {
      case 'b':
        parts.push(<strong key={partKey++} className="font-bold">{content}</strong>);
        break;
      case 'u':
        parts.push(<span key={partKey++} className="underline">{content}</span>);
        break;
      case 's':
        parts.push(<span key={partKey++} className="line-through">{content}</span>);
        break;
      case 'i':
        parts.push(<em key={partKey++} className="italic">{content}</em>);
        break;
    }
    
    lastIndex = regex.lastIndex;
  }
  
  // Add remaining text
  if (lastIndex < text.length) {
    parts.push(text.slice(lastIndex));
  }
  
  return parts.length > 0 ? parts : [text];
}

/**
 * Truncate a string to a maximum visible length, preserving HTML tags.
 * Tags like <u>, </u>, <b>, </b> etc. are not counted toward the visible length.
 * If truncation happens inside a tag pair, the closing tag is appended to keep
 * the markup well-formed so parseTerminalFormatting can match it.
 */
function truncateToVisibleLength(text: string, maxVisible: number): string {
  // No tags? Simple truncation.
  if (!text.includes('<')) {
    return text.length > maxVisible ? text.slice(0, maxVisible) : text;
  }

  let result = "";
  let visibleCount = 0;
  let index = 0;
  const openTags: string[] = []; // stack of open tag names

  while (index < text.length && visibleCount < maxVisible) {
    if (text[index] === '<') {
      // Find end of tag
      const closeIndex = text.indexOf('>', index);
      if (closeIndex === -1) break;
      const tag = text.slice(index, closeIndex + 1);
      result += tag;

      // Track open/close tags
      const openMatch = tag.match(/^<([busi])>$/);
      const closeMatch = tag.match(/^<\/([busi])>$/);
      if (openMatch) {
        openTags.push(openMatch[1]);
      } else if (closeMatch) {
        openTags.pop();
      }

      index = closeIndex + 1;
    } else {
      result += text[index];
      visibleCount++;
      index++;
    }
  }

  // Close any open tags that were cut off
  for (let tagIdx = openTags.length - 1; tagIdx >= 0; tagIdx--) {
    result += `</${openTags[tagIdx]}>`;
  }

  return result;
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

/** Cursor blink interval in ms (classic terminal feel). */
const CURSOR_BLINK_MS = 530;
/** Per-character delay range for system "typewriter" output (ms). */
const SYSTEM_TYPE_MIN_MS = 40;
const SYSTEM_TYPE_MAX_MS = 70;
/** Fade-in duration when terminal powers on (ms). */
const FADE_IN_DURATION_MS = 6000;
/** Delay between output lines during command playback (ms). */
const OUTPUT_LINE_DELAY_MS = 120;
/** Glitch scheduling range (ms). */
const GLITCH_INITIAL_MIN_MS = 2000;
const GLITCH_INITIAL_MAX_MS = 3000;
const GLITCH_INTERVAL_MIN_MS = 3000;
const GLITCH_INTERVAL_MAX_MS = 5000;
/** Glitch reset delay range (ms). */
const GLITCH_RESET_MIN_MS = 50;
const GLITCH_RESET_MAX_MS = 70;

/** Load configuration from parsed script. */
const { config } = TERMINAL_SCRIPT;
const INITIAL_CURSOR_DELAY_MS = config.initialCursorDelay;
const TYPE_MIN_MS = config.typeMin;
const TYPE_MAX_MS = config.typeMax;
const PAUSE_AFTER_OUTPUT_MS = config.pauseAfterOutput;
const PAUSE_BEFORE_OUTPUT_MS = config.pauseBeforeOutput;
const SCHOOL_TRIGGER_SEC = config.schoolTrigger;
const JOSHUA_TRIGGER_SEC = config.joshuaTrigger;

// Load sequences from parsed script (types imported from terminal-parser)

const BOOT_SEQUENCE: BootStep[] = TERMINAL_SCRIPT.bootSequence;
const SCHOOL_SEQUENCE: SchoolStep[] = TERMINAL_SCRIPT.schoolSequence;
const JOSHUA_SEQUENCE: JoshuaStep[] = TERMINAL_SCRIPT.joshuaSequence;

// Component

interface TerminalScreenProps {
  /** Whether the terminal is powered on. When false, shows static welcome text. */
  powered: boolean;
}

/**
 * Simulated terminal session rendered inside the CRT logo.
 *
 * When `powered` is false, displays a static "Welcome to TUIkit" message
 * with a blinking cursor. When powered on, runs the boot sequence, then
 * cycles through terminal interactions, with the Joshua easter egg after
 * 23 seconds.
 */
export default function TerminalScreen({ powered }: TerminalScreenProps) {
  const [lines, setLines] = useState<{key: number, text: string}[]>([]);
  const [cursorVisible, setCursorVisible] = useState(true);
  const [terminalOpacity, setTerminalOpacity] = useState(0);

  const usedIndicesRef = useRef<Set<number>>(new Set());
  const linesRef = useRef<{key: number, text: string}[]>([]);
  const lineKeyCounterRef = useRef(0);
  const lineRefsRef = useRef<(HTMLDivElement | null)[]>([]);
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

  const pushLine = useCallback((text: string) => {
    const entry = { key: lineKeyCounterRef.current++, text };
    const updated = [...linesRef.current, entry];
    const trimmed = updated.length > ROWS ? updated.slice(updated.length - ROWS) : updated;
    linesRef.current = trimmed;
    // Keep lineRefsRef in sync to prevent stale DOM refs from accumulating.
    lineRefsRef.current = lineRefsRef.current.slice(-ROWS);
    setLines(trimmed);
  }, []);

  const updateLastLine = useCallback((text: string) => {
    const updated = [...linesRef.current];
    updated[updated.length - 1] = { ...updated[updated.length - 1], text };
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
    }, CURSOR_BLINK_MS);
    return () => clearInterval(interval);
  }, []);

  /** Fade in entire terminal over 6 seconds when powered on.
   *  Cleanup resets opacity to 0 when powered off (avoids setState-in-effect). */
  useEffect(() => {
    if (!powered) return;
    
    const startTime = Date.now();
    const duration = FADE_IN_DURATION_MS;
    let rafId: number;
    
    const fadeIn = () => {
      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / duration, 1);
      setTerminalOpacity(progress);
      
      if (progress < 1) {
        rafId = requestAnimationFrame(fadeIn);
      }
    };
    
    rafId = requestAnimationFrame(fadeIn);
    
    return () => {
      if (rafId) cancelAnimationFrame(rafId);
      setTerminalOpacity(0);
    };
  }, [powered]);

  /** Reset terminal state when powered off.
   *  Cleanup handles abort + state reset so no setState lives in the effect body. */
  useEffect(() => {
    if (!powered) return;

    // Capture ref values inside effect to satisfy exhaustive-deps rule.
    const usedIndices = usedIndicesRef.current;

    return () => {
      /* Abort any running animation. */
      if (abortRef.current) {
        abortRef.current.abort();
        abortRef.current = null;
      }
      /* Clear terminal state */
      linesRef.current = [];
      lineRefsRef.current = [];
      setLines([]);
      schoolPlayedRef.current = false;
      joshuaPlayedRef.current = false;
      usedIndices.clear();
    };
  }, [powered]);

  /** Main animation loop: only runs when powered. */
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

    /**
     * Types text character-by-character, but handles HTML tags specially:
     * - Opening and closing tags appear instantly as a pair
     * - Only the visible text content is typed character-by-character
     */
    const typeSystem = async (text: string) => {
      pushLine("");
      
      // If no HTML tags, just type normally
      if (!text.includes('<')) {
        for (let charIdx = 0; charIdx < text.length; charIdx++) {
          updateLastLine(text.slice(0, charIdx + 1));
          await sleep(SYSTEM_TYPE_MIN_MS + Math.random() * (SYSTEM_TYPE_MAX_MS - SYSTEM_TYPE_MIN_MS));
        }
        return;
      }
      
      // Match paired tags with their content: <tag>content</tag>
      const pairedTagRegex = /<([busi])>([\s\S]*?)<\/\1>/g;
      const segments: Array<{type: 'plain' | 'wrapped', tag?: string, content: string}> = [];
      let lastIndex = 0;
      let match: RegExpExecArray | null;
      
      while ((match = pairedTagRegex.exec(text)) !== null) {
        // Add plain text before this tag pair
        if (match.index > lastIndex) {
          segments.push({type: 'plain', content: text.slice(lastIndex, match.index)});
        }
        // Add the content inside tags (we'll wrap it during typing)
        segments.push({type: 'wrapped', tag: match[1], content: match[2]});
        lastIndex = pairedTagRegex.lastIndex;
      }
      // Add remaining plain text
      if (lastIndex < text.length) {
        segments.push({type: 'plain', content: text.slice(lastIndex)});
      }
      
      // Type segments
      let displayText = "";
      for (const segment of segments) {
        if (segment.type === 'plain') {
          // Plain text: type char-by-char
          const charDelay = () => SYSTEM_TYPE_MIN_MS + Math.random() * (SYSTEM_TYPE_MAX_MS - SYSTEM_TYPE_MIN_MS);
          for (let i = 0; i < segment.content.length; i++) {
            displayText += segment.content[i];
            updateLastLine(displayText);
            await sleep(charDelay());
          }
        } else {
          // Wrapped text: show opening/closing tags instantly, type content char-by-char
          const openTag = `<${segment.tag}>`;
          const closeTag = `</${segment.tag}>`;
          
          // Insert opening and closing tags instantly
          displayText += openTag + closeTag;
          updateLastLine(displayText);
          
          // Now type the content character-by-character BETWEEN the tags
          const beforeClose = displayText.slice(0, -closeTag.length);
          const charDelay = () => SYSTEM_TYPE_MIN_MS + Math.random() * (SYSTEM_TYPE_MAX_MS - SYSTEM_TYPE_MIN_MS);
          for (let i = 0; i < segment.content.length; i++) {
            const typed = beforeClose + segment.content.slice(0, i + 1) + closeTag;
            updateLastLine(typed);
            await sleep(charDelay());
          }
          displayText = beforeClose + segment.content + closeTag;
        }
      }
    };

    /**
     * Simulates a human typing at a physical keyboard.
     *
     * Varies timing per character to mimic real keystrokes:
     * - Short bursts of fast typing (50-80ms) for familiar sequences
     * - Thinking pauses (300-600ms) after spaces and punctuation
     * - Occasional mid-word hesitation (200-350ms, ~15% chance)
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
          /* Pause after word boundary or punctuation: thinking time. */
          delay = 250 + Math.random() * 350;
        } else if (nextChar === " " || charIdx === text.length - 1) {
          /* Slightly slower on last char of a word: finger lifting. */
          delay = 100 + Math.random() * 120;
        } else if (Math.random() < 0.15) {
          /* Occasional mid-word hesitation: hunting for the right key. */
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
        /* Show only prompt with blinking cursor before boot starts. */
        pushLine("> ");
        await sleep(INITIAL_CURSOR_DELAY_MS);
        
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
            await sleep(OUTPUT_LINE_DELAY_MS);
          }

          await sleep(PAUSE_AFTER_OUTPUT_MS);
        }
      } catch {
        /* AbortError: powered off or unmounted. */
      }
    };

    runLoop();

    return () => {
      controller.abort();
      abortRef.current = null;
    };
  }, [powered, pickInteraction, pushLine, updateLastLine, clearScreen]);

  /**
   * CRT scanline glitch: randomly shifts multiple text lines
   * horizontally in independent directions for a few frames,
   * simulating an unstable electron beam. Each glitched line
   * gets its own random offset. Fires every 3-8 seconds.
   */
  useEffect(() => {
    if (!powered) return;
    // Skip glitch effect for users who prefer reduced motion.
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    let timeout: ReturnType<typeof setTimeout>;
    let resetTimeout: ReturnType<typeof setTimeout>;

    const triggerGlitch = () => {
      const lineElements = lineRefsRef.current.filter((el): el is HTMLDivElement => el !== null);
      if (lineElements.length === 0) {
        timeout = setTimeout(triggerGlitch, GLITCH_INTERVAL_MIN_MS + Math.random() * (GLITCH_INTERVAL_MAX_MS - GLITCH_INTERVAL_MIN_MS));
        return;
      }

      const glitched: HTMLDivElement[] = [];

      /* Glitch 2-5 random lines, each with its own direction and intensity. */
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

      /* Reset after 50-120ms. */
      resetTimeout = setTimeout(() => {
        for (const element of glitched) {
          element.style.transition = "transform 0.05s";
          element.style.transform = "translateX(0)";
        }
      }, GLITCH_RESET_MIN_MS + Math.random() * (GLITCH_RESET_MAX_MS - GLITCH_RESET_MIN_MS));

      timeout = setTimeout(triggerGlitch, GLITCH_INTERVAL_MIN_MS + Math.random() * (GLITCH_INTERVAL_MAX_MS - GLITCH_INTERVAL_MIN_MS));
    };

    timeout = setTimeout(triggerGlitch, GLITCH_INITIAL_MIN_MS + Math.random() * (GLITCH_INITIAL_MAX_MS - GLITCH_INITIAL_MIN_MS));
    return () => {
      clearTimeout(timeout);
      clearTimeout(resetTimeout);
    };
  }, [powered]);

  /* Powered off: no content, just dark glass. */
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
        className="flex flex-col justify-start items-start text-glow"
        style={{
          fontFamily: "WarText, monospace",
          fontSize: "13px",
          lineHeight: "1.2",
          color: "var(--foreground)",
        }}
      >
        {lines.map((entry, index) => {
          const displayLine = truncateToVisibleLength(entry.text, COLS);
          const formatted = parseTerminalFormatting(displayLine);
          const isEmpty = entry.text === "";
          return (
            <div
              key={entry.key}
              ref={(element) => { lineRefsRef.current[index] = element; }}
              className="whitespace-pre overflow-hidden"
            >
              {isEmpty ? "\u00A0" : formatted}
              {index === lines.length - 1 && cursorVisible && (
                <span className="opacity-80">_</span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
