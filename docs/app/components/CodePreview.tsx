"use client";

import { useState } from "react";

/** A Swift code block with copy-to-clipboard and minimal syntax highlighting. */
export default function CodePreview() {
  const [copied, setCopied] = useState(false);

  const code = `import TUIkit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Hello, TUIkit!")
                    .bold()
                    .foregroundColor(.cyan)
                Button("Press me") {
                    // handle action
                }
            }
        }
    }
}`;

  const handleCopy = async () => {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      className="group relative w-full overflow-hidden rounded-xl border border-border backdrop-blur-xl"
      style={{ backgroundColor: "color-mix(in srgb, var(--container-body) 50%, transparent)" }}
    >
      {/* Header bar */}
      <div className="flex items-center justify-between border-b border-border px-4 py-2.5">
        <div className="flex items-center gap-2">
          <div className="flex gap-1.5">
            <div className="h-3 w-3 rounded-full bg-[#ff5f57]" />
            <div className="h-3 w-3 rounded-full bg-[#febc2e]" />
            <div className="h-3 w-3 rounded-full bg-[#28c840]" />
          </div>
          <span className="ml-3 text-xs text-muted">MyApp.swift</span>
        </div>
        <button
          onClick={handleCopy}
          className="rounded-md px-2.5 py-1 text-xs text-muted transition-colors hover:bg-white/5 hover:text-foreground"
        >
          {copied ? "Copied!" : "Copy"}
        </button>
      </div>

      {/* Code content */}
      <pre className="overflow-x-auto p-5 text-base leading-relaxed">
        <code>
          <Highlight code={code} />
        </code>
      </pre>
    </div>
  );
}

/** Minimal Swift syntax highlighter — no external dependency. */
function Highlight({ code }: { code: string }) {
  const keywords =
    /\b(struct|var|some|func|import|let|return|if|else|for|in|while|switch|case|default|class|protocol|enum|init|self|true|false|nil|private|public|internal)\b/g;
  const decorators = /(@\w+)/g;
  const types = /\b(App|Scene|WindowGroup|VStack|HStack|Text|Button|View|String|Int|Bool|Never)\b/g;
  const strings = /("(?:[^"\\]|\\.)*")/g;
  const comments = /(\/\/.*$)/gm;
  const modifiers = /(\.\w+\()/g;

  const lines = code.split("\n");

  return (
    <>
      {lines.map((line, lineIndex) => (
        <span key={lineIndex}>
          {tokenizeLine(line, {
            keywords,
            decorators,
            types,
            strings,
            comments,
            modifiers,
          })}
          {lineIndex < lines.length - 1 && "\n"}
        </span>
      ))}
    </>
  );
}

interface Patterns {
  keywords: RegExp;
  decorators: RegExp;
  types: RegExp;
  strings: RegExp;
  comments: RegExp;
  modifiers: RegExp;
}

function tokenizeLine(line: string, patterns: Patterns) {
  // Comments take precedence
  const commentMatch = line.match(/^(.*?)(\/\/.*)$/);
  if (commentMatch) {
    const [, before, comment] = commentMatch;
    return (
      <>
        {tokenizeSegment(before, patterns)}
        <span className="text-[#6a737d]">{comment}</span>
      </>
    );
  }
  return tokenizeSegment(line, patterns);
}

function tokenizeSegment(segment: string, patterns: Patterns) {
  // Build a combined regex for all token types
  const combined =
    /(@\w+)|("(?:[^"\\]|\\.)*")|(\.\w+)\(|\b(struct|var|some|func|import|let|return|if|else|for|in|while|switch|case|default|class|protocol|enum|init|self|true|false|nil|private|public|internal)\b|\b(App|Scene|WindowGroup|VStack|HStack|Text|Button|View|String|Int|Bool|Never)\b/g;

  const parts: React.ReactNode[] = [];
  let lastIndex = 0;
  let match: RegExpExecArray | null;

  // Reset pattern state
  combined.lastIndex = 0;

  while ((match = combined.exec(segment)) !== null) {
    // Add text before match
    if (match.index > lastIndex) {
      parts.push(segment.slice(lastIndex, match.index));
    }

    if (match[1]) {
      // Decorator (@main, @State)
      parts.push(
        <span key={match.index} className="text-[#d19a66]">
          {match[1]}
        </span>
      );
    } else if (match[2]) {
      // String literal
      parts.push(
        <span key={match.index} className="text-[#98c379]">
          {match[2]}
        </span>
      );
    } else if (match[3]) {
      // Modifier (.bold, .foregroundColor) — add dot+name, then the ( back
      parts.push(
        <span key={match.index} className="text-[#61afef]">
          {match[3]}
        </span>
      );
      parts.push("(");
    } else if (match[4]) {
      // Keyword
      parts.push(
        <span key={match.index} className="text-[#c678dd]">
          {match[4]}
        </span>
      );
    } else if (match[5]) {
      // Type
      parts.push(
        <span key={match.index} className="text-[#e5c07b]">
          {match[5]}
        </span>
      );
    }

    lastIndex = combined.lastIndex;
  }

  // Remaining text
  if (lastIndex < segment.length) {
    parts.push(segment.slice(lastIndex));
  }

  return <>{parts}</>;
}
