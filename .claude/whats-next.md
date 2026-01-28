# TUIKit - Current Status

## Date
2026-01-28

## Last work context
**Session Focus: Package Rename from SwiftTUI to TUIKit**

Renamed the entire package due to name collision with existing rensbreur/SwiftTUI:
- Package name: SwiftTUI -> TUIKit
- Library target: SwiftTUI -> TUIKit
- Example target: SwiftTUIExample -> TUIKitExample
- Test target: SwiftTUITests -> TUIKitTests
- All imports updated
- All code references updated
- Documentation updated

Also completed FocusManager refactoring earlier in session:
- Removed FocusManager.shared singleton
- FocusManager now injected via Environment (\.focusManager)
- Tests can run in parallel

## Active tasks
- [ ] Open PR for `feature/tview-foundation`

## Next steps
1. **Open PR** - Merge feature/tview-foundation to main
2. **TextField View** - Text input with cursor management
3. **ScrollView** - Scrollable content area
4. **Improve HStack** - Two-pass layout (measure, then position)

## Open questions/blockers
- `AppState.shared` is still a singleton - should be replaced with Environment-based render trigger
- Should `DefaultTheme` be renamed to `ANSITheme`? What should be the actual default?

## Important decisions
- **Package name: TUIKit** - Apple-style naming (like UIKit, AppKit)
- **No singletons for state** - Use Environment system instead
- **FocusManager via Environment** - `\.focusManager` environment key

## Notes
- Run tests with `swift test` (parallel works!)
- 181 tests across 27 suites, all passing
- Import with `import TUIKit`
- Version variable: `tuiKitVersion`

## Commits this session
- `5b54c26` - refactor: Replace FocusManager singleton with Environment-based injection
- `ca977c3` - refactor: Rename package from SwiftTUI to TUIKit
