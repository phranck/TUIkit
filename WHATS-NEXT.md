# What's Next

## Status Snapshot

- **Branch**: main
- **Active Task**: None (Codebase Quality refactoring complete)
- **Status**: pending
- **Last Updated**: 2026-02-13T21:45:00Z

## Current Checkpoint

- **File**: N/A
- **What**: Codebase Quality & SwiftUI API Parity refactoring complete (Phases 1-6, Phase 5 deferred)
- **Phase**: N/A

## Blockers

- (None)

## Next Steps (Immediate Actions)

1. **Bundle Resource Loading** (SPM integration, TUIResource type-safe accessors)
2. **Image View with ASCII Art** (24-bit color rendering, 6 phases)
3. **State Persistence** (@RestoredState property wrapper, crash recovery)
4. **Phase 5 Revisited** (File splitting for maintainability, when resources allow)

## Open Plans (Next Priority Queue)

| # | Plan | Effort | Impact | Status |
|---|------|--------|--------|--------|
| 1 | Bundle Resource Loading Support | Medium | Medium | Not Started |
| 2 | Image View with ASCII Art Rendering | High | High | Not Started |
| 3 | State Persistence (Session Continuity) | Medium | Medium | Not Started |

---

## In Progress

(None - all refactoring complete)

## Open (Backlog)

### Infrastructure
- [ ] **Bundle Resource Loading**: SPM integration, type-safe TUIResource accessors (plan complete)
- [ ] **Image View**: ASCII art rendering with 24-bit true color (plan complete, 6 phases)
- [ ] **State Persistence**: @RestoredState wrapper, crash recovery (plan complete)

### Components
- [ ] **DisclosureGroup**: Expandable/collapsible sections
- [ ] **Phase 5 Revisited**: List.swift file splitting (deferred, low priority)

### Performance & Docs
- [ ] **`View._printChanges()` Equivalent**: Debug mechanism
- [ ] **Example App Redesign**: Feature catalog improvements
- [ ] **Mobile/Tablet Docs**: Test DocC on mobile devices

## Completed

- **2026-02-13**: Codebase Quality & SwiftUI API Parity complete (Phases 1-6)
  - Phase 1+2: FocusID collision bugs fixed (6 Views), auto-generated from context.identity.path
  - Phase 3: Disabled-state already consistent across 9 Views
  - Phase 4: List API modifiers already implemented (.focusID, .listEmptyPlaceholder, .listFooterSeparator)
  - Phase 6: SecureField made generic with ViewBuilder-Label initializer
  - Phase 5: File splitting deferred (List.swift dependencies too complex)
  - 1037/1037 tests passing, 2 commits pushed to main
- **2026-02-13**: Two-Pass Layout system complete (Phases 1-4, Phase 5 deferred). 1034+ tests passing.
- **2026-02-13**: Consolidated plans/ to .claude/plans/, standardized AI tool instruction files, added SessionStart hook
- **2026-02-13**: Code audit cleanup: withPersistentBackground, List/Table renderRow decomposition

## Notes

- Codebase Quality findings: Most infrastructure already in place, minimal changes needed
- Focus registration consolidated in FocusRegistration.swift (reusable helper)
- Disabled-state pattern unified: canBeFocused flag + 0.5 opacity tertiary color
- SwiftUI API parity achieved: Modifiers already implemented, ViewBuilder support added
- Tests: 1037 / 143 suites, all green
- Architecture: Clean, maintainable, follows Swift 6.0 conventions

**Last Updated**: 2026-02-13T21:45:00Z
