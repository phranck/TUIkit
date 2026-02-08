# Badge & ListStyle Implementation (List SwiftUI API Parity Phase 2)

## Preface

This plan implements the second phase of SwiftUI API Parity for List: the `.badge()` modifier and `.listStyle()` support. Badge adds decorative count/label badges to list rows (Int, Text, String overloads). ListStyle enables PlainListStyle and InsetGroupedListStyle to control borders, padding, and row appearance. Both integrate via TUIkit's environment system and follow existing pattern conventions. Section integration is deferred to Phase 3.

---

## Context

### Current State
- **Section view** (Phase 1): Complete - SwiftUI-conformant with header/content/footer
- **List + Table**: Working with ItemListHandler, but no style control
- **Environment system**: PaletteKey/AppearanceKey patterns established
- **Modifiers**: Both ViewModifier and View wrapper patterns exist in codebase
- **Tests**: 682 passing / 108 suites

### Architecture Constraints (Non-negotiable)
1. **100% SwiftUI API Parity**: Parameter names, order, types must match exactly
2. **Environment propagation**: Modifiers must flow through RenderContext
3. **Swift 6.0 compatible**: No newer compiler features
4. **Cross-platform**: macOS + Linux (CI validates)
5. **Pre-commit**: `swift build` + `swiftlint` must pass

### Relevant SwiftUI APIs
**Badge overloads:**
```swift
func badge(_ count: Int) -> some View  // 0 hides badge
func badge(_ label: Text?) -> some View  // nil hides
func badge<S>(_ label: S?) -> some View where S: StringProtocol  // nil hides
```

**ListStyle protocol (standard):**
- Conformers: PlainListStyle, InsetListStyle, InsetGroupedListStyle, etc.
- Not protocol-based in our codebase; will use struct + environment key

---

## Specification / Goal

### Phase 2a: Badge Modifier
1. Store badge value (Int/Text/String) in environment via BadgeKey
2. Create three overloaded `.badge()` extensions on View
3. Render badge in List row rendering (right-aligned, dimmed color)
4. Add tests for all overloads and edge cases (0 value, nil, string)

### Phase 2b: ListStyle System
1. Create `ListStyle` protocol with style properties (borders, padding, alternating rows)
2. Implement `PlainListStyle` (no borders) and `InsetGroupedListStyle` (bordered + inset)
3. Add `ListStyleKey` environment key with default
4. Create `.listStyle(_:)` modifier extension
5. Update `_ListCore.renderToBuffer()` to read and apply style
6. Add tests for both styles and row rendering differences
7. Implement alternating row colors (even rows get background, odd rows don't)

### Phase 2c: Section Integration (Deferred)
- Flatten Section headers/footers into List rows
- Support SelectionDisabled rows
- Hierarchical selection/focus handling
- **Deferred to Phase 3** (complexity requires separate plan)

---

## Design

### Badge Implementation

**Files to create/modify:**
1. **NEW: Sources/TUIkit/Modifiers/BadgeModifier.swift**
   - Private `BadgeValue` struct: Int, Text, or String
   - Private `BadgeModifier` wrapper: stores badge, renders with environment

2. **MODIFY: Sources/TUIkit/Environment/Environment.swift**
   - Add `BadgeKey: EnvironmentKey` (default: nil)
   - Add `badge: BadgeValue?` property to EnvironmentValues

3. **MODIFY: Sources/TUIkit/Extensions/View+Modifiers.swift** (or new View+Badge.swift)
   - Add `.badge(_ count: Int) -> some View`
   - Add `.badge(_ label: Text?) -> some View`
   - Add `.badge<S>(_ label: S?) -> some View where S: StringProtocol`
   - Each calls `environment(\.badge, value)` via `EnvironmentModifier`

4. **MODIFY: Sources/TUIkit/Views/List.swift**
   - In `renderRow()` method (~line 545): check context.environment.badge
   - If present: render badge at row's right edge, right-aligned
   - Badge styling: dimmed foreground color, (X) for Int or text label
   - Hide if Int == 0 or badge == nil

5. **NEW: Tests/TUIkitTests/BadgeModifierTests.swift**
   - Test all three overloads
   - Test badge in List rows (visual rendering)
   - Test edge cases: 0 value, nil, empty string
   - Test multiple badges (last one wins via environment override)

---

### ListStyle Implementation

**Files to create/modify:**
1. **NEW: Sources/TUIkit/Styles/ListStyle.swift**
   - Protocol `ListStyle: Sendable` with:
     - `var showsBorder: Bool { get }`
     - `var rowPadding: EdgeInsets { get }`
     - `var groupingStyle: GroupingStyle { get }` (enum: plain, inset, insetGrouped)
     - `var alternatingRowColors: Bool { get }`
     - `var alternatingColorPair: (Color, Color)? { get }` (default: nil = use palette)

   - Struct `PlainListStyle: ListStyle` (no borders, minimal padding, no alternating)
   - Struct `InsetGroupedListStyle: ListStyle` (bordered, inset padding, alternating=true)
   - Static convenience: `ListStyle.plain`, `.insetGrouped`
   - Implementation: even rows (index % 2 == 0) get bg color, odd rows get nil or alternate color

2. **MODIFY: Sources/TUIkit/Environment/Environment.swift**
   - Add `ListStyleKey: EnvironmentKey`
   - Default value: `InsetGroupedListStyle()`
   - Add `listStyle: any ListStyle` property to EnvironmentValues

3. **MODIFY: Sources/TUIkit/Extensions/View+Environment.swift**
   - Add `.listStyle<S: ListStyle>(_ style: S) -> some View`
   - Uses `environment(\.listStyle, style)` via `EnvironmentModifier`

4. **MODIFY: Sources/TUIkit/Views/List.swift**
   - In `_ListCore.renderToBuffer()` (~line 450):
     - Read: `let style = context.environment.listStyle`
     - Apply to `ContainerConfig`: borders from `style.showsBorder`
     - Apply to row padding: from `style.rowPadding`
     - Apply to container appearance: inset vs. plain based on `style.groupingStyle`

   - In `renderRow()` (~line 545):
     - Respect `style.rowPadding` when rendering individual rows
     - If `style.alternatingRowColors`: apply alternating background (pass row index)

5. **NEW: Tests/TUIkitTests/ListStyleTests.swift**
   - Test PlainListStyle rendering (no borders)
   - Test InsetGroupedListStyle rendering (borders + padding)
   - Test style propagation via environment (child List reads parent style)
   - Test row appearance differences
   - Test List title + style combination
   - Test alternating row colors for both styles

---

## Implementation Plan

### Phase 2a: Badge (3-4 tasks)
- [ ] Create BadgeModifier.swift with BadgeValue + BadgeModifier view
- [ ] Add BadgeKey + badge property to Environment.swift
- [ ] Add `.badge()` extensions (3 overloads) to View+Badge.swift
- [ ] Update List.renderRow() to render badge from environment
- [ ] Write BadgeModifierTests.swift (15+ test cases)
- [ ] Verify: `swift build` + `swiftlint` + tests pass

### Phase 2b: ListStyle (5-6 tasks)
- [ ] Create ListStyle.swift with protocol + PlainListStyle + InsetGroupedListStyle
- [ ] Add alternatingRowColors logic in ListStyle rendering (even/odd index, alternating bg color from palette)
- [ ] Add ListStyleKey + listStyle property to Environment.swift
- [ ] Add `.listStyle()` modifier to View+Environment.swift
- [ ] Update List._ListCore.renderToBuffer() to read style and pass to row rendering
- [ ] Update List.renderRow() to apply style row padding/appearance + alternating colors (pass row index)
- [ ] Write ListStyleTests.swift (15+ test cases including alternating colors for both styles)
- [ ] Verify: `swift build` + `swiftlint` + tests pass

### Verification
1. Run `swift build` — must pass, no errors
2. Run `swiftlint` — must pass, 0 warnings
3. Run `swift test` — all 682+ tests pass (new tests included)
4. Manual: Test app shows badge in List rows, style changes apply
5. CI: Both macos-15 and swift:6.0 container pass

---

## Critical Files

| File | Purpose | Status |
|------|---------|--------|
| `Sources/TUIkit/Modifiers/BadgeModifier.swift` | Badge implementation | Create |
| `Sources/TUIkit/Styles/ListStyle.swift` | ListStyle protocol + styles | Create |
| `Sources/TUIkit/Environment/Environment.swift` | BadgeKey + ListStyleKey | Modify |
| `Sources/TUIkit/Views/List.swift` | Apply badge + style in rendering | Modify |
| `Sources/TUIkit/Extensions/View+Badge.swift` | `.badge()` overloads | Create |
| `Sources/TUIkit/Extensions/View+Environment.swift` | `.listStyle()` modifier | Modify |
| `Tests/TUIkitTests/BadgeModifierTests.swift` | Badge tests | Create |
| `Tests/TUIkitTests/ListStyleTests.swift` | ListStyle tests | Create |

---

## Decisions

1. **Badge & ListStyle**: Implement together in this phase
2. **Section Integration**: Defer to Phase 3 - Phase 2 focused on Badge + ListStyle
3. **Alternating Row Colors**: Fully implement with even/odd logic in Phase 2b

---

## Checklist

- [ ] Badge modifier fully implemented and tested
- [ ] ListStyle protocol + 2 concrete styles implemented
- [ ] Environment keys + properties added
- [ ] `.badge()` and `.listStyle()` extensions added to View
- [ ] List row rendering updated for badge display
- [ ] List container rendering updated for style application
- [ ] All tests passing (25+ new tests)
- [ ] `swift build` + `swiftlint` clean
- [ ] CI/CD passes (macOS + Linux)
- [ ] Plan moved to `plans/done/` with completion date
- [ ] `to-dos.md` updated with completion
- [ ] `whats-next.md` updated with Phase 3 (Section integration)

