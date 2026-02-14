# What's Next

## Status Snapshot

- **Branch**: main
- **Active Task**: P4.16 (Replace RenderNotifier.current with dependency injection) — COMPLETE
- **Status**: completed
- **Last Updated**: 2026-02-14T21:00:00Z

## Current Checkpoint

- **File**: N/A
- **What**: P4.17 Generic ItemListHandler complete. Git history cleaned (Co-Authored-By trailers removed).
- **Phase**: N/A

## Blockers

- (None)

## Next Steps (Immediate Actions)

1. **P4.16**: Replace RenderNotifier.current global with dependency injection (IN PROGRESS)
2. **Test Coverage** (ASCIIConverter, RGBAImage, Notification, Extensions)
3. **State Persistence** (@RestoredState property wrapper, crash recovery)
4. **DisclosureGroup** (expandable/collapsible sections)
5. **P4.15**: Performance optimization & caching strategies

## Open Plans (Next Priority Queue)

| # | Plan | Effort | Impact | Status |
|---|------|--------|--------|--------|
| 1 | Project Analysis P4 (Long-term Architecture) | Large | High | In Progress |
| 2 | State Persistence (Session Continuity) | Medium | Medium | Not Started |
| 3 | DisclosureGroup | Medium | Medium | Not Started |

---

## In Progress

(None)

## Open (Backlog)

### Project Analysis Remaining (P4 + Additional)
- [x] **P4.16**: Replace RenderNotifier.current global with dependency injection (COMPLETE)
- [x] **P4.17**: Generic ItemListHandler to preserve type safety
- [x] **P4.18**: Evaluate MainActor.assumeIsolated in Equatable safety
- [x] **P4.19**: Add image size limits and URL timeout configuration
- [x] **P4.20**: Split framework into multiple Swift package modules (done: TUIkitCore, TUIkitStyling, TUIkitView, TUIkitImage, CSTBImage)
- [x] **Additional**: Remove unnecessary `import Foundation` (9 files), split 500+ line files (Focus.swift, StatusBarItem.swift, ASCIIConverter.swift)
- [ ] **Additional**: Test coverage for ASCIIConverter, RGBAImage, Notification, Extensions

### Components
- [ ] **DisclosureGroup**: Expandable/collapsible sections

### Infrastructure
- [ ] **State Persistence**: @RestoredState wrapper, crash recovery

### Performance & Docs
- [ ] **`View._printChanges()` Equivalent**: Debug mechanism
- [ ] **Example App Redesign**: Feature catalog improvements

## Completed

- **2026-02-14**: P4.16 Complete elimination of RenderNotifier: AppState.shared and RenderCache.shared singletons replace global registry. Pure singleton architecture. All property wrappers, render consumers, and services use direct singleton access. 1069 tests pass.
- **2026-02-14**: P4.18 Concurrency documentation: added RenderNotifier safety model documentation, Terminal memory operation comments
- **2026-02-14**: P4.17 Generic ItemListHandler: replaced AnyHashable type erasure with generic SelectionValue parameter, removed configureSelectionBindings, type-safe bindings in _ListCore and _TableCore
- **2026-02-14**: Git history cleanup: removed 33 Co-Authored-By trailers from entire history via git filter-repo + force-push
- **2026-02-14**: Cleanup: removed unnecessary `import Foundation` (9 files), split 3 files over 500 lines into 9 files
- **2026-02-14**: README.md updated (multi-module structure, new components, macOS 14+ requirement, module imports)
- **2026-02-14**: Project analysis improvements P1-P3 complete (15/29 topics)
- **2026-02-14**: Image View feature merged (PR #90)
- **2026-02-13**: Codebase Quality & SwiftUI API Parity complete (Phases 1-6)
- **2026-02-13**: Two-Pass Layout system complete (Phases 1-4)
- **2026-02-13**: Consolidated plans/, standardized AI tool instructions, added SessionStart hook
- **2026-02-13**: Code audit cleanup: withPersistentBackground, List/Table renderRow decomposition

## Notes

- Tests: 1069 / 148 suites, all green
- Project analysis report: papers/project_analysis.md
- Improvement plan: .claude/plans/open/2026-02-14-project-analysis-improvements.md
- P3.11 and P3.14 resolved as "already adequate" after detailed review (no code changes needed)

**Last Updated**: 2026-02-14T21:00:00Z
