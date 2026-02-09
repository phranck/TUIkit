import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { useCopyToClipboard } from "../../hooks/useCopyToClipboard";

const CODE = `import TUIkit

struct ContentView: View {
    @State private var count = 0
    @State private var selected: String?

    var body: some View {
        VStack {
            Spacer()

            Text("Welcome to TUIkit")
                .bold()
                .foregroundStyle(.palette.accent)
                .padding(.bottom)

            HStack {
                Button("Increment") { count += 1 }
                Text("Count: \\(count)")
            }

            Spacer()

            List("Items", selection: $selected) {
                ForEach(["Alpha", "Beta", "Gamma", "Delta"], id: \\.self) { item in
                    Text(item)
                }
            }
            .frame(width: 21)

            Spacer()
            Spacer()
        }
        .padding()
        .appHeader {
            HStack {
                Text("My TUIkit App").bold()
                Spacer()
                Text("v1.0")
            }
        }
        .statusBarSystemItems(
            theme: true,
            appearance: true
        )
    }
}`;

/** A Swift code block with copy-to-clipboard, preview overlay, and minimal syntax highlighting. */
export default function CodePreview() {
  const { copied, copy } = useCopyToClipboard();
  const [showPreview, setShowPreview] = useState(false);
  const [isVisible, setIsVisible] = useState(false);

  // Handle ESC key to close preview
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && showPreview) {
        closePreview();
      }
    };
    
    if (showPreview) {
      document.addEventListener("keydown", handleKeyDown);
      // Trigger fade-in after mount
      requestAnimationFrame(() => setIsVisible(true));
    }
    
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [showPreview]);

  const openPreview = () => {
    setShowPreview(true);
  };

  const closePreview = () => {
    setIsVisible(false);
    // Wait for fade-out animation before removing from DOM
    setTimeout(() => setShowPreview(false), 200);
  };

  // Render overlay in a portal to escape overflow:hidden
  const overlay = showPreview && typeof document !== "undefined" 
    ? createPortal(
        <div
          className={`fixed inset-0 z-50 flex items-center justify-center cursor-pointer transition-all duration-300 ease-out ${
            isVisible ? "backdrop-blur-md" : "backdrop-blur-0"
          }`}
          onClick={closePreview}
        >
          <div 
            className={`relative max-w-6xl max-h-[95vh] p-4 transition-all duration-300 ease-out ${
              isVisible ? "opacity-100 scale-100" : "opacity-0 scale-75"
            }`}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="relative">
              <img
                src="/images/preview.png"
                alt="Terminal preview of the code example"
                className="max-h-[90vh] w-auto"
              />
              <div className="absolute bottom-[108px] left-0 right-0 flex justify-center">
                <p className="text-lg text-foreground bg-black/30 px-6 py-3 rounded-lg">The executed code running in Terminal</p>
              </div>
            </div>
          </div>
        </div>,
        document.body
      )
    : null;

  return (
    <>
      {overlay}
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
        <div className="flex items-center gap-2">
          <button
            onClick={openPreview}
            className="rounded-md px-2.5 py-1 text-xs text-muted transition-colors hover:bg-foreground/5 hover:text-foreground focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background"
            aria-label="Show terminal preview"
          >
            Preview
          </button>
          <button
            onClick={() => copy(CODE)}
            className="rounded-md px-2.5 py-1 text-xs text-muted transition-colors hover:bg-foreground/5 hover:text-foreground focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background"
          >
            {copied ? "Copied!" : "Copy"}
          </button>
        </div>
      </div>

      {/* Code content: max 21 lines visible, scroll for rest */}
      <pre className="overflow-auto p-5 text-base leading-relaxed" style={{ maxHeight: "calc(21 * 1.625em + 2.5rem)" }}>
        <code>
          <Highlight code={CODE} showLineNumbers />
        </code>
      </pre>
      </div>
    </>
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
function Highlight({ code, showLineNumbers = false }: { code: string; showLineNumbers?: boolean }) {
  const lines = code.split("\n");
  const lineNumberWidth = String(lines.length).length;

  return (
    <>
      {lines.map((line, lineIndex) => (
        <span key={lineIndex} className="flex">
          {showLineNumbers && (
            <span 
              className="select-none pr-4 text-right text-muted/40"
              style={{ minWidth: `${lineNumberWidth + 1}ch` }}
            >
              {lineIndex + 1}
            </span>
          )}
          <span className="flex-1">
            {tokenizeLine(line)}
            {lineIndex < lines.length - 1 && "\n"}
          </span>
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
    /(@\w+)|("(?:[^"\\]|\\.)*")|(\\\.self)|(\.\w+)\(|\b(struct|var|some|func|import|let|return|if|else|for|in|while|switch|case|default|class|protocol|enum|init|self|true|false|nil|private|public|internal|isOn|label|shortcut|id)\b|\b(App|Scene|WindowGroup|VStack|HStack|Text|Button|View|String|Int|Bool|Never|Toggle|List|ForEach|State|StatusBarItem)\b/g;

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
      // KeyPath (\.self)
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.modifier }}>
          {match[3]}
        </span>
      );
    } else if (match[4]) {
      // Modifier (.bold, .foregroundColor): add dot+name, then the ( back
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.modifier }}>
          {match[4]}
        </span>
      );
      parts.push("(");
    } else if (match[5]) {
      // Keyword
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.keyword }}>
          {match[5]}
        </span>
      );
    } else if (match[6]) {
      // Type
      parts.push(
        <span key={match.index} style={{ color: HIGHLIGHT.type }}>
          {match[6]}
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
