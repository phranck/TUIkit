# List & Table Components

## Preface

This plan implements the List and Table components in two phases. Phase 1 builds the shared `ItemListHandler` (navigation, selection, scrolling) and the `List` view. Phase 2 adds the `Table` view, reusing the handler and adding column alignment. Both components follow the RadioButtonGroup pattern: a handler class persisted via StateStorage, keyboard navigation within the component, and visual states for focused/selected items.

## Context / Problem

TUIKit lacks scrollable list and table components. Users need to display collections with keyboard navigation, selection, and scrolling. The architecture analysis (completed) identified shared patterns between List and Table. Now we implement both components using that shared foundation.

## Specification / Goal

Implement:
1. `ItemListHandler`: Shared Focusable class for navigation, selection, scrolling
2. `List`: Vertical scrollable list with single/multi-selection
3. `Table`: Grid with column headers and alignment (reuses ItemListHandler)

API targets (SwiftUI-inspired):

```swift
// List with single selection
List(selection: $selectedID) {
    ForEach(items) { item in
        Text(item.name)
    }
}

// List with multi-selection
List(selection: $selectedIDs) {
    ForEach(items) { item in
        Text(item.name)
    }
}

// Table with columns
Table(items, selection: $selectedID) {
    TableColumn("Name", value: \.name)
    TableColumn("Size", value: \.size)
    TableColumn("Date", value: \.date)
}
```

## Design

### ItemListHandler

Shared handler for both List and Table. Manages:
- `focusedIndex`: Currently highlighted item (keyboard cursor)
- `scrollOffset`: First visible item index
- `viewportHeight`: Number of visible items
- `selectionMode`: Single or multi-selection
- `selectedIndices`: Set of selected item indices

Navigation keys (same for both components):
| Key | Action |
|-----|--------|
| Up | focusedIndex -= 1 (wrap to end) |
| Down | focusedIndex += 1 (wrap to start) |
| Home | focusedIndex = 0 |
| End | focusedIndex = itemCount - 1 |
| PageUp | focusedIndex -= viewportHeight |
| PageDown | focusedIndex += viewportHeight |
| Enter/Space | Toggle selection at focusedIndex |

### Visual States

Four states per item:
| State | Rendering |
|-------|-----------|
| Focused + Selected | Pulsing accent background, bold text |
| Focused only | Accent foreground (navigation cursor) |
| Selected only | Dimmed accent foreground |
| Neither | Default foreground |

### Scrolling

Auto-scroll to keep focused item visible:
```
if focusedIndex < scrollOffset:
    scrollOffset = focusedIndex
if focusedIndex >= scrollOffset + viewportHeight:
    scrollOffset = focusedIndex - viewportHeight + 1
```

Scroll indicators: Up/down arrows when content extends beyond viewport.

### List Structure

```swift
public struct List<SelectionValue: Hashable, Content: View>: View {
    let selection: Binding<SelectionValue?>        // Single selection
    // OR
    let selection: Binding<Set<SelectionValue>>    // Multi selection
    let content: Content
    
    public var body: Never { fatalError() }
}

extension List: Renderable {
    func renderToBuffer(context:) -> FrameBuffer
}
```

### Table Structure (Phase 2)

```swift
public struct Table<Value, Content>: View {
    let data: [Value]
    let selection: Binding<Value.ID?>
    let columns: [TableColumn<Value>]
}

public struct TableColumn<Value> {
    let title: String
    let alignment: HorizontalAlignment
    let width: ColumnWidth  // .fixed(Int), .flexible, .ratio(Double)
    let value: (Value) -> String
}
```

## Implementation Plan

### Phase 1: ItemListHandler + List

1. **ItemListHandler.swift** (Focus/)
   - Focusable conformance
   - Navigation logic (Up/Down/Home/End/PageUp/PageDown)
   - Selection management (single + multi)
   - Scroll offset calculation
   - `onFocusLost()` behavior

2. **List.swift** (Views/)
   - Public API with selection binding
   - ForEach-style content via @ViewBuilder
   - Renderable extension with StateStorage integration
   - Scroll indicators (arrows when content overflows)
   - Visual states for items

3. **ListTests.swift** (Tests/)
   - Navigation: Up/Down/Home/End/PageUp/PageDown
   - Selection: single, multi, toggle
   - Scrolling: auto-scroll on navigation
   - Edge cases: empty list, single item, disabled

4. **ListPage.swift** (Example/)
   - Demo with various list configurations
   - Single and multi-selection examples

### Phase 2: Table

5. **TableColumn.swift** (Views/)
   - Column definition with title, alignment, width
   - Value extraction closure

6. **Table.swift** (Views/)
   - Reuses ItemListHandler
   - Column header rendering
   - ANSI-aware column alignment
   - Grid layout with separators

7. **TableTests.swift** (Tests/)
   - Column alignment
   - Header rendering
   - Selection (reuses handler logic)

8. **TablePage.swift** (Example/)
   - File browser style table
   - Multi-column data display

## Checklist

### Phase 1: List

- [ ] ItemListHandler: Navigation logic (Up/Down/Home/End)
- [ ] ItemListHandler: PageUp/PageDown navigation
- [ ] ItemListHandler: Single selection mode
- [ ] ItemListHandler: Multi selection mode
- [ ] ItemListHandler: Scroll offset management
- [ ] ItemListHandler: onFocusLost behavior
- [ ] List: Public API with Binding
- [ ] List: Renderable with StateStorage
- [ ] List: Visual states (focused/selected)
- [ ] List: Scroll indicators
- [ ] List: Disabled state
- [ ] ListTests: Navigation tests
- [ ] ListTests: Selection tests
- [ ] ListTests: Scroll tests
- [ ] ListPage: Example integration

### Phase 2: Table

- [ ] TableColumn: Definition struct
- [ ] TableColumn: Width modes (fixed/flexible/ratio)
- [ ] Table: Public API
- [ ] Table: Header rendering
- [ ] Table: ANSI-aware column alignment
- [ ] Table: Reuses ItemListHandler
- [ ] TableTests: Column tests
- [ ] TableTests: Selection tests
- [ ] TablePage: Example integration

## Open Questions

1. **Selection API:** SwiftUI uses `List(selection:)` with optional for single, Set for multi. Follow exactly?
2. **Row height:** Fixed 1 line per item, or allow multi-line rows?
3. **Empty state:** Show placeholder text when list is empty?
4. **Table separators:** Vertical lines between columns, or space-only?

## Files

New:
- `Sources/TUIkit/Focus/ItemListHandler.swift`
- `Sources/TUIkit/Views/List.swift`
- `Sources/TUIkit/Views/Table.swift`
- `Sources/TUIkit/Views/TableColumn.swift`
- `Tests/TUIkitTests/ListTests.swift`
- `Tests/TUIkitTests/TableTests.swift`
- `Sources/TUIkitExample/Pages/ListPage.swift`
- `Sources/TUIkitExample/Pages/TablePage.swift`

Modified:
- `Sources/TUIkitExample/ExampleApp.swift` (add menu entries)

## Dependencies

- RadioButtonGroup pattern (reference implementation)
- ActionHandler pattern (simpler reference)
- StateStorage (handler persistence)
- FocusManager (registration, key dispatch)
- ANSIRenderer (colorize, visual states)
