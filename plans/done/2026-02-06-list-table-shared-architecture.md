# List & Table: Shared Architecture Analysis

## Completed

2026-02-07

## Preface

This analysis identifies the shared architecture between List and Table before implementation: both need focus management, keyboard navigation (Up/Down/Home/End), selection binding, scrolling, and item state rendering. Navigation logic and selection state are identical; rendering differs (List = vertical stack, Table = grid). Extract shared components (handlers, helpers, state managers) to eliminate duplication while letting each component specialize in layout.

## Context / Problem

Both List and Table need focus management, item navigation, selection binding, scrolling, and keyboard handlers. Without careful planning, the implementations will duplicate effort and diverge in behavior.

## Specification / Goal

Analyze shared patterns between List and Table to establish common architecture before implementing either component.

## Existing Patterns Analysis

### 1. Box.swift Pattern
- Composite View that delegates to `.border()` modifier
- Uses `body` property (not Renderable directly)
- Optional parameters with environment defaults
- Equatable conformance for caching

### 2. Focus.swift Pattern
- `Focusable` protocol requires AnyObject (class-based handlers)
- Handler returns `true` from `handleKeyEvent()` to consume events
- FocusManager dispatches to focused element first, then handles Tab/arrows
- Section-based navigation with `context.activeFocusSectionID`

### 3. RadioButtonGroupHandler Pattern (Primary Blueprint)
- Handler class with `focusedIndex` persisted via StateStorage
- Separate navigation index vs selection binding
- Wrap-around navigation (last to first)
- Consumes directional keys even when not acting
- `onFocusLost()` resets focusedIndex to selected item

### 4. StateStorage Pattern
- `StateKey(identity, propertyIndex)` for unique identification
- `stateStorage.storage(for:default:)` returns StateBox
- `stateStorage.markActive(identity)` prevents garbage collection
- StateBox mutations trigger re-render automatically

### 5. ContainerView Pattern
- Two-struct pattern: public View + private `_Core` Renderable
- Width calculation: render content first, then container
- Context width reduction: subtract 2 for borders
- Focus indicator consumption via `context.focusIndicatorColor`

## Architecture Decision

**Option A Selected**: List as View, Table as View, shared `ItemListHandler` class

Rationale:
- Follows existing RadioButtonGroupHandler pattern
- Handler encapsulates all navigation logic
- List and Table differ only in rendering
- No need for complex protocol hierarchies

## Shared Components Design

### 1. ItemListHandler (Focusable class)

```swift
final class ItemListHandler: Focusable {
    let focusID: String
    var focusedIndex: Int = 0
    var scrollOffset: Int = 0
    var itemCount: Int = 0
    var viewportHeight: Int = 10
    var canBeFocused: Bool = true
    var onSelect: ((Int) -> Void)?
    
    func handleKeyEvent(_ event: KeyEvent) -> Bool
    func onFocusLost()
    func ensureFocusedInView()
}
```

Navigation keys:
| Key | Action |
|-----|--------|
| Up | focusedIndex -= 1 (wrap to end) |
| Down | focusedIndex += 1 (wrap to start) |
| Home | focusedIndex = 0 |
| End | focusedIndex = itemCount - 1 |
| PageUp | focusedIndex -= viewportHeight |
| PageDown | focusedIndex += viewportHeight |
| Enter/Space | onSelect?(focusedIndex) |

### 2. Item Rendering States

Four visual states based on focus and selection:

| State | Style |
|-------|-------|
| Focused + Selected | Pulsing accent, bold |
| Focused only | Accent color (navigation cursor) |
| Selected only | Dimmed accent |
| Neither | Default foreground |

Helper function in `ItemStateRenderer`:
```swift
func renderItem(
    content: String,
    isFocused: Bool,
    isSelected: Bool,
    pulsePhase: Double,
    palette: Palette
) -> String
```

### 3. Scroll Management

Auto-scroll when focus moves out of visible window:
```swift
func ensureFocusedInView() {
    if focusedIndex < scrollOffset {
        scrollOffset = focusedIndex
    } else if focusedIndex >= scrollOffset + viewportHeight {
        scrollOffset = focusedIndex - viewportHeight + 1
    }
}
```

Scroll indicators: Show up/down arrows when content extends beyond viewport.

### 4. Container Reuse

Both List and Table wrap content in ContainerView via `.border()` modifier:
- Optional title
- Border style from appearance
- Padding handled by modifier chain

## File Structure

```
Sources/TUIkit/
├── Focus/
│   ├── ItemListHandler.swift      # Shared navigation handler
│   └── ItemStateRenderer.swift    # Shared item rendering
├── Views/
│   ├── List.swift                 # List view (uses ItemListHandler)
│   └── Table.swift                # Table view (uses ItemListHandler)
```

## Keyboard Navigation Model

```
┌─────────────────────────────────────────────────────────────┐
│                     FocusManager                            │
│  dispatchKeyEvent() → focused.handleKeyEvent()              │
│                           ↓                                 │
│               ItemListHandler.handleKeyEvent()              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Up/Down/Home/End/PgUp/PgDown: Update focusedIndex   │   │
│  │ Enter/Space: Call onSelect                          │   │
│  │ Return true (consume event)                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Tab: FocusManager handles (next section/element)          │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Order

1. **ItemListHandler.swift**: Navigation logic, Focusable conformance
2. **ItemStateRenderer.swift**: Focus/selection visual states
3. **List.swift**: Simple vertical list using shared components
4. **Table.swift**: Grid layout with column alignment (future)

## Checklist

- [x] Architecture decisions documented
- [x] Shared patterns identified
- [x] Reference provided for List & Table implementation
- [x] No code changes required (analysis only)
