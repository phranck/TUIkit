# SwiftTUI - Current Status

## Date
2026-01-28

## Last work context
**Session Focus: Major feature additions and bug fixes**

Added several major systems:
- **Theming System** with 8 predefined themes (Phosphor variants, ncurses, Dark/Light)
- **Lifecycle Modifiers** (onAppear, onDisappear, task)
- **Storage System** (@AppStorage, @SceneStorage) with Linux support
- **Preferences System** for bottom-up data flow
- **Flexible Frame** with minWidth/maxWidth/maxHeight/.infinity
- **Linux Compatibility** (Glibc, XDG paths, UserDefaults emulation)

Fixed critical bugs:
- Render loop caused by statusBarItems modifier
- q-quit not working when StatusBar item has no action
- Overlay/Border extending beyond terminal bounds
- StatusBar .justified alignment uneven at edges

## Active tasks
- [ ] FocusManager: Refactor from singleton to Environment-based
- [ ] Commit current changes (Theme system)
- [ ] Open PR for `feature/tview-foundation`

## Next steps
1. **Commit Theme system** - Current uncommitted changes
2. **FocusManager Refactoring** - Move to Environment (fixes parallel test issues)
3. **TextField View** - Text input with cursor management
4. **ScrollView** - Scrollable content area
5. **Improve HStack** - Two-pass layout (measure, then position)

## Open questions/blockers
- `AppState.shared` is still a singleton - should be replaced with Environment-based render trigger
- Should `DefaultTheme` be renamed to `ANSITheme`? What should be the actual default?
- HStack layout needs two-pass measurement for proper Spacer behavior

## Important decisions
- **No singletons for state** - Use Environment system instead
- **Theming via Environment** - `\.theme` environment key, not ThemeManager singleton
- **Linux support** - Full compatibility with XDG paths and JSON storage
- **16M color support** - RGB, Hex (string and integer), HSL colors
- **Predefined themes** - Phosphor variants (Green, Amber, White, Red), ncurses, Dark, Light

## Notes
- Run tests with `swift test --no-parallel` (FocusManager singleton issue)
- 178 tests across 26 suites, all passing
- Theme colors accessible via `Color.theme.foreground` or `@Environment(\.theme)`
- StatusBar items set via `.statusBarItems()` modifier (silent, no render loop)
