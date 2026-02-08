# List and Table Components

Build scrollable, navigable data collections with keyboard support.

## Overview

TUIkit provides two components for displaying collections of data:

- **List**: A vertical collection of arbitrary view content with selection support
- **Table**: A columnar data display with headers and configurable column widths

Both components share the same keyboard navigation and selection infrastructure, providing a consistent user experience.

## List

`List` displays a vertical collection of items inside a bordered container. It supports:
- Optional title in the border
- Optional footer section
- Single or multi-selection
- Keyboard navigation
- Automatic scrolling with viewport management

### Basic Usage

```swift
struct ContentView: View {
    @State var selectedID: String?
    
    let items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    
    var body: some View {
        List("Fruits", selection: $selectedID) {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
    }
}
```

### With Footer

Add action buttons or status text in a footer section:

```swift
List("Tasks", selection: $selectedTask) {
    ForEach(tasks) { task in
        Text(task.title)
    }
} footer: {
    ButtonRow {
        Button("Add") { addTask() }
        Button("Remove") { removeTask() }
    }
}
```

### Multi-Selection

Use a `Set` binding for multi-selection mode:

```swift
@State var selectedIDs: Set<String> = []

List("Files", selection: $selectedIDs) {
    ForEach(files) { file in
        HStack {
            Text(file.icon)
            Text(file.name)
        }
    }
}
```

### Visual States

List rows display different visual states:

| State | Appearance |
|-------|------------|
| Focused + Selected | Pulsing accent background |
| Focused only | Highlight background bar |
| Selected only | Subtle accent background |
| Neither | Default appearance |

## Table

`Table` displays tabular data with column headers, alignment, and configurable widths.

### Basic Usage

```swift
struct FileInfo: Identifiable {
    let id: String
    let name: String
    let size: String
    let modified: String
}

struct ContentView: View {
    @State var selectedFile: String?
    let files: [FileInfo] = [...]
    
    var body: some View {
        Table(files, selection: $selectedFile) {
            TableColumn("Name", value: \.name)
            TableColumn("Size", value: \.size)
                .width(.fixed(10))
                .alignment(.trailing)
            TableColumn("Modified", value: \.modified)
        }
    }
}
```

### Column Configuration

Columns support three width modes:

```swift
TableColumn("Name", value: \.name)
    .width(.flexible)        // Shares remaining space (default)

TableColumn("Size", value: \.size)
    .width(.fixed(12))       // Exactly 12 characters

TableColumn("Progress", value: \.progress)
    .width(.ratio(0.3))      // 30% of available width
```

### Column Alignment

Align column content to leading, center, or trailing:

```swift
TableColumn("Amount", value: \.amount)
    .alignment(.trailing)    // Right-align numbers
```

## Keyboard Navigation

Both List and Table support the same keyboard shortcuts:

| Key | Action |
|-----|--------|
| Up | Move focus up (wraps to end) |
| Down | Move focus down (wraps to start) |
| Home | Jump to first item |
| End | Jump to last item |
| Page Up | Move up by viewport height |
| Page Down | Move down by viewport height |
| Enter / Space | Toggle selection |

## Scroll Indicators

When content extends beyond the viewport, scroll indicators appear:

```
┌─ My List ────────────────────┐
│         ▲ more above         │
│ Item 5                       │
│ Item 6                       │
│ Item 7                       │
│         ▼ more below         │
└──────────────────────────────┘
```

## Disabled State

Disable a list or table to prevent interaction:

```swift
List("Items", selection: $selected) {
    ForEach(items) { item in
        Text(item.name)
    }
}
.disabled(isLoading)
```

## Environment Propagation

Modifiers applied to List or Table propagate to their content:

```swift
List("Items", selection: $selected) {
    ForEach(items) { item in
        Text(item.name)  // Inherits red foreground
    }
}
.foregroundColor(.red)
```

## See Also

- ``List``
- ``Table``
- ``TableColumn``
- ``ForEach``
- <doc:FocusSystem>
