# TUIKit - To-Dos

## IN PROGRESS

- (none)

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

## COMPLETED

### Comprehensive DocC Documentation (2026-01-29)
- [x] TUIKit.docc catalog structure with Info.plist
- [x] Main landing page (TUIKit.md) with quick-start and topic navigation
- [x] 8 comprehensive guide articles:
  - [x] GettingStarted.md - Installation and first app
  - [x] ViewHierarchy.md - Understanding the View protocol
  - [x] StateManagement.md - @State, @Environment, @AppStorage patterns
  - [x] Theming.md - Theme system and customization
  - [x] Appearance.md - 5 appearance styles and rendering
  - [x] Focus.md - Focus management and keyboard navigation
  - [x] Modifiers.md - View modifier reference and composition
  - [x] Architecture.md - Overall architecture and design patterns
- [x] 3 step-by-step interactive tutorials:
  - [x] BuildYourFirstApp.md - Simple counter application
  - [x] BuildInteractiveMenu.md - Menu navigation and keyboard shortcuts
  - [x] BuildThemableUI.md - Theme switching with persistence
- [x] Improved Box.swift documentation with container comparison
- [x] GitHub Actions workflow (docc.yml) for automatic DocC building
- [x] GitHub Pages deployment configuration
- [x] Apple-style documentation with code examples and cross-references

### StatusBar, Buttons & Theme Styling (2026-01-29)
- [x] StatusBar.bordered style with theme border colors
- [x] StatusBar block appearance with half-block characters
- [x] Pass current environment to StatusBar rendering for theme updates
- [x] ButtonRow right-alignment with left padding calculation
- [x] Button: Remove borders in block appearance
- [x] Button: Remove focus indicator for primary buttons
- [x] Button: Add buttonBackground in block appearance
- [x] Theme: Add buttonBackground color for all themes
- [x] Theme: Adjust foregroundSecondary and statusBarForeground
- [x] Container: Add theme background to body content
- [x] Alerts: Use real Button components instead of Text
- [x] Alerts: Center modal with HStack/Spacer layout
- [x] Amber theme: Update header/footer background to #1E110E
- [x] StatusBar: Block style with ▄/█/▀ characters

### Half-Padding Cleanup & Demo Improvements (2026-01-29)
- [x] Remove half-padding feature from BorderModifier
- [x] Simplify `renderBlockStyle()` method
- [x] Remove half-padding from `.border()` view extension
- [x] Remove half-padding demo from ContainersPage
- [x] Fix Content Alignment demo to show actual alignment differences
- [x] Update Padding demo to show h and v values

### Block Appearance Implementation (2026-01-28)
- [x] Half-block Unicode rendering (top/bottom borders, side borders)
- [x] Container background colors for all themes
- [x] Header/footer background colors
- [x] ANSI reset code handling for persistent backgrounds

### Theme System Improvements (2026-01-28)
- [x] Theme colors throughout UI components
  - [x] Menu uses theme.foreground/accent
  - [x] Button uses theme colors for focus/border
  - [x] Panel/BorderModifier use theme.border
- [x] Consistent background color across entire terminal
  - [x] ANSI reset codes replaced with "reset + restore background"
  - [x] StatusBar uses same background treatment
- [x] Subtle theme tints for backgrounds
  - [x] Green: #060A07 (app), #0E271C (container)
  - [x] Amber: #0A0706 (app), #251710 (container)
  - [x] White: #06070A (app), #111A2A (container)
  - [x] Red: #0A0606 (app), #281112 (container)
- [x] Simplified theme names (Green, Amber, White, Red)

### System StatusBar Items (2026-01-28)
- [x] Two-container model (user items left, system items right)
- [x] System items: quit, help, theme
- [x] ThemeManager for theme cycling (`t` key)
- [x] QuitBehavior configuration

### FocusManager Refactoring (2026-01-28)
- [x] FocusManager: Refactored from singleton to Environment-based
- [x] Parallel tests now work

### Package Rename (2026-01-28)
- [x] Renamed from SwiftTUI to TUIKit
- [x] All imports and references updated

### Core Framework
- [x] View protocol
- [x] ViewBuilder result builder (up to 10 children, conditionals, optionals, arrays)
- [x] Primitive views: Text, EmptyView, Spacer, Divider
- [x] Container views: VStack, HStack, ZStack
- [x] Container views: Card, Box, Panel, ContainerView
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
  - [x] 4 predefined phosphor themes
  - [x] `.theme()` modifier
  - [x] `Color.theme.foreground` etc. shortcuts

### Text & Styling
- [x] Text styling (bold, italic, underline, strikethrough, dim, blink, inverted)
- [x] Foreground and background colors

### Modifiers
- [x] `.padding()` modifier
- [x] `.frame(width:height:alignment:)` - fixed size
- [x] `.frame(minWidth:maxWidth:minHeight:maxHeight:)` - flexible size
- [x] `.border()` modifier (5 appearance styles, width-aware, theme colors)
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
- [x] System items (quit, help, theme, appearance)

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
- [x] Test suite (210 tests, 31 suites)
- [x] README with badges
- [x] Code documentation in English
- [x] Example app with 7 demo pages
