# TUIKit — To-Dos

## IN PROGRESS

- [ ] Create PR for `feature/system-statusbar-items` branch

## PLANNED

### High Priority
- [ ] AppState: Replace singleton with Environment-based render trigger
- [ ] TextField view with cursor management
- [ ] HelpOverlay for `?` system shortcut

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

## ✅ COMPLETED

### Theme System Improvements (2026-01-28)
- [x] Theme colors throughout UI components
  - [x] Menu uses theme.foreground/accent
  - [x] Button uses theme colors for focus/border
  - [x] Panel/BorderModifier use theme.border
- [x] Consistent background color across entire terminal
  - [x] ANSI reset codes replaced with "reset + restore background"
  - [x] StatusBar uses same background treatment
- [x] Subtle theme tints for backgrounds
  - [x] Green: #0F1A0F (green tint)
  - [x] Amber: #1A150F (amber tint)
  - [x] White: #121418 (cool/blue tint)
  - [x] Red: #1A0F0F (red tint)
- [x] Simplified theme names (Green, Amber, White, Red, ncurses)

### System StatusBar Items (2026-01-28)
- [x] Two-container model (user items left, system items right)
- [x] System items: quit, help, theme
- [x] ThemeManager for theme cycling (`t` key)
- [x] QuitBehavior configuration

### FocusManager Refactoring (2026-01-28)
- [x] FocusManager: Refactored from singleton to Environment-based
- [x] Parallel tests now work

### Core Framework
- [x] View protocol
- [x] ViewBuilder result builder (up to 10 children, conditionals, optionals, arrays)
- [x] Primitive views: Text, EmptyView, Spacer, Divider
- [x] Container views: VStack, HStack, ZStack
- [x] Container views: Card, Box, Panel
- [x] ForEach (Identifiable, KeyPath, Range)
- [x] AnyView type erasure

### Color & Theming
- [x] Color system (ANSI, bright, 256-palette, RGB)
- [x] Hex colors (integer and string: "#FF5500", "#F50")
- [x] HSL color support
- [x] Color modifiers: lighter(), darker(), opacity()
- [x] Theme System
  - [x] Theme protocol with semantic colors
  - [x] Environment-based ThemeManager
  - [x] 5 predefined themes (Green, Amber, White, Red, NCurses)
  - [x] `.theme()` modifier
  - [x] `Color.theme.foreground` etc. shortcuts

### Text & Styling
- [x] Text styling (bold, italic, underline, strikethrough, dim, blink, inverted)
- [x] Foreground and background colors

### Modifiers
- [x] `.padding()` modifier
- [x] `.frame(width:height:alignment:)` - fixed size
- [x] `.frame(minWidth:maxWidth:minHeight:maxHeight:)` - flexible size
- [x] `.border()` modifier (8 border styles, width-aware, theme colors)
- [x] `.background()` modifier
- [x] `.overlay(alignment:)` modifier
- [x] `.dimmed()` modifier
- [x] `.modal()` convenience helper
- [x] `.onKeyPress()` modifier
- [x] `.statusBarItems()` modifier
- [x] `.environment()` modifier
- [x] `.theme()` modifier

### Lifecycle
- [x] `.onAppear()` modifier
- [x] `.onDisappear()` modifier
- [x] `.task()` async modifier

### State & Data Flow
- [x] @State property wrapper
- [x] Binding for two-way data flow
- [x] Environment System (top-down)
- [x] Preferences System (bottom-up)

### Storage
- [x] @AppStorage property wrapper
- [x] @SceneStorage property wrapper
- [x] JSONFileStorage backend
- [x] UserDefaultsStorage (macOS + Linux)

### Interactive Views
- [x] Button view with action handler
- [x] ButtonRow for horizontal button groups
- [x] ButtonStyle presets
- [x] Focus system with Tab/Shift+Tab navigation
- [x] Menu view with items, selection, shortcuts

### Overlays & Alerts
- [x] Alert view (with warning/error/info/success presets)
- [x] Dialog view
- [x] FrameBuffer character-level compositing

### Status Bar
- [x] StatusBar view (compact and bordered styles)
- [x] StatusBarItem with shortcut, label, action
- [x] Shortcut constants (Unicode symbols)
- [x] Context stack for modals (push/pop)
- [x] StatusBarState via Environment
- [x] System items (quit, help, theme)

### Rendering
- [x] Terminal abstraction (raw mode, alternate screen, cursor, fillBackground)
- [x] ANSI escape code renderer (including backgroundCode)
- [x] Renderable protocol with RenderContext
- [x] ViewRenderer with tree traversal
- [x] FrameBuffer with compositing
- [x] Theme background preservation after ANSI resets

### App Lifecycle
- [x] App/Scene/WindowGroup
- [x] AppRunner with run loop
- [x] Signal handlers (SIGINT, SIGWINCH)

### Platform Support
- [x] macOS support (10.15+)
- [x] Linux support (Glibc, XDG paths, JSON storage)

### Testing & Documentation
- [x] Test suite (189 tests, 28 suites)
- [x] README with badges
- [x] Code documentation in English
- [x] Example app with 7 demo pages
