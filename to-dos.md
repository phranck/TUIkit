# TUIKit — Tasks

## In Progress

(none)

## Open

### Components

#### High

- [ ] **TextInput / TextField** — Einzeilige Texteingabe mit Cursor, Backspace, Delete, Scrolling
- [ ] **Table** — Spaltenausrichtung mit ANSI-aware Padding

#### Medium

- [ ] **ProgressBar** — Prozentbalken mit Unicode-Blöcken (`▓░`)
- [ ] **List (scrollbar)** — Scrollbare Liste mit Selektion für beliebige Views
- [ ] **Checkbox / Toggle** — `[x]`/`[ ]` mit Keyboard-Toggle

#### Low

- [ ] **Toast / Notification** — Temporäre Meldung, verschwindet nach X Sekunden

### Performance

(none)

### Infrastructure

- [ ] **Example App Neugestaltung** — Feature-Katalog → mehrere kleine Example Apps
- [ ] **GitHub → Codeberg Migration** — `gh2cb`, Woodpecker CI, DNS-Umstellung

### Testing & Docs

- [ ] **Mobile/Tablet Docs** — Landing Page + DocC auf mobilen Geräten testen
- [ ] **Code Examples** — Counter, Todo List, Form, Table/List

## Completed

### 2026-02-03

- [x] **Subtree Memoization** — EquatableView + RenderCache, opt-in via `.equatable()`, cache cleared on @State change
- [x] **Palette Consolidation** — 6 Palette-Structs → `SystemPalette.Preset` enum + `SystemPalette` (PR #70)
- [x] **Extension Separation** — 35 Source-Files: Funktionen in access-level Extensions (PR #69)
- [x] **AppHeader** — Framework-managed Header Bar, `.appHeader {}` Modifier
- [x] **Focus Sections** — `.focusSection()`, section-aware FocusManager, StatusBar Cascading
- [x] **Dimmed Overlay Rewrite** — Palette-basiertes Dimming, Ornament-Stripping, ANSI-aware Splitting
- [x] **Unified File Headers** — 136 Swift-Files standardisiert
- [x] **OverlaysPage Redesign** — 8 Overlay-Varianten, modale Focus-Isolation (PR #67)

### 2026-02-02

- [x] **Render-Pipeline Phase 1–4** — Line-Diffing, Output Buffering, Caching, Architecture Cleanup (PR #62, #63)
- [x] **Spinner View** — dots/line/bouncing Styles, auto-animating (PR #61)
- [x] **Structural Identity for @State** — ViewIdentity, StateStorage, self-hydrating @State (PR #60)
- [x] **Landing Page Optimierung** — CRT Boot/Shutdown, Terminal Markdown Parser, Smart Typing, SEO
- [x] **Test Quality Audits** — 134 wertlose Tests entfernt, 33 schwache Assertions verschärft
- [x] **CI Automation** — Test-Badge, Git Author Cleanup

### 2026-01-31

- [x] **Source Restructure** — Directory-Reorg, Phosphor→Palette Rename (PR #30)
- [x] **EnvironmentStorage Elimination** — Singleton entfernt, SemanticColor System (PR #31)
- [x] **Palette Protocol Split** — `Palette` + `BlockPalette`, ANSI→RGB (PR #48)
- [x] **Access-Level Refactor** — Public API Surface eingeschränkt (PR #37)
- [x] **DocC Documentation** — 8 Guide-Artikel, Diagramme, Palette/Keyboard Reference

### 2026-01-30

- [x] **Code Quality PR #5–#18** — Dead Code, Singletons, SwiftLint, Linux Compat, AppRunner Decomposition
- [x] **Testing PR #20–#23** — 4 Phasen, 569 Tests initial
- [x] **DocC + GitHub Pages** — swift-docc-plugin, CI Deploy, Custom Domain
- [x] **Landing Page** — Next.js, CRT Terminal, Blade Runner Atmosphere (PR #40–#54)

### 2026-01-29

- [x] **Git Cleanup** — `.claude/` aus History entfernt, Branches gelöscht

## Notes

- DocC: `swift-docc-plugin`, GitHub Pages mit `theme-settings.json` Workaround
- Landing Page: Next.js 16 + React 19 + Tailwind 4, CI-deployed, tuikit.layered.work

---

**Last Updated:** 2026-02-04
