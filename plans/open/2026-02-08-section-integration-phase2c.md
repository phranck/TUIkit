# Section Integration with List (List SwiftUI API Parity Phase 2c)

## Preface

Phase 2c integrates Section headers/footers into List's row rendering while maintaining SwiftUI API parity. The key insight: Section headers/footers are non-selectable visual separators, while content items within sections are individually selectable and focusable. Current architecture treats entire Sections as single rows; this plan flattens Section structure into individual row types with focus navigation that skips non-selectable headers/footers. Alternating row colors now restart per section.

---

## Current State (Post Phase 2a + 2b)

- **Section view**: Complete SwiftUI-conformant with header/content/footer
- **SectionRowExtractor protocol**: Defined but unused by List
- **List extraction**: Only handles ListRowExtractor (ForEach) and generic ChildInfoProvider
- **ItemListHandler**: Treats all rows as selectable with no skip logic
- **Alternating colors**: Global row index only (no per-section restart)
- **Tests**: 722 passing / 110 suites
- **Architecture gap**: Sections are rendered but not structurally integrated

## Specification / Goal

### Phase 2c: Section Integration (Split into 3 mini-phases)

#### 2c1: Row Type Foundation
1. Create `ListRowType` enum: `.header`, `.content(id)`, `.footer`
2. Create `SelectableListRow` struct with type info + buffer
3. Add computed properties: `isSelectable`, `id`
4. Update List extraction to return SelectableListRow with proper type classification

#### 2c2: ItemListHandler Enhancement
1. Add `selectableIndices: Set<Int>` tracking which rows can be selected/focused
2. Implement skip-logic in `moveFocus()` - jump over non-selectable rows
3. Update selection filtering - only content rows participate in binding
4. Ensure Up/Down arrow keys skip headers/footers cleanly

#### 2c3: List Integration & Rendering
1. Update `List.extractRows()` to detect and expand Sections
2. Flatten Section headers/footers into row sequence
3. Pass row-type info to `renderRow()` for styling
4. Implement per-section alternating color reset
5. Ensure headers/footers never render with selection background

### Architecture Decision: Row Type System (STRUCTURED METADATA)

**Current Problem**: `ListRow<ID>` only stores ID + buffer. Need to distinguish:
- Header rows (non-selectable, dimmed)
- Content rows (selectable, from ForEach or Section content)
- Footer rows (non-selectable, dimmed)

**Solution**: Create `ListRowType` enum for type-safe row classification

```swift
/// Defines the type of a row in a List.
public enum ListRowType<SelectionValue: Hashable>: Sendable {
    /// A section header (non-selectable, non-focusable).
    case header

    /// A content row with a selectable ID.
    case content(id: SelectionValue)

    /// A section footer (non-selectable, non-focusable).
    case footer
}

/// A List row with type information for selection/focus handling.
public struct SelectableListRow<SelectionValue: Hashable>: Sendable {
    /// The row type (header, content with ID, or footer).
    public let type: ListRowType<SelectionValue>

    /// The rendered content buffer.
    public let buffer: FrameBuffer

    /// Computed: is this row selectable?
    public var isSelectable: Bool {
        if case .content = type { return true }
        return false
    }

    /// Computed: the row ID (only for content rows).
    public var id: SelectionValue? {
        if case .content(let id) = type { return id }
        return nil
    }
}
```

**Migration from ListRow to SelectableListRow**:
- Keep `ListRow` as backward-compat alias or internal-only
- Public API uses `SelectableListRow` with typed rows
- ItemListHandler checks `row.isSelectable` instead of ID patterns
- Type-safe, clean intent, no string matching

---

## Implementation Plan

### Phase 2c1: Row Type Foundation

**Files to create/modify:**
1. **NEW: Sources/TUIkit/Core/SelectableListRow.swift**
   - Create `ListRowType<SelectionValue>` enum with 3 cases: header, content(id), footer
   - Create `SelectableListRow<SelectionValue>` struct with type + buffer + computed properties
   - Make both Sendable + Equatable
   - Document: headers/footers are non-selectable, non-focusable; content rows are selectable/focusable

2. **MODIFY: Sources/TUIkit/Views/List.swift**
   - Update internal type from `ListRow<SelectionValue>` to `SelectableListRow<SelectionValue>` throughout
   - Update `extractRows()` to return `[SelectableListRow<SelectionValue>]`
   - Create type-safe row extraction that classifies each row correctly

### Phase 2c2: ItemListHandler Enhancement

**Files to modify:**
1. **MODIFY: Sources/TUIkit/Focus/ItemListHandler.swift**
   - Add `selectableIndices: Set<Int>` property
   - Modify `moveFocus()` method (~line 188):
     ```swift
     func moveFocus(by delta: Int, wrap: Bool) -> Bool {
         guard !items.isEmpty else { return false }
         var newIndex = focusedIndex

         // Skip non-selectable rows
         while !selectableIndices.contains(newIndex) {
             newIndex = ((newIndex + delta) % selectableIndices.count) + offset
             if !wrap && newIndex == focusedIndex { return false }
         }
         focusedIndex = newIndex
         return true
     }
     ```
   - Update `selectionMode` getter to skip non-selectable IDs
   - Add method: `ensureSelectableItemsExist()`

### Phase 2c3: List Integration & Rendering

**Files to modify:**
1. **MODIFY: Sources/TUIkit/Views/List.swift (Major changes)**

   a) **Update `extractRows()` (~line 563)**:
   - Add Section detection: `if let section = content as? SectionRowExtractor { ... }`
   - For each Section:
     - Create header row: `SelectableListRow(type: .header, buffer: headerBuffer)`
     - Extract content rows with: `SelectableListRow(type: .content(id: id), buffer: contentBuffer)`
     - Create footer row: `SelectableListRow(type: .footer, buffer: footerBuffer)`
   - Return rows with type-safe classification

   b) **Update `renderToBuffer()` (~line 420)**:
   - Build `selectableIndices: Set<Int>` during row enumeration
   - Pass to ItemListHandler: `handler.selectableIndices = selectableIndices`
   - Track section boundaries for alternating color reset

   c) **Update `renderRow()` (~line 620)**:
   - Add parameter: `row: SelectableListRow<SelectionValue>`
   - For `.header` or `.footer` rows:
     - Ignore focus/selection state (always render as-is)
     - Apply dimmed styling (palette.foregroundTertiary)
     - Skip alternating color logic
   - For `.content(id)` rows:
     - Reset alternating color counter on section change
     - Apply palette.accent.opacity(0.15) for even indices within section only
     - Apply focus/selection state normally

### Verification & Testing

**New test file: Tests/TUIkitTests/SectionListIntegrationTests.swift**
- [ ] Section headers render with dimmed styling
- [ ] Section footers render with dimmed styling
- [ ] Content rows within Section are individually selectable
- [ ] Focus navigation skips headers/footers (Up/Down arrow)
- [ ] Section headers/footers never show selection background
- [ ] Alternating row colors restart per section
- [ ] Multiple sections with mixed content (ForEach + manual rows)
- [ ] Empty sections render header + footer without content rows
- [ ] Selection binding works on content rows only (not headers/footers)
- [ ] Tab navigation enters/exits sections correctly

**SwiftUI Behavior Parity Checks**:
1. ✓ Headers are non-selectable, non-focusable
2. ✓ Footers are non-selectable, non-focusable
3. ✓ Content rows inside sections are individually selectable
4. ✓ Keyboard navigation: Up/Down skip headers/footers
5. ✓ Alternating colors restart per section (with insetGrouped)
6. ✓ Selection binding excludes header/footer IDs

---

## Critical Files

| File | Changes | Complexity |
|------|---------|-----------|
| `Sources/TUIkit/Core/SelectableListRow.swift` | NEW: ListRowType enum + SelectableListRow struct | Low |
| `Sources/TUIkit/Views/List.swift` | Extract/flatten sections, classify rows by type, reset alt-colors per section | High |
| `Sources/TUIkit/Focus/ItemListHandler.swift` | Skip logic for non-selectable rows in moveFocus() | Medium |
| `Tests/TUIkitTests/SectionListIntegrationTests.swift` | NEW: 10+ integration tests | Medium |

## Design Decisions Made

1. **Row Type Representation**: Structured Metadata (Option B) - DECIDED
   - Use ListRowType enum + SelectableListRow struct for type-safe row classification
   - Headers/footers marked as `.header` / `.footer` (non-selectable)
   - Content rows marked as `.content(id)` (selectable/focusable)
   - Eliminates fragile ID-marker string matching; provides compile-time safety

## Open Questions

1. **Selection Model**: How to handle multi-selection across sections?
   - **Answer**: Selection IDs must be from content rows only; headers/footers never included in binding

3. **Alternating Color Restart**: Should EmptySection (header + footer only) affect sequence?
   - **Answer**: Yes, empty sections reset the counter like any other section

4. **Focus Wrapping**: When at section footer and press Down, should focus wrap to next section header or skip to next section's first content row?
   - **Answer**: Skip to next section's first selectable row (don't stop at headers)

---

## Checklist

- [ ] SelectableListRow.swift created with ListRowType enum + SelectableListRow struct
- [ ] List.extractRows() updated to detect and flatten Sections
- [ ] List.extractRows() classifies rows with SelectableListRow type-safe structure
- [ ] ItemListHandler.selectableIndices property added and integrated
- [ ] ItemListHandler.moveFocus() updated with skip logic for non-selectable rows
- [ ] List.renderToBuffer() builds selectableIndices set and passes to handler
- [ ] List.renderRow() receives SelectableListRow and handles type-specific styling
- [ ] Headers/footers render with dimmed styling, never show selection background
- [ ] Alternating colors reset per section
- [ ] Focus navigation skips non-selectable rows (Up/Down arrow keys)
- [ ] Selection binding excludes header/footer IDs (content rows only)
- [ ] 10+ SectionListIntegrationTests passing
- [ ] `swift build` + `swiftlint` clean
- [ ] All 722 previous tests still passing (no regression)
- [ ] Plan moved to `done/` with completion date
- [ ] `to-dos.md` and `whats-next.md` updated

