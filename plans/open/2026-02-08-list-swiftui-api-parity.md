# List SwiftUI API Parity

## Preface

TUIkit's List component gains SwiftUI API parity with Section grouping, badges, list styles, selection control, and alternating row backgrounds. Section enables hierarchical organization with headers and footers. The `.badge()` modifier displays counts or labels right-aligned in rows. ListStyle provides visual variants like `.plain` and `.insetGrouped`. Per-item selection can be disabled via `.selectionDisabled()`. Zebra-striping via `.alternatingRowBackgrounds()` improves readability. The `.listRowSeparator()` modifier is implemented as a stub with a warning since separators are not visually supported in TUIkit.

## Context

SwiftUI's List API offers rich configuration options that TUIkit currently lacks. Users expect familiar SwiftUI patterns when building terminal UIs. The current TUIkit List has custom parameters (`title`, `footer`, `focusID`, `maxVisibleRows`, `emptyPlaceholder`) that deviate from SwiftUI conventions.

## Goal

Implement SwiftUI-conformant List features that make sense for terminal UIs:

1. **Section** - Group list items with headers and footers
2. **`.badge()`** - Display counts or labels on the right side of rows
3. **`.listStyle()`** - Different visual presentations
4. **`.selectionDisabled()`** - Disable selection for specific items
5. **`.alternatingRowBackgrounds()`** - Zebra-striping for better readability
6. **`.listRowSeparator()`** - Stub with warning (not visually supported)

## Design

### Section

SwiftUI signature:
```swift
Section {
    // content
} header: {
    Text("Header")
} footer: {
    Text("Footer")
}
```

TUIkit implementation:
- `Section<Parent, Content, Footer>` where Parent/Content/Footer are Views
- Header rendered with dimmed/bold styling above section content
- Footer rendered with dimmed styling below section content
- Sections work inside List, rendering grouped content with visual separation

### Badge Modifier

SwiftUI signatures:
```swift
func badge(_ count: Int) -> some View
func badge(_ label: Text?) -> some View
func badge<S>(_ label: S?) -> some View where S : StringProtocol
```

TUIkit implementation:
- Badge renders right-aligned in the row
- Integer badges show the count (0 hides the badge)
- Text badges show the string
- Stored in environment, read during row rendering
- Visual: dimmed color, right-aligned with padding

### List Style

SwiftUI signature:
```swift
func listStyle<S>(_ style: S) -> some View where S : ListStyle
```

Relevant styles for TUI:
- `.plain` - No decoration, minimal spacing
- `.inset` - Indented with subtle visual grouping
- `.insetGrouped` - Grouped sections with inset appearance
- `.sidebar` - Sidebar-appropriate styling (if needed)

TUIkit implementation:
- `ListStyle` protocol with static properties
- Styles affect: border presence, row padding, section spacing, background
- Default style: `.automatic` (maps to `.insetGrouped` behavior, current default)

### Selection Disabled Modifier

SwiftUI signature:
```swift
func selectionDisabled(_ isDisabled: Bool = true) -> some View
```

TUIkit implementation:
- Environment key `isSelectionDisabled`
- When true, row cannot be selected (focus skips it or selection is prevented)
- Visual feedback: dimmed appearance when disabled

### Alternating Row Backgrounds

SwiftUI signature (macOS):
```swift
func alternatingRowBackgrounds(_ behavior: AlternatingRowBackgroundBehavior = .enabled) -> some View
```

TUIkit implementation:
- `AlternatingRowBackgroundBehavior` enum: `.automatic`, `.enabled`, `.disabled`
- When enabled, odd/even rows get different background colors
- Uses subtle palette-derived colors for alternation
- Applied at List level, affects all rows

### List Row Separator (Stub)

SwiftUI signature:
```swift
func listRowSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View
```

TUIkit implementation:
- Modifier exists for API compatibility
- Logs a warning: "listRowSeparator is not supported in TUIkit"
- Returns the view unchanged (no visual effect)

## Implementation Plan

### Phase 1: Section

1. Create `Section` struct with header/content/footer generic parameters
2. Implement initializers matching SwiftUI signatures
3. Add `SectionRowExtractor` protocol for List to recognize sections
4. Update `_ListCore` to render section headers/footers
5. Add tests for Section in List

### Phase 2: Badge Modifier

1. Create `BadgeKey` environment key
2. Implement `.badge(_:)` modifier overloads (Int, Text, String)
3. Update row rendering in `_ListCore` to read badge from environment
4. Render badge right-aligned with appropriate styling
5. Add tests for badge rendering

### Phase 3: List Style

1. Create `ListStyle` protocol
2. Implement concrete styles: `PlainListStyle`, `InsetListStyle`, `InsetGroupedListStyle`
3. Create `ListStyleKey` environment key
4. Add `.listStyle(_:)` modifier
5. Update `_ListCore` to read and apply list style
6. Add tests for different list styles

### Phase 4: Selection Disabled

1. Create `SelectionDisabledKey` environment key
2. Implement `.selectionDisabled(_:)` modifier
3. Update `ItemListHandler` to respect selection disabled state
4. Add dimmed visual appearance for disabled items
5. Add tests for selection disabled behavior

### Phase 5: Alternating Row Backgrounds

1. Create `AlternatingRowBackgroundBehavior` enum
2. Create `AlternatingRowBackgroundsKey` environment key
3. Implement `.alternatingRowBackgrounds(_:)` modifier
4. Update row rendering to apply alternating colors
5. Add tests for zebra-striping

### Phase 6: List Row Separator Stub

1. Create `ListRowSeparatorKey` environment key
2. Implement `.listRowSeparator(_:edges:)` modifier
3. Log warning when modifier is used
4. Add test verifying warning is logged

## Checklist

- [x] **Phase 1: Section** (2026-02-08)
  - [x] Create `Section` struct
  - [x] Implement SwiftUI-conformant initializers
  - [x] Add `SectionRowExtractor` protocol
  - [ ] Update `_ListCore` for section rendering (deferred to Phase 3)
  - [x] Write tests (14 tests)

- [ ] **Phase 2: Badge Modifier**
  - [ ] Create `BadgeKey` environment key
  - [ ] Implement `.badge()` overloads
  - [ ] Update row rendering for badges
  - [ ] Write tests

- [ ] **Phase 3: List Style**
  - [ ] Create `ListStyle` protocol
  - [ ] Implement concrete styles
  - [ ] Add environment key and modifier
  - [ ] Update `_ListCore` to apply styles
  - [ ] Write tests

- [ ] **Phase 4: Selection Disabled**
  - [ ] Create environment key
  - [ ] Implement modifier
  - [ ] Update `ItemListHandler`
  - [ ] Add visual feedback
  - [ ] Write tests

- [ ] **Phase 5: Alternating Row Backgrounds**
  - [ ] Create enum and environment key
  - [ ] Implement modifier
  - [ ] Update row rendering
  - [ ] Write tests

- [ ] **Phase 6: List Row Separator Stub**
  - [ ] Create environment key
  - [ ] Implement modifier with warning
  - [ ] Write test for warning

## Files

- `Sources/TUIkit/Views/Section.swift` (new)
- `Sources/TUIkit/Views/List.swift` (modify)
- `Sources/TUIkit/Styles/ListStyle.swift` (new)
- `Sources/TUIkit/Modifiers/BadgeModifier.swift` (new)
- `Sources/TUIkit/Modifiers/SelectionDisabledModifier.swift` (new)
- `Sources/TUIkit/Modifiers/AlternatingRowBackgroundsModifier.swift` (new)
- `Sources/TUIkit/Modifiers/ListRowSeparatorModifier.swift` (new)
- `Sources/TUIkit/Environment/EnvironmentKeys.swift` (modify)
- `Tests/TUIkitTests/SectionTests.swift` (new)
- `Tests/TUIkitTests/ListStyleTests.swift` (new)
- `Tests/TUIkitTests/BadgeModifierTests.swift` (new)

## Dependencies

- Current uncommitted changes should be committed first (Alert improvements, Button roles, rendering fixes)
- No external dependencies

## Open Questions

- Should TUIkit List initializers be changed to match SwiftUI exactly (removing `title`, `footer` parameters)? This would be a breaking change but improve API conformity.
- Should `.badge()` support `BadgeProminence` for different visual weights?
- Which list styles are most useful for terminal UIs? `.plain` and `.insetGrouped` seem most relevant.
