# NavigationSplitView Integration

## Preface

NavigationSplitView brings a two- or three-column navigation layout to TUIkit, enabling master-detail patterns common in terminal applications like file managers, music players, or database browsers. The view renders entirely within the content area between AppHeader and StatusBar, respecting existing layout constraints. Each column becomes its own focus section, allowing Tab navigation between sidebar, content, and detail areas. Column visibility can be controlled programmatically, and styles determine whether columns resize or overlay.

## Context

SwiftUI's NavigationSplitView (iOS 16+) provides:
- Two-column layout: `sidebar` + `detail`
- Three-column layout: `sidebar` + `content` + `detail`
- Programmatic visibility control via `NavigationSplitViewVisibility`
- Column identification via `NavigationSplitViewColumn`
- Styles: `automatic`, `balanced`, `prominentDetail`

TUIkit constraints:
- Terminal has fixed character width (no fractional columns)
- AppHeader and StatusBar consume vertical space; NavigationSplitView renders in the remaining content area
- No mouse interaction; keyboard-only navigation via focus sections
- Column separators use box-drawing characters (e.g., `│`)

## Specification

### API Parity with SwiftUI

```swift
// Two-column
NavigationSplitView {
    List(items, selection: $selected) { ... }
} detail: {
    DetailView(item: selected)
}

// Three-column
NavigationSplitView {
    List(categories, selection: $category) { ... }
} content: {
    List(items, selection: $item) { ... }
} detail: {
    DetailView(item: item)
}

// With visibility control
@State private var visibility: NavigationSplitViewVisibility = .automatic

NavigationSplitView(columnVisibility: $visibility) {
    ...
} detail: {
    ...
}

// With style
NavigationSplitView { ... } detail: { ... }
    .navigationSplitViewStyle(.balanced)
```

### TUI-Specific Adaptations

1. **No collapse to stack**: Terminal width is typically sufficient; no automatic collapsing like on iPhone.
2. **Column width**: Fixed character widths via `.navigationSplitViewColumnWidth(_:)` modifier.
3. **Separator**: Vertical line (`│`) between columns, using border color from palette.
4. **Focus integration**: Each column registers as a focus section; Tab cycles columns.

## Design

### Type Hierarchy

```
NavigationSplitView<Sidebar, Content, Detail>
├── NavigationSplitViewVisibility (struct)
│   ├── .automatic
│   ├── .all
│   ├── .doubleColumn
│   └── .detailOnly
├── NavigationSplitViewColumn (struct)
│   ├── .sidebar
│   ├── .content
│   └── .detail
└── NavigationSplitViewStyle (protocol)
    ├── AutomaticNavigationSplitViewStyle
    ├── BalancedNavigationSplitViewStyle
    └── ProminentDetailNavigationSplitViewStyle
```

### Column Layout Algorithm

Terminal width minus separators is distributed among visible columns:

```
Two-column (sidebar + detail):
┌─────────────┬───────────────────────────────┐
│   Sidebar   │            Detail             │
│   (1/3)     │            (2/3)              │
└─────────────┴───────────────────────────────┘

Three-column (sidebar + content + detail):
┌─────────┬─────────────┬─────────────────────┐
│ Sidebar │   Content   │       Detail        │
│  (1/4)  │    (1/4)    │       (2/4)         │
└─────────┴─────────────┴─────────────────────┘
```

Default proportions (customizable via `.navigationSplitViewColumnWidth()`):
- Two-column: sidebar 1/3, detail 2/3
- Three-column: sidebar 1/4, content 1/4, detail 2/4

Minimum column width: 10 characters (prevents unusable narrow columns).

### Focus Section Integration

Each visible column registers as a separate focus section:

```swift
// During render, NavigationSplitView registers:
focusManager.registerSection(id: "nav-split-sidebar")
focusManager.registerSection(id: "nav-split-content")  // if 3-column
focusManager.registerSection(id: "nav-split-detail")
```

Tab navigation cycles between columns. Up/Down navigates within each column's focusable elements.

### Rendering Strategy

NavigationSplitView is a **composite View** (like Box), not Renderable:

```swift
public struct NavigationSplitView<Sidebar: View, Content: View, Detail: View>: View {
    public var body: some View {
        _NavigationSplitViewCore(...)
    }
}

private struct _NavigationSplitViewCore: View, Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // 1. Calculate column widths based on visibility and style
        // 2. Render each visible column into separate buffers
        // 3. Join buffers horizontally with separator characters
        // 4. Return combined buffer
    }
}
```

### Visibility Behavior

| Visibility | Two-Column | Three-Column |
|------------|------------|--------------|
| `.automatic` | Show both | Show all |
| `.all` | Show both | Show all |
| `.doubleColumn` | Show both | Hide sidebar, show content + detail |
| `.detailOnly` | Show detail only | Show detail only |

### Style Behavior

| Style | Effect |
|-------|--------|
| `.automatic` | Platform default (balanced in TUI) |
| `.balanced` | Columns share space proportionally |
| `.prominentDetail` | Detail gets more space; leading columns narrower |

## Implementation Plan

### Phase 1: Core Types

1. Create `NavigationSplitViewVisibility` struct with static properties
2. Create `NavigationSplitViewColumn` struct with static properties
3. Create `NavigationSplitViewStyle` protocol and concrete types
4. Add environment key for style

### Phase 2: NavigationSplitView (Two-Column)

1. Create `NavigationSplitView` with `init(sidebar:detail:)` and `init(columnVisibility:sidebar:detail:)`
2. Implement `_NavigationSplitViewCore` with Renderable
3. Column width calculation (1/3 + 2/3 default)
4. Vertical separator rendering
5. Focus section registration per column

### Phase 3: NavigationSplitView (Three-Column)

1. Add `init(sidebar:content:detail:)` overloads
2. Extend layout algorithm for three columns
3. Update focus section registration

### Phase 4: Column Width Modifier

1. Create `NavigationSplitViewColumnWidthModifier`
2. Add `.navigationSplitViewColumnWidth(_:)` convenience
3. Add `.navigationSplitViewColumnWidth(min:ideal:max:)` convenience
4. Environment key for column width preferences

### Phase 5: Style Modifier

1. Implement `.navigationSplitViewStyle(_:)` modifier
2. Apply style during layout calculation

### Phase 6: Tests

1. Visibility state tests
2. Column layout tests (2-column and 3-column)
3. Focus section integration tests
4. Style application tests
5. Column width modifier tests

## Completed

**Date:** 2026-02-10

## Checklist

- [x] Phase 1: NavigationSplitViewVisibility, NavigationSplitViewColumn, NavigationSplitViewStyle
- [x] Phase 2: Two-column NavigationSplitView with focus sections
- [x] Phase 3: Three-column support
- [x] Phase 4: Column width modifier
- [x] Phase 5: Style modifier
- [x] Phase 6: Tests (39 tests in 8 suites)

## Files

### New Files

- `Sources/TUIkit/Views/NavigationSplitView.swift`
- `Sources/TUIkit/Styles/NavigationSplitViewStyle.swift`
- `Sources/TUIkit/Modifiers/NavigationSplitViewColumnWidthModifier.swift`
- `Tests/TUIkitTests/NavigationSplitViewTests.swift`

### Modified Files

- `Sources/TUIkit/Rendering/Renderable.swift` (added `withAvailableWidth` helper)

## Open Questions

1. **Separator character**: Use `│` (light) or `┃` (heavy)? Recommendation: follow current `Appearance` border style.
2. **Minimum terminal width**: Should NavigationSplitView refuse to render if terminal is too narrow (e.g., < 40 chars)? Recommendation: collapse to detail-only below threshold.
3. **Column resize handles**: Not applicable in TUI (no mouse), but should keyboard shortcuts exist (e.g., `[` / `]` to resize)? Recommendation: defer to future enhancement.

---
**Created:** 2026-02-10
