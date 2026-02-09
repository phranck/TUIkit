# TUIkit To-Dos

## In Progress

- [ ] **List SwiftUI API Parity**: Section, .badge(), .listStyle(), .selectionDisabled(), .alternatingRowBackgrounds()

## Open

### High Priority

- [ ] **SecureField**: Password input with masking (builds on TextField)

### Medium Priority

- [ ] **DisclosureGroup**: Expandable/collapsible sections

### Low Priority

- [ ] **Fix Flaky Test**: "Default FocusManager is provided if not set" fails due to shared static instance

## Completed

### 2026-02-09
- TextField complete: full text editing, cursor navigation, onSubmit, ViewBuilder label, Example app demo page (37 tests)
- View Architecture Refactor complete (all controls use `body: some View`)
- LazyVStack, LazyHStack added for SwiftUI parity
- Performance: FrameBuffer, Stack rendering, ANSI string operations optimized (2-3x faster)
- Removed unused regex (dead code cleanup)

### 2026-02-08
- Alert horizontal button layout, ESC dismiss, max width 60 chars
- ButtonRole (.cancel, .destructive) with SwiftUI-conformant API
- Left/Right arrow focus navigation
- RenderLoop content positioning fix (actualHeaderHeight)
- VStack default alignment fix in Example App pages

### 2026-02-07
- .foregroundColor() renamed to .foregroundStyle()
- List & Table with ItemListHandler, focus bar, F-keys

### 2026-02-06
- ContainerView refactor with shared renderContainer()
- List scrolling with viewport management

### 2026-02-03
- Focus Sections with StatusBar cascading
- Breathing dot indicator, PulseTimer

## Notes

- SwiftUI docs available locally: `http://127.0.0.1:51703/Dash/dash-apple-api/load?request_key=ls/documentation/swiftui`
- Always check SwiftUI signature before implementing new APIs

---

**Last Updated:** 2026-02-09
