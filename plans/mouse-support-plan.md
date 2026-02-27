# TUIkit Mouse Support Plan

## Goal
Add incremental mouse support for terminal apps built with TUIkit, prioritizing low-risk value first:
1. v1: mouse wheel scroll for `List`/`Table` in active focus section.
2. v2: click-to-focus and click-to-select for `List`/`Table` rows.
3. v3: generalized click dispatch for all focusable controls.

## Non-Goals (for v1)
- No full generic hit-testing across every view type.
- No drag gestures.
- No double-click semantics.
- No pixel/graphics mode support (text terminal only).

## Constraints
- Swift 6.0 only.
- Cross-platform macOS + Linux.
- Keep keyboard behavior unchanged.
- Maintain current render-loop performance characteristics.

## Current State (Code Reality)
- Input pipeline is key-only (`KeyEvent`), no mouse event model.
- `Terminal` enables bracketed paste only, not mouse reporting.
- `InputHandler` dispatch chain is status bar -> view handlers -> focus -> default keys.
- Focus system has no coordinate-based APIs.
- `List`/`Table` already have robust scroll/focus handlers (`ItemListHandler`).

## Design Overview
Introduce a unified event model and route mouse in parallel with existing key behavior:
- New `InputEvent` enum with `.key(KeyEvent)` and `.mouse(MouseEvent)`.
- Terminal adds mouse mode enable/disable and parsing for SGR mouse protocol (`ESC [ < b ; x ; y M/m`).
- `InputHandler` gains mouse branch with strict, staged behavior.
- Add lightweight geometry registry for interactive surfaces as needed by phase.

## Phase Plan

### Phase 1: Foundations (Event Model + Terminal Mouse Parsing)
Deliverables:
- Add `MouseEvent` and `MouseButton` types in `TUIkitCore/Input`.
- Add `InputEvent` wrapper type.
- Extend `TerminalProtocol` with `readInputEvent()` (keep `readKeyEvent()` for compatibility during migration).
- In `Terminal.enableRawMode()`, enable mouse tracking:
  - `?1000h` (button press)
  - `?1002h` (button drag report)
  - `?1006h` (SGR extended coordinates)
- In `disableRawMode()`, disable same modes.
- Implement parser for SGR mouse sequences into `MouseEvent`.

Notes:
- Normalize coordinates to 1-based terminal row/column first, convert internally only where needed.
- Ignore unknown/unsupported mouse packets safely.

### Phase 2: v1 Feature (Wheel Scroll in List/Table)
Deliverables:
- Extend input loop to consume `InputEvent`.
- Add mouse handling path in `InputHandler`.
- For wheel up/down events:
  - If active focus section has an `ItemListHandler`, scroll it by configurable step (default 3 rows).
  - Keep selection/focus unchanged unless list is not focused and policy says to auto-focus list (configurable; default false in v1).
- Trigger rerender only when scroll offset changes.

Implementation option (recommended):
- Add optional focus-manager API to expose currently focused handler typed as `ItemListHandler` when available.
- Avoid introducing global hit-testing in v1.

### Phase 3: v2 Feature (Click Focus + Row Selection for List/Table)
Deliverables:
- Introduce `InteractionMap` (per-frame rebuilt registry) in environment services.
- Register row bounds from `_ListCore` / `Table` render path.
- On left-click:
  - resolve row hit
  - focus corresponding list/table
  - update focused row index
  - toggle/select according to selection mode

Rules:
- Click on non-selectable rows (headers/footers) only focuses list/table, no selection toggle.
- Preserve keyboard navigation semantics after click.

### Phase 4: v3 Feature (Generic Click Dispatch)
Deliverables:
- Extend `InteractionMap` to button-like controls and other focusables.
- Add `onMouseEvent` registration API (internal first).
- Route clicks to control handlers before fallback logic.

## API Sketch

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
- Keep `readKeyEvent()` temporarily as adapter:
  - returns key when event is `.key`
  - returns `nil` for mouse.
- Update `AppRunner` to consume `readInputEvent()`.

## Testing Strategy

### Unit Tests
- Mouse parser coverage:
  - SGR press/release/drag/wheel sequences.
  - Modifier flags (shift/alt/ctrl).
  - malformed and partial sequences.
- InputHandler mouse routing:
  - wheel changes scroll offset.
  - no-op on unsupported targets.
  - rerender triggered only on state change.

### Integration Tests
- `List` with long content:
  - wheel down/up changes visible range.
  - bounds respected at top/bottom.
- `Table` same as list.
- Keyboard regression:
  - existing key tests continue unchanged.

### Compatibility Tests
- macOS terminal integration.
- Linux terminal integration.
- Ensure no mouse escape leakage on exit (modes disabled in cleanup).

## Rollout and Flags
- Add internal feature flag (env/service level) for mouse support during rollout.
- Default off for first merge if risk is high; switch on after stabilization.
- Document terminal prerequisites in docs (requires SGR mouse-capable terminal).

## Risks and Mitigations
- Risk: terminal compatibility differences.
  - Mitigation: strict parser + graceful fallback to key-only behavior.
- Risk: performance overhead from hit map.
  - Mitigation: no hit map in v1; per-frame compact registry in v2+.
- Risk: behavior conflicts with focus/key pipeline.
  - Mitigation: keep event channels explicit and prioritize deterministic routing rules.

## Proposed Milestones
1. M1 (1-2 days): Input model + terminal mouse mode + parser + tests.
2. M2 (1 day): v1 wheel scroll for list/table + tests.
3. M3 (2-3 days): v2 click focus/select with interaction map + tests.
4. M4 (optional, 3+ days): generalized control clicking.

## Acceptance Criteria
- App runs unchanged without mouse input.
- Mouse wheel scroll works reliably in focused `List`/`Table` on macOS and Linux.
- No regressions in existing keyboard-driven tests.
- Mouse modes are always disabled on app shutdown.
