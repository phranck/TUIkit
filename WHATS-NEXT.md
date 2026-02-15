# What's Next

## Status Snapshot

- **Branch**: main
- **Active Task**: None
- **Status**: pending
- **Last Updated**: 2026-02-15T01:55:00Z

## Current Checkpoint

- **File**: Sources/TUIkit/TUIkit.docc/theme-settings.json
- **What**: Completed DocC theme with TUIkit green palette colors, colorful syntax highlighting, Nunito font
- **Phase**: N/A

## Blockers

- (None)

## Next Steps (Immediate Actions)

1. Localization Tests Fix (plan exists in .claude/plans/)
2. Test Coverage (ASCIIConverter, RGBAImage, Notification, Extensions)
3. State Persistence (@RestoredState property wrapper, crash recovery)
4. DisclosureGroup component

---

## In Progress

(None)

## Open (Backlog)

### Bugs / Fixes
- [ ] **Localization Tests Fix**: Deadlock in LocalizationService.string(for:), init() side effects (plan ready)

### Test Coverage
- [ ] **ASCIIConverter Tests**: Complete test coverage
- [ ] **RGBAImage Tests**: Complete test coverage
- [ ] **Notification Tests**: Complete test coverage
- [ ] **Extensions Tests**: Complete test coverage

### Components
- [ ] **DisclosureGroup**: Expandable/collapsible sections

### Infrastructure
- [ ] **State Persistence**: @RestoredState wrapper, crash recovery

### Performance & Docs
- [ ] **`View._printChanges()` Equivalent**: Debug mechanism
- [ ] **Example App Redesign**: Feature catalog improvements

## Completed

- **2026-02-15**: DocC theme-settings.json with full TUIkit green palette (130+ color variables, light/dark), Nunito font, colorful Xcode-inspired syntax highlighting
- **2026-02-15**: Rebuilt all 10 DocC diagrams with Typst (fletcher), replacing Mermaid/D2 for better quality. Transparent backgrounds, Style D arrows, top-down layouts.
- **2026-02-14**: Audited all DocC diagrams against code: fixed 7 diagrams, corrected text in 3 articles
- **2026-02-14**: Created Architecture.md event loop + input dispatch diagrams from code analysis
- **2026-02-14**: Converted KeyboardShortcuts.md ASCII diagram to rendered PNG (light/dark)
- **2026-02-14**: Fixed LocalizationService: NSLock deadlock, wrong Bundle path, init() side effects. Re-enabled all 42 localization tests. 1111 tests / 151 suites passing.

## Notes

- Tests: 1111 / 151 suites, all green
- DocC diagrams: All now Typst-rendered (fletcher package) with transparent backgrounds, light/dark variants
- Typst workflow: .typ → typst compile --ppi 288 → PNG (light + ~dark) → @Image in DocC
- DocC theme: Full green palette theming, Nunito font, Xcode-inspired syntax colors
- Localization Tests fix plan: `.claude/plans/twinkly-kindling-dongarra.md`
- **Next Focus**: Localization deadlock fix or test coverage expansion

**Last Updated**: 2026-02-15T01:55:00Z
