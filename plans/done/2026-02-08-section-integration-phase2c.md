# Section Integration with List (List SwiftUI API Parity Phase 2c)

## Preface

Phase 2c integrates Section headers/footers into List's row rendering while maintaining SwiftUI API parity. The key insight: Section headers/footers are non-selectable visual separators, while content items within sections are individually selectable and focusable. Current architecture treats entire Sections as single rows; this plan flattens Section structure into individual row types with focus navigation that skips non-selectable headers/footers. Alternating row colors now restart per section.

## Completed

**Date:** 2026-02-08

All implementation phases completed:
- Phase 2c1: SelectableListRow + ListRowType enum
- Phase 2c2: ItemListHandler skip logic with selectableIndices
- Phase 2c3: List integration with Section flattening

---

## Checklist

- [x] SelectableListRow.swift created with ListRowType enum + SelectableListRow struct
- [x] List.extractRows() updated to detect and flatten Sections
- [x] List.extractRows() classifies rows with SelectableListRow type-safe structure
- [x] ItemListHandler.selectableIndices property added and integrated
- [x] ItemListHandler.moveFocus() updated with skip logic for non-selectable rows
- [x] List.renderToBuffer() builds selectableIndices set and passes to handler
- [x] List.renderRow() receives SelectableListRow and handles type-specific styling
- [x] Headers/footers render with dimmed styling, never show selection background
- [x] Alternating colors reset per section
- [x] Focus navigation skips non-selectable rows (Up/Down arrow keys)
- [x] Selection binding excludes header/footer IDs (content rows only)
- [x] SectionListIntegrationTests passing
- [x] `swift build` + `swiftlint` clean
- [x] All previous tests still passing (no regression)
- [x] Plan moved to `done/` with completion date
- [x] `to-dos.md` and `whats-next.md` updated

---

## Critical Files

| File | Changes |
|------|---------|
| `Sources/TUIkit/Core/SelectableListRow.swift` | NEW: ListRowType enum + SelectableListRow struct |
| `Sources/TUIkit/Views/List.swift` | Extract/flatten sections, classify rows by type, reset alt-colors per section |
| `Sources/TUIkit/Focus/ItemListHandler.swift` | Skip logic for non-selectable rows in moveFocus() |
| `Tests/TUIkitTests/SectionListIntegrationTests.swift` | NEW: Integration tests |

## Design Decisions

1. **Row Type Representation**: Structured Metadata with ListRowType enum
   - Headers/footers marked as `.header` / `.footer` (non-selectable)
   - Content rows marked as `.content(id)` (selectable/focusable)
   - Compile-time safety, no string matching
