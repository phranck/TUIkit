# TUIkit To-Dos

## In Progress

(none)

## Open

### High Priority

- [ ] **Render Cycle Documentation**: Create detailed Markdown doc explaining the complete render cycle from view tree to terminal output. Include Mermaid diagrams showing: view hierarchy traversal, FrameBuffer composition, HStack/VStack layout algorithm, modifier application order, environment propagation. Location: `docs/render-cycle.md`

### Medium Priority

- [ ] **DisclosureGroup**: Expandable/collapsible sections

### Low Priority

- [ ] **Fix Flaky Test**: FocusManager shared static instance issue

## Completed

### 2026-02-10
- TextCursor Modifier: `.textCursor(_:)` with shape (block, bar, underscore) and animation (none, blink, pulse), cursorColor in Palette (17 tests)

### 2026-02-09
- SecureField: password masking with ● bullets, reuses TextFieldHandler (15 tests)
- List SwiftUI API Parity: Section, badge, listStyle, selectionDisabled (45+ tests)
- Slider & Stepper with TrackStyle, keyboard controls, focus indicators (59 tests)
- TextField: text editing, cursor navigation, onSubmit, ViewBuilder label (37 tests)
- TrackStyle refactor from ProgressBarStyle, TrackRenderer utility
- View Architecture Refactor (all controls use `body: some View`)
- LazyVStack, LazyHStack for SwiftUI parity
- Performance: FrameBuffer, Stack rendering optimized (2-3x faster)

### 2026-02-08
- Alert horizontal buttons, ESC dismiss, ButtonRole (.cancel, .destructive)
- Left/Right arrow focus navigation, RenderLoop positioning fix

### 2026-02-07
- .foregroundStyle() renamed, List & Table with ItemListHandler

### 2026-02-06
- ContainerView refactor, List scrolling with viewport management

## Notes

- SwiftUI docs: `http://127.0.0.1:51703/Dash/dash-apple-api/load?request_key=ls/documentation/swiftui`

---
**Last Updated:** 2026-02-10 (Render Cycle Docs added)
