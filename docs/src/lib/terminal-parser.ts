/**
 * Parser for terminal-script.md
 * 
 * Converts markdown terminal script into executable sequences.
 * Supports basic Markdown formatting:
 * - **bold** → \x1B[1m
 * - __underline__ → \x1B[4m
 * - ~~strikethrough~~ → \x1B[9m
 * - *italic* → \x1B[3m
 */

import fs from "fs";
import path from "path";

/**
 * Convert Markdown formatting to HTML-like tags for terminal display.
 * These will be rendered by TerminalScreen component.
 * Supports: bold, underline, strikethrough, italic
 * 
 * Important: Only matches if there's actual text content between markers,
 * not just repeated special chars (e.g., ******** for password masking)
 */
function parseMarkdownFormatting(text: string): string {
  let result = text;
  
  // Skip formatting if line contains only special characters (like ********)
  if (/^[*_~\s]+$/.test(text)) {
    return text;
  }
  
  // Process in order, being careful not to match literal asterisks
  
  // **bold** → <b>bold</b>
  // Only match if:
  // - Content has at least one non-* character
  // - NOT preceded or followed by another * (to avoid matching *** as bold)
  result = result.replace(/(?<!\*)\*\*([^*]+?)\*\*(?!\*)/g, '<b>$1</b>');
  
  // __underline__ → <u>underline</u>
  // Matches content between __ and __, including spaces
  // Only match if content has at least one word character
  result = result.replace(/__([^_]+?)__/g, '<u>$1</u>');
  
  // ~~strikethrough~~ → <s>strikethrough</s>
  // Only match if content has at least one non-~ character
  result = result.replace(/~~([^~]+?)~~/g, '<s>$1</s>');
  
  // *italic* - process last, very carefully
  // Match single * that:
  // - Is preceded by whitespace or start of string (to avoid ** and ***)
  // - Is followed by whitespace or end of string (to avoid ** and ***)
  // - Content starts with word character (to avoid matching *** or ****)
  result = result.replace(/(^|\s)\*(\w[^\*]*?\w)\*(\s|$)/g, '$1<i>$2</i>$3');
  
  return result;
}

export interface BootStep {
  type: "instant" | "type" | "counter" | "pause" | "clear" | "dots";
  text?: string;
  prefix?: string;
  target?: number;
  suffix?: string;
  dotCount?: number;
  delayAfter?: number;
}

export interface SchoolStep {
  type: "system" | "user" | "inline" | "pause" | "clear";
  prompt?: string;
  text?: string;
  delayAfter?: number;
}

export interface JoshuaStep {
  type: "system" | "user" | "pause" | "clear" | "barrage";
  text?: string;
  delayAfter?: number;
}

export interface TerminalEntry {
  prompt: string;
  command: string;
  output: string[];
}

export interface TerminalScript {
  config: {
    initialCursorDelay: number;
    schoolTrigger: number;
    joshuaTrigger: number;
    typeMin: number;
    typeMax: number;
    pauseBeforeOutput: number;
    pauseAfterOutput: number;
  };
  bootSequence: BootStep[];
  schoolSequence: SchoolStep[];
  joshuaSequence: JoshuaStep[];
  unixCommands: TerminalEntry[];
}

/**
 * Parse a single line from the script.
 * Format: [TYPE] content
 * Delay: [DELAY 1200ms]
 */
function parseLine(line: string): { type: string; content: string; delay?: number } | null {
  const trimmed = line.trim();
  
  // Parse delay
  const delayMatch = trimmed.match(/^\[DELAY (\d+)ms\]$/);
  if (delayMatch) {
    return { type: "DELAY", content: "", delay: parseInt(delayMatch[1], 10) };
  }
  
  // Parse command
  const commandMatch = trimmed.match(/^\[(\w+)\]\s*(.*)$/);
  if (commandMatch) {
    const [, type, content] = commandMatch;
    return { type, content };
  }
  
  return null;
}

/**
 * Parse boot sequence from markdown content.
 */
function parseBootSequence(content: string): BootStep[] {
  const steps: BootStep[] = [];
  const lines = content.split("\n");
  let i = 0;
  
  while (i < lines.length) {
    const parsed = parseLine(lines[i]);
    if (!parsed) {
      i++;
      continue;
    }
    
    const step: Partial<BootStep> = {};
    
    switch (parsed.type) {
      case "INSTANT":
        step.type = "instant";
        step.text = parseMarkdownFormatting(parsed.content);
        break;
      case "TYPE":
        step.type = "type";
        step.text = parseMarkdownFormatting(parsed.content);
        break;
      case "COUNTER":
        step.type = "counter";
        // Format: "Memory Test: 0 → 4096K OK" or "Memory Test:  0 → 4096K OK"
        // Keep spacing between prefix and "0"
        const counterMatch = parsed.content.match(/^(.*?\s+)0\s*→\s*(\d+)(.*)$/);
        if (counterMatch) {
          step.prefix = parseMarkdownFormatting(counterMatch[1]);
          step.target = parseInt(counterMatch[2], 10);
          step.suffix = parseMarkdownFormatting(counterMatch[3]);
        }
        break;
      case "DOTS":
        step.type = "dots";
        // Format: "Detecting drives..."
        const dotsMatch = parsed.content.match(/^(.*?)(\.+)$/);
        if (dotsMatch) {
          step.text = parseMarkdownFormatting(dotsMatch[1]);
          step.dotCount = dotsMatch[2].length;
        } else {
          step.text = parseMarkdownFormatting(parsed.content);
          step.dotCount = 3;
        }
        break;
      case "CLEAR":
        step.type = "clear";
        break;
      case "PAUSE":
        step.type = "pause";
        break;
      case "DELAY":
        // Apply delay to previous step
        if (steps.length > 0) {
          steps[steps.length - 1].delayAfter = parsed.delay;
        }
        i++;
        continue;
    }
    
    steps.push(step as BootStep);
    i++;
  }
  
  return steps;
}

/**
 * Parse school sequence from markdown content.
 */
function parseSchoolSequence(content: string): SchoolStep[] {
  const steps: SchoolStep[] = [];
  const lines = content.split("\n");
  let i = 0;
  
  while (i < lines.length) {
    const parsed = parseLine(lines[i]);
    if (!parsed) {
      i++;
      continue;
    }
    
    const step: Partial<SchoolStep> = {};
    
    switch (parsed.type) {
      case "SYSTEM":
        step.type = "system";
        step.text = parseMarkdownFormatting(parsed.content);
        break;
      case "USER":
        step.type = "user";
        step.text = parseMarkdownFormatting(parsed.content);
        break;
      case "INLINE":
        step.type = "inline";
        // Format: "USER: DABNEY"
        const inlineMatch = parsed.content.match(/^(.*?:\s*)(.*)$/);
        if (inlineMatch) {
          step.prompt = parseMarkdownFormatting(inlineMatch[1]);
          step.text = parseMarkdownFormatting(inlineMatch[2]);
        }
        break;
      case "CLEAR":
        step.type = "clear";
        break;
      case "PAUSE":
        step.type = "pause";
        break;
      case "DELAY":
        if (steps.length > 0) {
          steps[steps.length - 1].delayAfter = parsed.delay;
        }
        i++;
        continue;
    }
    
    steps.push(step as SchoolStep);
    i++;
  }
  
  return steps;
}

/**
 * Parse Joshua sequence from markdown content.
 */
function parseJoshuaSequence(content: string): JoshuaStep[] {
  const steps: JoshuaStep[] = [];
  const lines = content.split("\n");
  let i = 0;
  
  while (i < lines.length) {
    const parsed = parseLine(lines[i]);
    if (!parsed) {
      i++;
      continue;
    }
    
    const step: Partial<JoshuaStep> = {};
    
    switch (parsed.type) {
      case "SYSTEM":
        step.type = "system";
        step.text = parseMarkdownFormatting(parsed.content);
        break;
      case "USER":
        step.type = "user";
        // Remove "> " prefix if present, then apply formatting
        step.text = parseMarkdownFormatting(parsed.content.replace(/^>\s*/, ""));
        break;
      case "BARRAGE":
        step.type = "barrage";
        break;
      case "CLEAR":
        step.type = "clear";
        break;
      case "PAUSE":
        step.type = "pause";
        break;
      case "DELAY":
        if (steps.length > 0) {
          steps[steps.length - 1].delayAfter = parsed.delay;
        }
        i++;
        continue;
    }
    
    steps.push(step as JoshuaStep);
    i++;
  }
  
  return steps;
}

/**
 * Parse UNIX commands from markdown content.
 */
function parseUnixCommands(content: string): TerminalEntry[] {
  const commands: TerminalEntry[] = [];
  const blocks = content.split("```terminal\n").slice(1);
  
  for (const block of blocks) {
    const lines = block.split("\n```")[0].split("\n");
    if (lines.length === 0) continue;
    
    const firstLine = lines[0];
    const promptMatch = firstLine.match(/^(\$|#)\s+(.+)$/);
    if (!promptMatch) continue;
    
    const prompt = promptMatch[1];
    const command = parseMarkdownFormatting(promptMatch[2]);
    const output = lines.slice(1)
      .filter(line => line.trim() !== "")
      .map(line => parseMarkdownFormatting(line));
    
    commands.push({ prompt, command, output });
  }
  
  return commands;
}

/**
 * Parse the complete terminal script markdown file.
 */
export function parseTerminalScript(): TerminalScript {
  const scriptPath = path.join(process.cwd(), "terminal-script.md");
  const content = fs.readFileSync(scriptPath, "utf-8");
  
  // Extract sections
  const bootMatch = content.match(/## Boot Sequence\s*```terminal\n([\s\S]*?)\n```/);
  const schoolMatch = content.match(/## School Computer Scene[\s\S]*?```terminal\n([\s\S]*?)\n```/);
  const joshuaMatch = content.match(/## Joshua\/WOPR Scene[\s\S]*?### First Contact([\s\S]*?)## UNIX Command Pool/);
  const unixMatch = content.match(/## UNIX Command Pool([\s\S]*?)## Special Effects/);
  
  // Parse config
  const config = {
    initialCursorDelay: 1500,
    schoolTrigger: 12,
    joshuaTrigger: 12,
    typeMin: 40,
    typeMax: 80,
    pauseBeforeOutput: 400,
    pauseAfterOutput: 1200,
  };
  
  // Parse sequences
  const bootSequence = bootMatch ? parseBootSequence(bootMatch[1]) : [];
  const schoolSequence = schoolMatch ? parseSchoolSequence(schoolMatch[1]) : [];
  const joshuaSequence = joshuaMatch ? parseJoshuaSequence(joshuaMatch[1]) : [];
  const unixCommands = unixMatch ? parseUnixCommands(unixMatch[1]) : [];
  
  return {
    config,
    bootSequence,
    schoolSequence,
    joshuaSequence,
    unixCommands,
  };
}
