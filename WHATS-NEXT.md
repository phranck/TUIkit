# What's Next

## Status Snapshot

- **Branch**: refactor/code-audit-cleanup
- **Active Task**: None (session tasks completed)
- **Status**: pending
- **Last Updated**: 2026-02-13T17:30:00Z

## Current Checkpoint

- **File**: N/A
- **What**: Plans consolidation and AI tool instruction standardization complete
- **Phase**: N/A

## Blockers

- (None)

## Next Steps (Immediate Actions)

1. **Codebase Quality Phase 1-2:** Extract FocusRegistration helper, standardize FocusID generation (removes ~80 LOC duplikation across 9 Views)
2. **Codebase Quality Phase 3-4:** Unify disabled-state handling, simplify List API with Modifiers
3. Create PR for two-pass-layout Phase 5 (Remove hasExplicitWidth/Height) - separate PR, low urgency
4. Start Bundle Resource Loading (SPM integration, TUIResource accessors)

## Open Plans (Prioritized)

| # | Plan | File | Effort | Impact |
|---|------|------|--------|--------|
| 1 | Codebase Quality & SwiftUI API Parity | `.claude/plans/open/2026-02-13-codebase-refactoring.md` | Med/High | High |
| 2 | Bundle Resource Loading Support | `.claude/plans/open/2026-02-10-bundle-resource-loading.md` | Medium | Medium |
| 3 | Image View with ASCII Art Rendering | `.claude/plans/open/2026-02-10-image-view-ascii-art.md` | High | High |
| 4 | State Persistence (Session Continuity) | `.claude/plans/open/2026-02-02-state-persistence.md` | Medium | Medium |

---

## In Progress

(None)

## Open (Backlog)

### Components

- [ ] **Image View**: ASCII art rendering with full 24-bit color support (plan complete)
- [ ] **Bundle Resource Loading**: SPM resource integration for Image support (plan complete, deferred)
- [ ] **DisclosureGroup**: Expandable/collapsible sections

### Performance

- [ ] **`View._printChanges()` Equivalent**: Debug mechanism that logs why body was re-evaluated

### Infrastructure

- [ ] **Example App Redesign**: Feature catalog to multiple small example apps
- [ ] **Two-Pass Layout Focus Fix**: Verify TextField focus works correctly after isMeasuring flag fix

### Testing & Docs

- [ ] **Mobile/Tablet Docs**: Test DocC on mobile devices (landing page done)
- [ ] **Code Examples**: Counter, Todo List, Form, Table/List

## Completed

- **2026-02-13**: Two-Pass Layout system complete (Phases 1-4, Phase 5 deferred to separate PR). 1034+ tests passing, layout algorithm fixes TextField + HStack overflow bugs.
- **2026-02-13**: Consolidated plans/ to .claude/plans/, standardized AI tool instruction files (CONTRIBUTING.md, PR template, AGENTS.md, Cursor rules, Windsurf rules, copilot-instructions rewrite), added SessionStart hook for auto /remember
- **2026-02-13**: Code audit cleanup: withPersistentBackground extension, List/Table renderRow decomposition, String+ANSI refactoring
- **2026-02-11**: Two-Pass Layout Focus Bug: Added isMeasuring flag to prevent double focus registration
- **2026-02-10**: TextField Clipboard & Undo: Ctrl+A/C/X/V/Z, clipboard via pbcopy/xclip, 50-state undo stack
- **2026-02-10**: NavigationSplitView: Two/three-column layouts, visibility control, focus sections, 39 tests

## Notes

- DocC: `swift-docc-plugin`, GitHub Pages with `theme-settings.json` workaround
- Landing Page: Astro + React + Tailwind 4, CI-deployed, tuikit.layered.work
- Xcode Template: `~/Library/Developer/Xcode/Templates/Project Templates/macOS/Application/`
- Tests: 1037 / 143 suites, build clean

**Last Updated**: 2026-02-13T17:30:00Z
