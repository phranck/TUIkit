# List & Table: Shared Architecture Analysis

## Similarities (Redundancy Risk)

### Core Concepts
- **Focus Management**: Both need to track which item is focused (keyboard navigation)
- **Item Focus State**: Up/Down arrows, Home/End, Page Up/Down to navigate items
- **Selection**: Binding to track selected item(s)
- **Scrolling/Viewport**: Both have visible area vs total content
- **Keyboard Handlers**: Up/Down, Enter/Space, Page Up/Down, Home/End
- **Item Rendering with State**: Each item can be focused/selected (visual diff)

### Visual Elements
- **Container**: Border, optional title, padding
- **Focus Indicator**: Visual marker on focused item (background color, bar, etc.)
- **Selection Indicator**: Visual marker on selected item(s)
- **Scroll Indicators**: Up/Down arrows when not at boundaries

### Handler Logic
- Both need `Focusable` interface (for focus manager)
- Both need `StateStorage` for persistence across renders
- Navigation logic (focusUp, focusDown, etc.) is identical
- Scroll offset management is identical

## Differences

### List
- **Layout**: Vertical stack of items (simple)
- **Selection**: Usually single item
- **Item Content**: Arbitrary Views

### Table
- **Layout**: Grid with columns and rows
- **Selection**: Row-based (but multiple columns in display)
- **Column Alignment**: ANSI-aware padding per column
- **Item Content**: Structured (column values, not arbitrary Views)

## Shared Architecture Needed

### 1. Base Focusable Item Handler
Extract common navigation logic into reusable class:
```
FocusableItemListHandler:
  - focusedIndex
  - scrollOffset  
  - viewportHeight
  - rowCount
  - focusUp/Down/Home/End/Page Up/Down
  - ensureFocusedInView()
```

### 2. Selection State
Shared pattern for tracking selected item:
```
SelectionState<SelectionValue>:
  - binding: Binding<SelectionValue>?
  - select(index, value)
  - isSelected(index, value) -> Bool
```

### 3. Container & Border Rendering
Both need border + optional title + padding.
Possibly extract into shared utility or reuse existing `ContainerView`.

### 4. View Modifiers (Extensions)
Both should support:
- `.foregroundColor()` (via Environment)
- `.disabled()`
- `.focusable()` (custom?)
- `.padding()` (via modifiers)

### 5. Focus Indicator & Item State Rendering
Common pattern:
```
func renderItemWithState(
  content: String,
  isFocused: Bool,
  isSelected: Bool,
  palette: Palette
) -> String
```

## Implementation Strategy

### Phase 1: Extract Common Handler
Create `FocusableItemListBase` or similar with shared navigation logic.
Both List and Table create instances and reuse.

### Phase 2: Shared Selection State
Extract `SelectionStateManager<T>` for consistent selection binding.

### Phase 3: Architecture Decision
- **Option A**: List as View, Table as View, both use private _ListCore/_TableCore Views
- **Option B**: Single generic base (e.g., `_FocusableItemList`) that List and Table wrap
- **Option C**: Trait-based design (protocols for Focus, Selection, Rendering)

## Critical: DO NOT IMPLEMENT YET
Just keep this analysis for reference before implementing either List or Table.
Search for:
1. How Box handles modifiers
2. How existing focus management works
3. How Focusable interface is used elsewhere
4. What StateStorage patterns already exist
5. Container rendering patterns

Then design List & Table to maximize code reuse.
