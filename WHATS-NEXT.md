# What's Next

## Status Snapshot

- **Branch**: main
- **Active Task**: None
- **Status**: pending
- **Last Updated**: 2026-02-14T18:45:00Z

## Current Checkpoint

- **File**: N/A
- **What**: Project analysis improvements P1-P3 complete. All 15 topics addressed.
- **Phase**: N/A

## Blockers

- (None)

## Next Steps (Immediate Actions)

1. **P4 Long-term Architecture** (DI for singletons, generic ItemListHandler, Equatable safety)
2. ~~**Additional Cleanup**~~ (done: Foundation imports removed, files split)
3. **Test Coverage** (ASCIIConverter, RGBAImage, Notification, Extensions)
4. **State Persistence** (@RestoredState property wrapper, crash recovery)
5. **DisclosureGroup** (expandable/collapsible sections)

## Open Plans (Next Priority Queue)

| # | Plan | Effort | Impact | Status |
|---|------|--------|--------|--------|
| 1 | Project Analysis P4 (Long-term Architecture) | Large | High | Not Started |
| 2 | State Persistence (Session Continuity) | Medium | Medium | Not Started |
| 3 | DisclosureGroup | Medium | Medium | Not Started |
| 4 | Phase 5 Revisited (File Splitting) | Low | Low | Done |

---

## In Progress

(None)

## Open (Backlog)

### Project Analysis Remaining (P4 + Additional)
- [ ] **P4.16**: Replace RenderNotifier.current global with dependency injection
- [ ] **P4.17**: Generic ItemListHandler to preserve type safety
- [ ] **P4.18**: Evaluate MainActor.assumeIsolated in Equatable safety
- [ ] **P4.19**: Add image size limits and URL timeout configuration
- [x] **P4.20**: Split framework into multiple Swift package modules (done: TUIkitCore, TUIkitStyling, TUIkitView, TUIkitImage, CSTBImage)
- [x] **Additional**: Remove unnecessary `import Foundation` (9 files), split 500+ line files (Focus.swift, StatusBarItem.swift, ASCIIConverter.swift)
- [ ] **Additional**: Test coverage for ASCIIConverter, RGBAImage, Notification, Extensions

### Components
- [ ] **DisclosureGroup**: Expandable/collapsible sections
- [x] **Phase 5 Revisited**: File splitting complete (Focus.swift → 3, StatusBarItem.swift → 3, ASCIIConverter.swift → 3)

### Infrastructure
- [ ] **State Persistence**: @RestoredState wrapper, crash recovery

### Performance & Docs
- [ ] **`View._printChanges()` Equivalent**: Debug mechanism
- [ ] **Example App Redesign**: Feature catalog improvements

## Completed

- **2026-02-14**: Cleanup: removed unnecessary `import Foundation` (9 files), split 3 files over 500 lines into 9 files
- **2026-02-14**: README.md updated (multi-module structure, new components, macOS 14+ requirement, module imports)
- **2026-02-14**: Project analysis improvements P1-P3 complete (592f5c1)
  - P1: ViewConstants enum (opacity, strings, EdgeInsets), file header standardization
  - P2: Selection binding helper, short variable renames, StatusBarItem split, ANSI sanitization
  - P3: ButtonProvider protocol (replaced Mirror), process name sanitization, docs reviewed
  - Plan with full checklist: .claude/plans/open/2026-02-14-project-analysis-improvements.md
  - 15/29 topics complete, 14 remaining (P4 long-term + additional cleanup)
- **2026-02-14**: Image View feature merged (PR #90)
  - Image view with ASCII art rendering (blocks, ASCII, braille character sets)
  - trueColor, ANSI-256, grayscale, mono color modes + Floyd-Steinberg dithering
  - Async image loading from files and URLs with caching
  - ContentMode enum + aspectRatio(_:contentMode:) modifier
  - Bracketed paste mode, TextContentType modifier, text-input priority in key dispatch
- **2026-02-13**: Codebase Quality & SwiftUI API Parity complete (Phases 1-6)
- **2026-02-13**: Two-Pass Layout system complete (Phases 1-4)
- **2026-02-13**: Consolidated plans/, standardized AI tool instructions, added SessionStart hook
- **2026-02-13**: Code audit cleanup: withPersistentBackground, List/Table renderRow decomposition

## Notes

- Tests: 1071 / 148 suites, all green
- Project analysis report: papers/project_analysis.md
- Improvement plan: .claude/plans/open/2026-02-14-project-analysis-improvements.md
- P3.11 and P3.14 resolved as "already adequate" after detailed review (no code changes needed)

**Last Updated**: 2026-02-14T18:45:00Z
