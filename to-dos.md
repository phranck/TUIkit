# TUIkit: Tasks

## In Progress

(none)

## Open

### Components

#### High

- [ ] **TextInput / TextField**: Single-line text input with cursor, backspace, delete, scrolling

#### Medium

(none)

#### Low

(none)

### Performance

- [ ] **`View._printChanges()` Equivalent**: Debug mechanism that logs why body was re-evaluated

### Infrastructure

- [ ] **Example App Redesign**: Feature catalog → multiple small example apps

### Testing & Docs

- [ ] **Mobile/Tablet Docs**: Test DocC on mobile devices (landing page done)
- [ ] **Code Examples**: Counter, Todo List, Form, Table/List

## Completed

### 2026-02-08

- [x] **Section Integration (Phase 2c3)**: List uses SelectableListRow, Section flattening, selectableIndices
- [x] **Test Cleanup**: Removed 5 flaky/tautological tests (732 → 727)
- [x] **README Update**: Added missing features (List, Table, Section, Toggle, ProgressView, Spinner, ListStyle, Badge)

### 2026-02-09

- [x] **Badge Modifier (Phase 2a)**: Int/Text/StringProtocol overloads, List integration, 20+ tests
- [x] **ListStyle System (Phase 2b)**: PlainListStyle + InsetGroupedListStyle, alternating rows, environment keys
- [x] **SelectableListRow Foundation (Phase 2c1)**: ListRowType enum, type-safe row classification, FrameBuffer Sendable
- [x] **ItemListHandler Skip Logic (Phase 2c2)**: selectableIndices, focus navigation over non-selectable rows

### 2026-02-08

- [x] **Section View**: SwiftUI-conformant Section with header/content/footer, SectionRowExtractor, 14 tests
- [x] **ButtonRole + Alert**: Horizontal buttons, cancel/destructive roles, ESC dismiss, arrow navigation
- [x] **Xcode Project Template**: TUIkit App.xctemplate with install script, landing page one-liner
- [x] **xcode-templates Skill**: Global skill for creating Xcode project templates
- [x] **List & Table PR**: Merged PR #86 with focus bar, F-keys, StatusBar defaults, SwiftLint fixes

### 2026-02-07

- [x] **List & Table Components**: ItemListHandler + List + Table with selection, keyboard navigation, scrolling
- [x] **Deep Code Review**: Force-unwrap fix, doc comments, 6 new tests, StatusBarTests split (4 files), SwiftLint 0 warnings
- [x] **Swift 6 Concurrency Complete**: Phases 1-7; TerminalProtocol, ActionHandler, AppRunner cleanup
- [x] **List/Table Shared Architecture**: Analysis complete, ItemListHandler pattern defined
- [x] **Em-dash Removal**: Replaced all em-dashes with colons/sentences across 73 files

### 2026-02-06

- [x] **Toggle / Checkbox**: Boolean toggle with Space/Enter, slider + checkbox styles, focus indicator, disabled state, 17 tests
- [x] **Dashboard Cache + Auto-Refresh**: localStorage cache (5 min TTL), auto-refresh timer, Framer Motion list animations
- [x] **License Change**: CC BY-NC-SA 4.0 → MIT, 141 Swift files + LICENSE file
- [x] **Mobile Responsive**: SiteNav hamburger, StatCards vertical, heatmap hidden, CommitList compact

### 2026-02-05

- [x] **ProgressView**: 5 bar styles, SwiftUI API parity
- [x] **Remove Block/Flat Appearances**: BorderedView consolidated into ContainerView
- [x] **Notification System**: Fire-and-forget NotificationService, fade-in/out animation, word-wrap
- [x] **Render Performance Phase 2**: Cache invalidation fix, Equatable on 15 types/views
- [x] **TupleView Equatable**: Conditional Equatable via parameter packs

### 2026-02-03

- [x] **Subtree Memoization**: EquatableView + RenderCache, opt-in via `.equatable()`
- [x] **Palette Consolidation**: 6 Palette-Structs → SystemPalette.Preset enum
- [x] **AppHeader**: Framework-managed Header Bar, `.appHeader {}` Modifier
- [x] **Focus Sections**: `.focusSection()`, section-aware FocusManager

### 2026-02-02

- [x] **Render-Pipeline Phase 1-4**: Line-Diffing, Output Buffering, Caching
- [x] **Spinner View**: dots/line/bouncing Styles, auto-animating
- [x] **Structural Identity for @State**: ViewIdentity, StateStorage

## Notes

- DocC: `swift-docc-plugin`, GitHub Pages with `theme-settings.json` workaround
- Landing Page: Astro + React + Tailwind 4, CI-deployed, tuikit.layered.work
- Xcode Template: `~/Library/Developer/Xcode/Templates/Project Templates/macOS/Application/`

---

**Last Updated:** 2026-02-09
