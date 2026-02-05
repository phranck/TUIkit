# Render Pipeline Optimization

## Completed

Phases 1–4 completed on 2026-02-02. All phases implemented across three branches:
- `refactor/render-pipeline-phase1` — Phase 1 (line-level diffing) + Phase 2 (output buffering) + CI fix. PR #62.
- `refactor/render-pipeline-phase3` — Phase 3 (caching). PR #63.
- `refactor/render-pipeline-phase4` — Phase 4 (architecture cleanup, renamed from "subtree memoization").

Note: The original Phase 4 (subtree memoization) was replaced with architecture cleanup. Subtree memoization remains a future project.

## Problem

Every frame in TUIKit reconstructs the entire view tree, re-renders every view into fresh FrameBuffers, and rewrites every terminal line — regardless of whether anything changed. This causes visible stuttering/jerkiness in animations (Spinner) and will get worse as the UI grows.

### Current per-frame cost (for a 30-view app on a 50-line terminal)

| Category | Count | Notes |
|---|---|---|
| View struct allocations | ~30 | Every view rebuilt from scratch |
| FrameBuffer allocations | ~15 | One per leaf + one per container |
| RenderContext copies | ~30 | Struct copy per tree traversal step |
| ViewIdentity string allocations | ~30 | String concatenation per identity |
| ANSI regex evaluations | ~100–200 | `strippedLength` + `width` calls |
| String allocations (terminal output) | ~150+ | Padding, bg replacement, concatenation |
| POSIX `write()` syscalls | ~100 | 50 cursor moves + 50 line writes |
| `ioctl()` syscalls | ~5 | Terminal size queries |
| **Total heap allocations** | **~400+** | Per frame, every 40ms |

### Root causes

1. **Full tree reconstruction** — `App.body` is evaluated every frame. Every view struct, TupleView, Stack, and modifier is created fresh. Every `@ViewBuilder` closure re-executes.
2. **Full screen repaint** — `WindowGroup.renderScene` writes every terminal line every frame via individual POSIX `write()` calls, even if nothing changed.
3. **Uncached computed properties** — `FrameBuffer.width` runs the ANSI regex on every line every time it's accessed. Called hundreds of times per frame.
4. **Uncached terminal size** — `terminal.width`/`height` call `ioctl()` every time (~5× per frame).
5. **No output buffering** — Each terminal line produces 2 `write()` syscalls (cursor move + content). No batching.
6. **Redundant string operations** — Every content line goes through regex stripping, `replacingOccurrences`, padding concatenation.

## Goal

Reduce per-frame work to only what actually changed. The render pipeline should:

1. Detect which terminal lines changed and only write those
2. Cache stable values (terminal size, FrameBuffer width)
3. Batch terminal output into a single write
4. (Future) Skip subtree rendering when inputs haven't changed

## Architecture

### What SwiftUI does (for reference)

SwiftUI maintains a persistent **Attribute Graph** that tracks dependencies between state and view bodies. When `@State` changes, only the dependent `body` properties are re-evaluated. A structural diff determines which subtrees changed. Only dirty screen regions are redrawn.

### What's applicable to TUIKit (incremental approach)

We adopt a **phased approach** — each phase is independently valuable and shippable:

1. **Phase 1: Line-level diffing** — highest ROI. Store previous frame, only write changed lines. Eliminates >90% of terminal writes for mostly-static UI.
2. **Phase 2: Output buffering** — batch all terminal output into one `write()` call.
3. **Phase 3: Caching** — cache `FrameBuffer.width`, terminal size, avoid redundant regex.
4. **Phase 4: Subtree memoization** — skip re-rendering subtrees whose inputs haven't changed.

Phase 1–3 are mechanical optimizations that don't change the architecture. Phase 4 is the structural change toward SwiftUI-style incremental rendering.

## Detailed Design

### Phase 1: Line-Level Diffing

**Concept:** After producing the new frame's FrameBuffer, compare each line with the previous frame. Only write lines that differ. For a mostly-static UI (e.g. menu + spinner), only 1–3 lines change per frame instead of 50+.

**Implementation:**

```swift
// In WindowGroup.renderScene() or RenderLoop
var previousFrame: [String] = []  // stored between frames

func writeFrame(_ buffer: FrameBuffer, terminal: Terminal) {
    let newLines = buildOutputLines(buffer)  // includes bg, padding, ANSI
    
    for row in 0..<terminalHeight {
        let newLine = row < newLines.count ? newLines[row] : emptyLine
        if row >= previousFrame.count || previousFrame[row] != newLine {
            terminal.moveCursor(toRow: 1 + row, column: 1)
            terminal.write(newLine)
        }
    }
    
    previousFrame = newLines
}
```

**Key decisions:**
- Compare the **final output strings** (with ANSI codes), not stripped text. This is a simple `==` comparison, O(1) amortized for equal strings (Swift uses hash-based comparison for long strings).
- Store `previousFrame` in `RenderLoop` (not global, injected via constructor — no singletons).
- On terminal resize (SIGWINCH), invalidate the entire previous frame to force a full repaint.
- The status bar gets its own `previousStatusBarLines` for independent diffing.

**Expected impact:** For a UI with a single animating Spinner and 45 static lines, this reduces terminal writes from ~100 to ~6 per frame (3 spinner lines × 2 writes each). **~94% reduction in syscalls.**

### Phase 2: Output Buffering

**Concept:** Instead of calling `terminal.write()` per line, accumulate all output into a single `[UInt8]` buffer and write once.

**Implementation:**

```swift
// New method on Terminal
func writeBuffered(_ chunks: [(row: Int, content: String)]) {
    var buffer: [UInt8] = []
    buffer.reserveCapacity(chunks.count * 120)  // estimate ~120 bytes per line
    
    for chunk in chunks {
        // Append cursor move escape sequence
        let move = "\u{1B}[\(chunk.row);1H"
        buffer.append(contentsOf: move.utf8)
        // Append content
        buffer.append(contentsOf: chunk.content.utf8)
    }
    
    buffer.withUnsafeBufferPointer { ptr in
        guard let base = ptr.baseAddress else { return }
        var written = 0
        while written < ptr.count {
            let result = Foundation.write(STDOUT_FILENO, base + written, ptr.count - written)
            if result <= 0 { break }
            written += result
        }
    }
}
```

**Key decisions:**
- Use `[UInt8]` not `String` to avoid repeated UTF-8 encoding.
- Single `write()` syscall instead of ~100.
- `reserveCapacity` to avoid array reallocations.
- Combines well with Phase 1: only changed lines go into the buffer.

**Expected impact:** Reduces POSIX `write()` syscalls from ~100 (or ~6 after Phase 1) to **1 per frame**. Eliminates per-line String→CString conversion overhead.

### Phase 3: Caching

Three independent caches:

#### 3a: Terminal size cache

```swift
// Terminal.swift
private var cachedSize: (width: Int, height: Int)?

var width: Int { (cachedSize ?? refreshSize()).width }
var height: Int { (cachedSize ?? refreshSize()).height }

func invalidateSize() { cachedSize = nil }  // called on SIGWINCH
private func refreshSize() -> (width: Int, height: Int) {
    var ws = winsize()
    ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)
    let size = (width: Int(ws.ws_col), height: Int(ws.ws_row))
    cachedSize = size
    return size
}
```

**Impact:** Eliminates ~5 `ioctl()` syscalls per frame.

#### 3b: FrameBuffer width cache

```swift
public struct FrameBuffer {
    public var lines: [String] {
        didSet { cachedWidth = nil }
    }
    private var cachedWidth: Int?
    
    public var width: Int {
        mutating get {
            if let cached = cachedWidth { return cached }
            let computed = lines.map { $0.strippedLength }.max() ?? 0
            cachedWidth = computed
            return computed
        }
    }
}
```

**Problem:** `FrameBuffer` is a value type. The `mutating get` won't work when accessed on a `let` binding. 

**Alternative:** Compute width eagerly in `appendVertically`/`appendHorizontally` and store it. Or use a reference-type wrapper for the cache.

**Better approach:** Store width as a simple stored property that is updated by the mutation methods. No computed property at all:

```swift
public struct FrameBuffer {
    public private(set) var lines: [String]
    public private(set) var width: Int
    
    mutating func appendVertically(_ other: FrameBuffer, spacing: Int = 0) {
        // ... existing logic ...
        width = max(width, other.width)
    }
}
```

**Impact:** Eliminates ~100–200 regex evaluations per frame. This is likely the single biggest CPU win after line diffing.

#### 3c: Pre-computed `strippedLength` on output lines

During `WindowGroup.renderScene`, each content line goes through `strippedLength` (regex) + `replacingOccurrences` + padding. We can pre-compute the stripped length when the FrameBuffer is built, avoiding the regex in the output phase entirely.

This is a natural extension of 3b — if `FrameBuffer` tracks `width`, individual line lengths could be tracked too.

### Phase 4: Subtree Memoization (Future)

**Concept:** If a view's inputs (state values, environment) haven't changed since the last frame, return the cached FrameBuffer without re-rendering the subtree.

**This is the hard problem.** It requires:
1. Tracking which `@State` values and environment keys each view reads
2. Comparing them across frames
3. Caching FrameBuffers keyed by ViewIdentity
4. Invalidating the cache when inputs change

**Sketch:**

```swift
func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    let identity = context.identity
    
    // Check if cached buffer is still valid
    if let cached = context.tuiContext.renderCache.get(identity),
       !context.tuiContext.stateStorage.hasChanges(for: identity) {
        return cached
    }
    
    // ... existing rendering logic ...
    
    let buffer = // ... result
    context.tuiContext.renderCache.set(identity, buffer: buffer)
    return buffer
}
```

**Dependency tracking approach:**
- `StateStorage` tracks a `changeGeneration` counter per `StateBox`. Incremented on every mutation.
- Each cached buffer stores the generation of every state it read.
- On the next frame, compare current generations with cached generations. If all match, reuse.

**This is a separate plan.** Phase 4 requires careful design and should be its own `plans/` file. Phases 1–3 should be shipped first.

## Implementation Plan

### Phase 1: Line-Level Diffing

- [x] 1. Add `previousContentLines: [String]` to `RenderLoop` (via `FrameDiffWriter`)
- [x] 2. Add `previousStatusBarLines: [String]` to `RenderLoop` (via `FrameDiffWriter`)
- [x] 3. Extract output line building into `FrameDiffWriter.buildOutputLines()`
- [x] 4. Add `writeContentDiff`/`writeStatusBarDiff` that compare and write only changed lines
- [x] 5. Invalidate on SIGWINCH via `FrameDiffWriter.invalidate()`
- [x] 6. Status bar diffing with separate previous-lines array

### Phase 2: Output Buffering

- [x] 7. Add `Terminal.beginFrame()`/`endFrame()` with `[UInt8]` frame buffer (16 KB pre-allocated)
- [x] 8. `Terminal.write()` transparently appends to buffer when buffering is active
- [x] 9. Single `write()` syscall per frame via `endFrame()` flush

### Phase 3: Caching

- [x] 10. Single `terminal.getSize()` call per frame in `RenderLoop.render()` (instead of 2 ioctl calls)
- [x] 11. `FrameBuffer.width` as stored `public private(set) var` with `didSet` recomputation
- [x] 12. All `FrameBuffer.width` call sites audited — all read-only, no external mutation
- [x] 13. `strippedLength` counts visible chars without intermediate string allocation

### Phase 4: Architecture Cleanup (replaced original "Subtree Memoization")

- [x] 14. Removed `terminal` from `RenderContext` (was never read after construction)
- [x] 15. `ViewRenderer` queries terminal size directly, documented as convenience-only
- [x] 16. `ChildInfo`/`ChildInfoProvider` extracted from `ViewRenderer.swift` into `ChildInfo.swift`

### Testing & Validation

- [x] 17. 13 tests for line diffing (`FrameDiffWriterTests.swift`)
- [x] 18. `FrameBuffer.width` caching validated by existing `FrameBufferTests` (all passing)
- [x] 19. 6 tests for output buffering (`TerminalOutputBufferTests.swift`)
- [x] 20. Spinner animation visually verified
- [x] 21. Full test suite: 455 tests in 79 suites, all passing

### Integration

- [x] 22. Updated `to-dos.md`, `whats-next.md`, `memory.md`
- [x] 23. Updated plan with completion status
- [x] 24. Updated DocC articles: `RenderCycle.md`, `AppLifecycle.md`, `StateManagement.md`

## Expected Impact

| Phase | What it eliminates | Estimated improvement |
|-------|---|---|
| Phase 1 | ~94% of terminal write syscalls for mostly-static UI | **Biggest visual improvement** — less flicker, smoother animations |
| Phase 2 | Remaining per-line syscall overhead | ~100 syscalls → 1 per frame |
| Phase 3a | ioctl syscalls | ~5 syscalls → 0 per frame (except resize) |
| Phase 3b | Regex evaluations for width | ~100–200 regex calls → 0 per frame |
| Phase 4 | Full subtree re-rendering | Proportional to % unchanged UI |

## Open Questions

1. **FrameBuffer as value type vs reference type?** Width caching is awkward with a value type (`mutating get` won't work on `let` bindings). Options: (a) stored `width` property updated by mutation methods, (b) switch to reference type (class), (c) internal `_Storage` class wrapper. Option (a) is simplest.

2. **String comparison cost for line diffing?** Swift Strings use UTF-8 storage. Equality check is O(N) in the worst case but O(1) for pointer-equal strings. Since we rebuild strings every frame, they won't be pointer-equal. For 50-line terminal with ~120 chars per line, that's ~6KB of comparison per frame — negligible.

3. **Status bar diffing separately or unified?** The status bar renders on its own pass with its own context. Keeping its diffing separate (own `previousLines`) is cleaner and avoids coupling.

4. **Should `buildOutputLines` handle the background color replacement?** Yes — this isolates the "raw FrameBuffer → terminal-ready strings" transformation into a testable pure function.
