# Mouse Support

## Preface

TUIkit gains incremental mouse support for terminal apps, layered on top of the existing key-only input pipeline. Rollout is staged across three user-visible features: wheel scroll for `List`/`Table` (v1), click-to-focus and click-to-select for rows (v2), and generalized click dispatch for all focusable controls (v3). Keyboard behavior stays unchanged, render-loop performance is preserved, and mouse modes are guaranteed to be disabled on shutdown so no escape sequences leak into the parent shell.

## Specification / Goal

Deliver SGR-mouse-protocol support across macOS and Linux terminals with the following acceptance criteria:

- Apps run unchanged without mouse input (opt-in, no regressions).
- Mouse wheel scroll works reliably in focused `List`/`Table` on macOS and Linux.
- Click-to-focus and click-to-select work for `List`/`Table` rows.
- Generalized click dispatch reaches all focusable controls.
- No regressions in existing keyboard-driven tests.
- Mouse modes are always disabled on app shutdown (no escape leakage).

**Non-goals (v1):**

- No full generic hit-testing across every view type.
- No drag gestures.
- No double-click semantics.
- No pixel/graphics mode support (text terminal only).

**Constraints:**

- Swift 6.0 only.
- Cross-platform macOS + Linux.
- Keep keyboard behavior unchanged.
- Maintain current render-loop performance characteristics.

## Design

### Current State

- Input pipeline is key-only (`KeyEvent`), no mouse event model.
- `Terminal` enables bracketed paste only, not mouse reporting.
- `InputHandler` dispatch chain: status bar → view handlers → focus → default keys.
- Focus system has no coordinate-based APIs.
- `List`/`Table` already have robust scroll/focus handlers (`ItemListHandler`).

### Unified Event Model

Route mouse in parallel with existing key behavior:

- New `InputEvent` enum with `.key(KeyEvent)` and `.mouse(MouseEvent)`.
- `Terminal` gains mouse mode enable/disable and an SGR parser for `ESC [ < b ; x ; y M/m`.
- `InputHandler` gets a dedicated mouse branch with strict, staged behavior.
- A lightweight geometry registry is added for interactive surfaces, scoped to the phase that needs it.

### Core Types

```swift
public enum InputEvent: Sendable, Equatable {
    case key(KeyEvent)
    case mouse(MouseEvent)
}

public struct MouseEvent: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case down(MouseButton)
        case up(MouseButton)
        case drag(MouseButton)
        case scrollUp
        case scrollDown
    }
    public let kind: Kind
    public let row: Int
    public let column: Int
    public let shift: Bool
    public let alt: Bool
    public let ctrl: Bool
}
```

### Terminal Protocol Migration

- Add `readInputEvent() -> InputEvent?`.
- Keep `readKeyEvent()` temporarily as adapter: returns key when event is `.key`, returns `nil` for `.mouse`.
- Update `AppRunner` to consume `readInputEvent()`.

### Interaction Map (v2+)

Per-frame rebuilt registry lives in environment services. `_ListCore` and `Table` register row bounds during render. On left-click, the map resolves the hit, focuses the target, updates the selected row index, and toggles selection according to selection mode. Clicks on non-selectable rows (headers/footers) only focus the list/table without toggling selection.

### Risks and Mitigations

- **Terminal compatibility differences** → strict parser + graceful fallback to key-only behavior.
- **Performance overhead from hit map** → no hit map in v1; per-frame compact registry in v2+.
- **Behavior conflicts with focus/key pipeline** → keep event channels explicit; deterministic routing rules.

## Implementation

### Phase 1: Foundations (Event Model + Terminal Mouse Parsing) — M1 (1-2 days)

- Add `MouseEvent` and `MouseButton` types in `TUIkitCore/Input`.
- Add `InputEvent` wrapper type.
- Extend `TerminalProtocol` with `readInputEvent()` (keep `readKeyEvent()` for compatibility during migration).
- In `Terminal.enableRawMode()`, enable mouse tracking: `?1000h` (button press), `?1002h` (button drag report), `?1006h` (SGR extended coordinates).
- In `disableRawMode()`, disable the same modes.
- Implement the SGR parser. Normalize coordinates to 1-based terminal row/column; convert internally only where needed. Ignore unknown/partial mouse packets safely.

### Phase 2: v1 Feature — Wheel Scroll in List/Table — M2 (1 day)

- Extend input loop to consume `InputEvent`.
- Add mouse handling path in `InputHandler`.
- On wheel up/down: if the active focus section has an `ItemListHandler`, scroll it by a configurable step (default 3 rows).
- Keep selection/focus unchanged unless the list is not focused and policy says to auto-focus the list (configurable; default `false` in v1).
- Trigger rerender only when scroll offset changes.
- Add optional focus-manager API to expose the currently focused handler typed as `ItemListHandler` when available. Avoid global hit-testing in v1.

### Phase 3: v2 Feature — Click Focus + Row Selection for List/Table — M3 (2-3 days)

- Introduce `InteractionMap` (per-frame rebuilt registry) in environment services.
- Register row bounds from `_ListCore` / `Table` render path.
- On left-click: resolve row hit, focus corresponding list/table, update focused row index, toggle/select according to selection mode.
- Click on non-selectable rows only focuses the list/table, no selection toggle.
- Preserve keyboard navigation semantics after click.

### Phase 4: v3 Feature — Generic Click Dispatch — M4 (optional, 3+ days)

- Extend `InteractionMap` to button-like controls and other focusables.
- Add `onMouseEvent` registration API (internal first).
- Route clicks to control handlers before fallback logic.

### Testing Strategy

**Unit tests:**

- SGR parser: press/release/drag/wheel sequences, modifier flags (shift/alt/ctrl), malformed and partial sequences.
- `InputHandler` mouse routing: wheel changes scroll offset, no-op on unsupported targets, rerender triggered only on state change.

**Integration tests:**

- `List` with long content: wheel down/up changes visible range, bounds respected at top/bottom.
- `Table`: same coverage as list.
- Keyboard regression: existing key tests continue unchanged.

**Compatibility tests:**

- macOS terminal integration.
- Linux terminal integration.
- No mouse escape leakage on exit (modes disabled in cleanup).

### Rollout

- Internal feature flag (env/service level) during rollout.
- Default off for first merge if risk is high; switch on after stabilization.
- Document terminal prerequisites in docs (SGR mouse-capable terminal required).

## Checklist

### Phase 1: Foundations

- [ ] `MouseEvent` + `MouseButton` types in `TUIkitCore/Input`
- [ ] `InputEvent` wrapper type
- [ ] `TerminalProtocol.readInputEvent()` added
- [ ] `Terminal.enableRawMode()` enables `?1000h`, `?1002h`, `?1006h`
- [ ] `Terminal.disableRawMode()` disables mouse modes
- [ ] SGR parser implementation
- [ ] Parser unit tests (press/release/drag/wheel, modifiers, malformed)

### Phase 2: Wheel Scroll

- [ ] Input loop consumes `InputEvent`
- [ ] Mouse branch in `InputHandler`
- [ ] Wheel events dispatch to active `ItemListHandler`
- [ ] Configurable scroll step (default 3 rows)
- [ ] Focus-manager API exposes focused `ItemListHandler`
- [ ] Rerender only on scroll offset change
- [ ] `List` + `Table` integration tests

### Phase 3: Click Focus + Row Selection

- [ ] `InteractionMap` registry in environment services
- [ ] `_ListCore` registers row bounds
- [ ] `Table` registers row bounds
- [ ] Left-click resolves hit and focuses target
- [ ] Selection toggle respects selection mode
- [ ] Non-selectable rows focus only, no toggle
- [ ] Keyboard navigation parity after click

### Phase 4: Generic Click Dispatch

- [ ] `InteractionMap` covers button-like controls + focusables
- [ ] Internal `onMouseEvent` registration API
- [ ] Click routing precedes fallback logic

### Rollout + Compatibility

- [ ] Feature flag wired up
- [ ] macOS terminal verification
- [ ] Linux terminal verification
- [ ] Shutdown cleanup verified (no escape leakage)
- [ ] Docs updated with terminal prerequisites
