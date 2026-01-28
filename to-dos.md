# SwiftTUI — To-Dos

## IN PROGRESS

- [ ] Open PR for `feature/tview-foundation`

## PLANNED

### High Priority
- [ ] FocusManager: Refactor from singleton to Environment-based (fixes parallel tests)
- [ ] AppState: Replace singleton with Environment-based render trigger
- [ ] TextField view with cursor management

### Views & Components
- [ ] ScrollView for scrollable content
- [ ] TabView for tabbed navigation
- [ ] ProgressView (determinate and indeterminate)
- [ ] Toggle/Checkbox view

### Layout
- [ ] HStack: Two-pass layout (measure children, then position)
- [ ] LazyVStack/LazyHStack for large lists
- [ ] Grid layout

### Infrastructure
- [ ] Deduplicate `renderElement` helper across TupleView/ConditionalView/TViewArray
- [ ] Animation system (basic transitions)
- [ ] Accessibility labels

## COMPLETED

### Core Framework
- [x] TView protocol
- [x] TViewBuilder result builder (up to 10 children, conditionals, optionals, arrays)
- [x] Primitive views: Text, EmptyView, Spacer, Divider
- [x] Container views: VStack, HStack, ZStack
- [x] Container views: Card, Box, Panel
- [x] ForEach (Identifiable, KeyPath, Range)
- [x] AnyView type erasure

### Color & Theming (2026-01-28)
- [x] Color system (ANSI, bright, 256-palette, RGB)
- [x] Hex colors (integer and string: "#FF5500", "#F50")
- [x] HSL color support
- [x] Color modifiers: lighter(), darker(), opacity()
- [x] **Theme System**
  - [x] Theme protocol with semantic colors
  - [x] Environment-based (no singleton)
  - [x] 8 predefined themes:
    - DefaultTheme (ANSI)
    - GreenPhosphorTheme (P1)
    - AmberPhosphorTheme (P3)
    - WhitePhosphorTheme (P4)
    - RedPhosphorTheme
    - NCursesTheme
    - DarkTheme
    - LightTheme
  - [x] `.theme()` modifier
  - [x] `Color.theme.foreground` etc. shortcuts

### Text & Styling
- [x] Text styling (bold, italic, underline, strikethrough, dim, blink, inverted)
- [x] Foreground and background colors

### Modifiers
- [x] `.padding()` modifier
- [x] `.frame(width:height:alignment:)` - fixed size
- [x] `.frame(minWidth:maxWidth:minHeight:maxHeight:)` - flexible size
- [x] `.border()` modifier (8 border styles, width-aware)
- [x] `.background()` modifier
- [x] `.overlay(alignment:)` modifier
- [x] `.dimmed()` modifier
- [x] `.modal()` convenience helper
- [x] `.onKeyPress()` modifier
- [x] `.statusBarItems()` modifier
- [x] `.environment()` modifier
- [x] `.theme()` modifier

### Lifecycle (2026-01-28)
- [x] `.onAppear()` modifier
- [x] `.onDisappear()` modifier
- [x] `.task()` async modifier

### State & Data Flow
- [x] @TState property wrapper
- [x] Binding for two-way data flow
- [x] **Environment System** (top-down)
  - [x] @Environment property wrapper
  - [x] EnvironmentValues container
  - [x] EnvironmentKey protocol
  - [x] .environment() modifier
- [x] **Preferences System** (bottom-up)
  - [x] PreferenceKey protocol
  - [x] .preference() modifier
  - [x] .onPreferenceChange() modifier
  - [x] .navigationTitle() convenience

### Storage (2026-01-28)
- [x] @AppStorage property wrapper (persistent settings)
- [x] @SceneStorage property wrapper (scene state restoration)
- [x] JSONFileStorage backend
- [x] UserDefaultsStorage (macOS + Linux emulation)
- [x] StorageBackend protocol

### Interactive Views
- [x] Button view with action handler
- [x] ButtonRow for horizontal button groups
- [x] ButtonStyle presets (default, primary, destructive, success, plain)
- [x] Focus system with Tab/Shift+Tab navigation
- [x] Menu view with items, selection, shortcuts

### Overlays & Alerts
- [x] Alert view (with warning/error/info/success presets)
- [x] Dialog view
- [x] FrameBuffer character-level compositing

### Status Bar
- [x] TStatusBar view (compact and bordered styles)
- [x] TStatusBarItem with shortcut, label, action
- [x] Shortcut constants (Unicode symbols)
- [x] Context stack for modals (push/pop)
- [x] StatusBarState via Environment (not singleton)

### Rendering
- [x] Terminal abstraction (raw mode, alternate screen, cursor, I/O)
- [x] ANSI escape code renderer
- [x] Renderable protocol with RenderContext
- [x] ViewRenderer with tree traversal
- [x] FrameBuffer with compositing

### App Lifecycle
- [x] TApp/TScene/WindowGroup
- [x] AppRunner with run loop
- [x] Signal handlers (SIGINT, SIGWINCH)

### Platform Support (2026-01-28)
- [x] macOS support (10.15+)
- [x] **Linux support**
  - [x] Glibc compatibility
  - [x] XDG Base Directory paths
  - [x] UserDefaults emulation via JSON

### Testing & Documentation
- [x] Test suite (178 tests, 26 suites)
- [x] README with badges
- [x] Code documentation in English
- [x] Example app with 7 demo pages
