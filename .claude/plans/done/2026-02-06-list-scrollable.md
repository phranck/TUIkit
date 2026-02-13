# List (Scrollable)

## Preface

List gives TUI apps the power of SwiftUI's List: arbitrary nested views, ForEach with dynamic content, optional selection binding via `.tag()`, and keyboard navigation (Up/Down/Home/End/PageUp/PageDown) with auto-scrolling. Focused item always visible, scroll indicators show bounds, selection updates on Enter. MVP focuses on core scrollable list without sections. They come later once the API is proven.

## Completed

**2026-02-08**: List implemented with ItemListHandler, single/multi selection, keyboard navigation, scroll indicators, ForEach support.

## Checklist

- [x] Create ListRow internal structure
- [x] Create List struct with selection binding and content builder
- [x] Create ListHandler for keyboard navigation and selection (using shared FocusableItemListHandler)
- [x] Implement row identity resolution from @ViewBuilder
- [x] Implement Renderable extension with visible window rendering
- [x] Add .disabled() modifier
- [x] Write 25+ comprehensive tests
- [x] Build & lint verification
- [x] Add to example app
- [x] Documentation complete

## Context / Problem

Terminal applications need a scrollable list component that supports keyboard navigation, optional selection binding, and dynamic content from ViewBuilder closures.

## Specification / Goal

A scrollable list component that displays arbitrary views in a vertical scrollable container with single selection support, keyboard navigation, and dynamic content.

## SwiftUI Reference

```swift
// Basic list with static content
List {
    Text("Item 1")
    Text("Item 2")
    Text("Item 3")
}

// List with selection
@State var selectedID: String?
List(selection: $selectedID) {
    Text("Item 1").tag("1")
    Text("Item 2").tag("2")
}

// List with dynamic content (ForEach)
List {
    ForEach(items, id: \.id) { item in
        Text(item.name)
    }
}

// List with sections
List {
    Section("Numbers") {
        Text("One")
        Text("Two")
    }
    Section("Letters") {
        Text("A")
        Text("B")
    }
}

// List with style
List {
    Text("Item")
}
.listStyle(.plain)  // or .inset, .grouped, .sidebar
```

Key SwiftUI patterns:
- `@ViewBuilder` content closure for arbitrary view composition
- Optional `selection: Binding<Selection>` for selection tracking
- `.tag()` modifier to associate values with rows
- Dynamic content via `ForEach` with stable `id`
- Sections with headers and footers
- Multiple style options (plain, inset, grouped, sidebar)

## TUIKit Design

### Target MVP

For initial implementation, focus on core scrollable list without sections:

```swift
// Basic scrollable list
List {
    Text("Item 1")
    Text("Item 2")
    Text("Item 3")
}

// With selection binding (optional)
@State var selected: String?
List(selection: $selected) {
    Text("Item 1").tag("1")
    Text("Item 2").tag("2")
}

// Dynamic content
List {
    ForEach(items, id: \.id) { item in
        Text(item.name)
    }
}
```

**Sections deferred to Phase 2**. Ucomplexity of section headers/footers can wait.

### API

```swift
public struct List<SelectionValue: Hashable, Content: View>: View {
    /// Optional selection binding
    let selection: Binding<SelectionValue>?
    
    /// Content builder (rows)
    let content: Content
    
    /// Height of list container (default: fills available height)
    let height: Int?
    
    /// Whether selection is enabled
    let canSelect: Bool
    
    /// Creates a scrollable list
    public init(
        selection: Binding<SelectionValue>? = nil,
        height: Int? = nil,
        @ViewBuilder content: () -> Content
    )
}

// Convenience for unselected lists
public init(
    height: Int? = nil,
    @ViewBuilder content: () -> Content
) where SelectionValue == Never
```

### Visual Behavior

```
┌──────────────────────┐
│ ● Item 1             │  ← focused row (pulsing ●)
│   Item 2             │
│   Item 3             │
│   Item 4             │
│   Item 5             │
↓   (scroll indicator) │
└──────────────────────┘
```

**Focus Behavior:**
- First item auto-focused when list gains focus
- Arrow Up/Down navigate rows
- Enter/Space selects focused row (if selection enabled)
- Tab moves to next element outside list

**Scroll Behavior:**
- Scroll window shows 5–10 items at a time (configurable via height, default behavior without height setting: it consumes the evailable height)
- Focused item always visible (auto-scroll into view)
- Scroll indicator (↑/↓) shows when content extends beyond viewport

### Selection Semantics

Selection is independent of focus:
- **Focus** = keyboard navigation position (visual highlight)
- **Selection** = value bound to `selection` binding (persistent state)
- Pressing Enter while focused on row updates `selection` binding

### Rendering

Each row is rendered independently:
1. Resolve children from content closure
2. Flatten into list of (view, identity) pairs
3. Determine visible window based on scroll offset
4. Render focused row with pulsing indicator prefix
5. Render unfocused rows with dimmed prefix or no prefix

### Keyboard Interaction

| Key | Action |
|-----|--------|
| ↑ | Previous row (wrap to end) |
| ↓ | Next row (wrap to start) |
| Page Up | Scroll up 5 rows |
| Page Down | Scroll down 5 rows |
| Home | Jump to first row |
| End | Jump to last row |
| Enter/Space | Select focused row (if selection enabled) |
| Tab | Exit list, focus next element |

## Design

### Component Architecture

The List component uses ViewBuilder for content, identity-based row tracking, keyboard event handling via ListHandler, and optional selection binding. Core features include focus management, scrolling with auto-focus-into-view behavior, and keyboard navigation (Up/Down/Home/End/PageUp/PageDown).

### Rendering Strategy

Each row is rendered independently, with focus/selection state determining visual styling (pulsing indicator for focus, different background for selection).

## Implementation Plan

### Phase 1: Core List (MVP)

- [ ] Create `ListRow` internal structure to track row identity and view
- [ ] Create `List` struct with selection binding (optional) and content builder
- [ ] Create `ListHandler` (Focusable) for keyboard navigation and selection
  - Maintains `focusedIndex` (keyboard position)
  - Maintains `scrollOffset` (viewport top row index)
  - Implements Up/Down/Page Up/Page Down/Home/End navigation
  - Auto-scrolls focused row into view
- [ ] Implement row identity resolution from `@ViewBuilder` content
  - Use existing `ViewIdentity` system to track row IDs
  - Support `.tag()` modifier for selection values
  - Flatten tree into flat list of rows
- [ ] Implement `Renderable` extension
  - Render visible window (scrollOffset to scrollOffset + viewportHeight)
  - Render focused row with pulsing `●` indicator
  - Render unfocused rows with dimmed prefix or space
  - Append scroll indicators (↑/↓) if needed
- [ ] Add `.disabled()` modifier
- [ ] Write comprehensive tests (25+ tests)
  - Row identity tracking
  - Navigation (up, down, home, end, page up/down, wrapping)
  - Selection binding updates
  - Scroll window calculation
  - Focus management
  - Disabled state
  - Empty list handling
- [ ] Build & lint verification
- [ ] Add to example app (ListPage with multiple scenarios)

### Phase 2: Enhancements (future)

- [ ] Sections with headers/footers
- [ ] List styles (plain, inset, grouped, sidebar)
- [ ] Swipe actions (delete, move)
- [ ] Edit mode (reordering, multi-select)
- [ ] Lazy rendering for huge lists (10k+ rows)

## Technical Challenges

### 1. Row Identity from @ViewBuilder Content

SwiftUI's `List` accepts `@ViewBuilder` content, which creates arbitrary view hierarchies. We need to:
- Flatten the hierarchy into a list of "rows"
- Assign stable identities to each row
- Support `.tag()` modifier to associate selection values
- Detect when content changes (new rows added/removed)

**Solution:** Reuse existing `ViewIdentity` + `StateStorage` system:
- Walk the rendered view tree after `@ViewBuilder` returns
- Assign each top-level view a stable ID based on its position in the builder
- Cache IDs in StateStorage so they're stable across renders
- Support `.tag()` by checking if focused row has a tag value in the environment

### 2. Selection Value Tracking with Generics

The selection binding can be any `Hashable` type. Rows can have different tag values:

```swift
List(selection: $selectedID) {
    Text("Item 1").tag("a")      // String
    Text("Item 2").tag("b")      // String
    Text("Item 3")               // No tag = unfocusable?
}
```

**Solution:**
- Make selection optional: `Binding<SelectionValue>?`
- Only rows with `.tag(value)` are selectable
- Rows without `.tag()` are focusable but not selectable
- When user presses Enter on a row with `.tag()`, update binding

### 3. Scroll Window Calculation

Need to:
- Track `focusedIndex` (0-based row index in full list)
- Track `scrollOffset` (0-based index of topmost visible row)
- Auto-scroll: when focusedIndex < scrollOffset or >= scrollOffset + viewportHeight, adjust scrollOffset
- Prevent over-scrolling (scrollOffset + viewportHeight ≤ totalRows)

**Solution:**
```swift
// In ListHandler
func focusedIndexChanged(_ newIndex: Int) {
    focusedIndex = newIndex
    
    // Auto-scroll into view
    if newIndex < scrollOffset {
        scrollOffset = newIndex  // Scroll up
    } else if newIndex >= scrollOffset + viewportHeight {
        scrollOffset = newIndex - viewportHeight + 1  // Scroll down
    }
}
```

### 4. ViewBuilder Content Resolution

The content closure returns a View, but we need to:
1. Render it to get actual children
2. Flatten hierarchy (Handle VStack, Tuple, etc.)
3. Assign IDs to each child
4. Cache for next render

**Existing Solution:** The framework already has `resolveChildInfos()` in Stacks. We can reuse this pattern:

```swift
let childInfos = resolveChildInfos(from: content, context: context)
// Each childInfo has: view, identity, buffer
```

## API Details

### Initializers

```swift
// With selection
public init<SelectionValue: Hashable>(
    selection: Binding<SelectionValue>,
    height: Int? = nil,
    @ViewBuilder content: () -> Content
)

// Without selection (SelectionValue = Never)
public init(
    height: Int? = nil,
    @ViewBuilder content: () -> Content
) where SelectionValue == Never
```

### Modifiers

```swift
List { ... }
    .disabled()           // Disable keyboard navigation + selection
    .frame(height: 10)    // Fixed height (or fill available)
```

### Row Tagging

Use standard SwiftUI `.tag()` modifier:

```swift
List(selection: $selected) {
    Text("Item 1").tag("id-1")
    Text("Item 2").tag("id-2")
}
```

## Test Strategy

### Unit Tests (ListHandler)

- Navigation: up, down, page up/down, home, end, wrapping at boundaries
- Selection: pressing Enter updates binding, no update without `.tag()`
- Scroll window: focus triggers auto-scroll, prevent over-scroll
- Empty list: no crash, no navigation
- Single item: no wrapping, selectable
- Disabled state: keys ignored, no selection updates

### Integration Tests (List rendering)

- Focused row renders with `●` indicator
- Unfocused rows render with space or tertiary color
- Scroll indicators (`↑`, `↓`) appear correctly
- ViewBuilder content resolved correctly
- Selection binding updated on Enter
- Keyboard focus management with FocusManager

### Example App Tests

- Static list (10 items, select to show selection)
- Dynamic list (ForEach over array)
- Empty list (graceful fallback)
- Mixed selectable/non-selectable rows
- Large list (50+ items, scroll performance)

## Files

- `Sources/TUIkit/Views/List.swift`: List component + ListHandler
- `Tests/TUIkitTests/ListTests.swift`: 25+ tests
- `Sources/TUIkitExample/Pages/ListPage.swift`: Example page

## Dependencies

- Focus system ✅ (FocusManager, Focusable)
- Binding ✅
- ViewBuilder ✅
- StateStorage ✅ (row ID persistence)
- ViewIdentity ✅ (child tracking)
- RenderContext + PulseTimer ✅ (focus indicator animation)
- ANSI rendering ✅

## Architecture Notes

### ListHandler Persistence

ListHandler must be persisted in StateStorage (like RadioButtonGroupHandler) to maintain:
- `focusedIndex` across renders (keyboard position)
- `scrollOffset` across renders (viewport position)

Without persistence, every render would reset focus to first row.

### Row Identity Stability

Row IDs must be stable across renders. Use the same approach as Stacks:
- Assign ID based on position in ViewBuilder output
- Cache in StateStorage keyed by (list identity, row index)
- Detect insertions/deletions/reordering via child count change

### Selection vs Focus

Key insight (like RadioButtonGroup):
- **Focus** = which row has keyboard cursor (visual ● indicator)
- **Selection** = which row's `.tag()` value is in the binding
- Independent: can navigate focus without changing selection (until user presses Enter)

## Performance Considerations

### Initial MVP

- Render all rows (even off-screen). Usimple, correct semantics
- Cache rendered buffers in RenderContext if available
- Measure: 100 rows should render in <50ms

### Future Optimization (Phase 2)

- Virtual rendering: only render visible window + small buffer (±2 rows)
- Lazy child resolution: don't fully render off-screen rows
- Memoization: cache row buffers via `.equatable()`

## Open Questions

1. **Height configuration:** Fixed height, or auto-fill available space?
   → Initially fixed via `height: Int?` parameter, default = available height
   
2. **Viewport size:** How many rows visible? 5, 10, configurable?
   → Auto-calculate based on available height (each row = 1 line, spacing = 0)
   
3. **Non-selectable rows:** What happens if row lacks `.tag()`?
   → Still focusable/navigable, but Enter does nothing
   
4. **Empty list:** Should it be focusable?
   → No, but shouldn't crash. ListHandler not registered if list empty.
   
5. **ForEach IDs:** How does `.id()` in ForEach interact with List tagging?
   → ForEach `.id()` is for stability; List `.tag()` is for selection. Both can be used.
   → E.g.: `ForEach(items, id: \.id) { item in Text(item.name).tag(item.id) }`
