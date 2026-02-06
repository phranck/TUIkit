"use client";

import { useCopyToClipboard } from "../hooks/useCopyToClipboard";

const CODE = `import TUIkit

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

/** A Swift code block with copy-to-clipboard and minimal syntax highlighting. */
export default function CodePreview() {
  const { copied, copy } = useCopyToClipboard();

  return (
    <div
      className="group relative w-full overflow-hidden rounded-xl border border-border bg-frosted-glass backdrop-blur-xl"
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
          onClick={() => copy(CODE)}
          className="rounded-md px-2.5 py-1 text-xs text-muted transition-colors hover:bg-foreground/5 hover:text-foreground focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background"
        >
          {copied ? "Copied!" : "Copy"}
        </button>
      </div>

      {/* Code content */}
      <pre className="overflow-x-auto p-5 text-base leading-relaxed">
        <code>
          <Highlight code={CODE} />
        </code>
      </pre>
    </div>
  );
}

/** Syntax highlight color palette: One Dark inspired. */
const HIGHLIGHT = {
  comment: "#6a737d",
  decorator: "#d19a66",
  string: "#98c379",
  modifier: "#61afef",
  keyword: "#c678dd",
  type: "#e5c07b",
} as const;

/** Minimal Swift syntax highlighter: no external dependency. */
function Highlight({ code }: { code: string }) {
  const lines = code.split("\n");

  return (
    <>
      {lines.map((line, lineIndex) => (
        <span key={lineIndex}>
          {tokenizeLine(line)}
          {lineIndex < lines.length - 1 && "\n"}
        </span>
      ))}
    </>
  );
}

function tokenizeLine(line: string) {
  // Comments take precedence
  const commentMatch = line.match(/^(.*?)(\/\/.*)$/);
  if (commentMatch) {
    const [, before, comment] = commentMatch;
    return (
      <>
        {tokenizeSegment(before)}
        <span style={{ color: HIGHLIGHT.comment }}>{comment}</span>
      </>
    );
  }
  return tokenizeSegment(line);
}

function tokenizeSegment(segment: string) {
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
        <span key={match.index} style={{ color: HIGHLIGHT.decorator }}>
          {match[1]}
        </span>
      );
    } else if (match[2]) {
      // String literal
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.string }}>
          {match[2]}
        </span>
      );
    } else if (match[3]) {
      // Modifier (.bold, .foregroundColor): add dot+name, then the ( back
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.modifier }}>
          {match[3]}
        </span>
      );
      parts.push("(");
    } else if (match[4]) {
      // Keyword
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.keyword }}>
          {match[4]}
        </span>
      );
    } else if (match[5]) {
      // Type
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.type }}>
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
