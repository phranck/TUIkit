# What's Next

## Status Snapshot

- **Branch**: main
- **Active Task**: Project analysis running (background agent)
- **Status**: pending
- **Last Updated**: 2026-02-14T12:30:00Z

## Current Checkpoint

- **File**: N/A
- **What**: Image View feature merged (PR #90). Project analysis agent running in background.
- **Phase**: N/A

## Blockers

- (None)

## Next Steps (Immediate Actions)

1. **Review project analysis report** (papers/project_analysis.md, once background agent completes)
2. **State Persistence** (@RestoredState property wrapper, crash recovery)
3. **DisclosureGroup** (expandable/collapsible sections)
4. **Phase 5 Revisited** (File splitting for maintainability, when resources allow)

## Open Plans (Next Priority Queue)

| # | Plan | Effort | Impact | Status |
|---|------|--------|--------|--------|
| 1 | State Persistence (Session Continuity) | Medium | Medium | Not Started |
| 2 | DisclosureGroup | Medium | Medium | Not Started |
| 3 | Phase 5 Revisited (File Splitting) | Low | Low | Deferred |

---

## In Progress

- [ ] **Project Analysis**: Background agent examining architecture, redundancies, dead code, documentation gaps

## Open (Backlog)

### Components
- [ ] **DisclosureGroup**: Expandable/collapsible sections
- [ ] **Phase 5 Revisited**: List.swift file splitting (deferred, low priority)

### Infrastructure
- [ ] **State Persistence**: @RestoredState wrapper, crash recovery

### Performance & Docs
- [ ] **`View._printChanges()` Equivalent**: Debug mechanism
- [ ] **Example App Redesign**: Feature catalog improvements

## Completed

- **2026-02-14**: Image View feature merged (PR #90)
  - Image view with ASCII art rendering (blocks, ASCII, braille character sets)
  - trueColor, ANSI-256, grayscale, mono color modes + Floyd-Steinberg dithering
  - Async image loading from files and URLs with caching
  - ContentMode enum + aspectRatio(_:contentMode:) modifier
  - Bracketed paste mode for bulk text insertion
  - TextContentType modifier for input character filtering (8 types)
  - Text-input priority in key dispatch architecture
  - Image demo pages in example app, DocC documentation updated
  - 1064 tests passing, 148 suites
- **2026-02-13**: Codebase Quality & SwiftUI API Parity complete (Phases 1-6)
  - Phase 1+2: FocusID collision bugs fixed (6 Views), auto-generated from context.identity.path
  - Phase 3: Disabled-state already consistent across 9 Views
  - Phase 4: List API modifiers already implemented
  - Phase 6: SecureField made generic with ViewBuilder-Label initializer
  - Phase 5: File splitting deferred
- **2026-02-13**: Two-Pass Layout system complete (Phases 1-4)
- **2026-02-13**: Consolidated plans/, standardized AI tool instructions, added SessionStart hook
- **2026-02-13**: Code audit cleanup: withPersistentBackground, List/Table renderRow decomposition

## Notes

- Image feature includes CSTBImage C target (stb_image) for cross-platform image decoding
- Bracketed paste: Terminal wraps pasted text in ESC[200~...ESC[201~ markers
- TextContentType filters both typed and pasted input per content type
- Key dispatch: Text-input elements get priority before status bar and other layers
- Tests: 1064 / 148 suites, all green
- Background analysis agent running: will produce papers/project_analysis.md

**Last Updated**: 2026-02-14T12:30:00Z
