# TUIKit - Tasks & Feature Ideas

## 🚀 In Progress
- (keine)

## 📋 Open Tasks

### New Components

#### High Priority
- [ ] **TextInput / TextField** — Einzeilige Texteingabe mit Cursor, Backspace, Delete, Scrolling bei Überlänge. Fehlt komplett, ist im Terminal aufwändig selbst zu bauen. Größter Impact für Endnutzer.
- [ ] **Table** — Spaltenausrichtung mit ANSI-aware Padding. TUIKit hat `padToVisibleWidth` schon, eine Table-View wäre fast geschenkt. Jeder CLI-Entwickler braucht das.

#### Medium Priority
- [ ] **ProgressBar** — Prozentbalken mit Unicode-Blöcken (`▓░`). In GUIs trivial, im Terminal muss man das selbst bauen.
- [ ] **Spinner** — Animierter Lade-Indikator (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` oder `|/-\`). Timer + Character-Cycling.
- [ ] **List (scrollbar)** — Scrollbare Liste mit Selektion für beliebige Views. `Menu` existiert schon, aber eine generische scrollbare Liste wäre der nächste Schritt.
- [ ] **Checkbox / Toggle** — `[x]` / `[ ]` mit Keyboard-Toggle. Simpel, aber jeder braucht's.

#### Low Priority
- [ ] **Toast / Notification** — Temporäre Meldung, die nach X Sekunden verschwindet. Im Terminal gibt's kein natives Notification-System.

### Code Quality (aus Projektanalyse)

- [ ] **B.4** AppRunner God Class — Split in InputHandler, RenderLoop, SignalManager (Medium)
- [ ] **C.4** Preference Keys ggf. unused — `TabBadgeKey`, `AnchorPreferenceKey` prüfen/entfernen (Low)
- [ ] **E.1** Public types missing doc comments — `///` für ~7 Modifier-Properties (Medium)
- [ ] **E.2** Complex logic without inline comments — KeyEvent, FrameBuffer, ViewRenderer (Medium)
- [ ] **H.2** Dual rendering system (body vs Renderable) — Contract dokumentieren (Medium)
- [ ] **H.4** Preference callback accumulation — Callbacks pro Render-Zyklus clearen (Medium)
- [ ] **H.8** Test coverage gaps — Views/Modifiers untested (High)

### Documentation
- [ ] Expand DocC articles: add more guides and tutorials
- [ ] Improve inline Swift doc comments for better auto-generated API docs
- [ ] Create interactive code examples in documentation
- [ ] Document all 5 phosphor themes with visual examples
- [ ] Add keyboard shortcut reference guide

### Landing Page
- [ ] Build custom landing page under `/` (currently redirects to DocC)
- [ ] Design with feature highlights, quick links, GitHub badge

### CI/CD
- [ ] Add CI workflow for `swift build` + `swift test` on push/PR

### Testing & Validation
- [ ] Test documentation on mobile/tablet
- [ ] Validate all DocC symbol links resolve correctly

### Code Examples
- [ ] Create example: Simple counter app
- [ ] Create example: Todo list app
- [ ] Create example: Form with validation
- [ ] Create example: Table/list view
- [ ] Document Spotnik (Spotify player) as main example

## ✅ Completed

### Code Quality & Refactoring (2026-01-30)
- ✅ **PR #5** — Code Quality Phases 1-9: Dead code, force unwraps, anti-patterns, Palette-Rename, ThemeManager, Extensions-Migration (47 files, +2899/−1875)
- ✅ **PR #6** — `buildEnvironment()` helper (A.12): Eliminiert 3x dupliziertes Environment-Setup
- ✅ **PR #7** — ContainerConfig (B.3): `ContainerConfig` struct + `renderContainer()` für Alert, Dialog, Panel, Card
- ✅ **PR #8** — SwiftLint Integration: SPM Build Plugin, ~300+ Autofixes
- ✅ **PR #9** — swift-format Integration: CLI-Formatting, `.swift-format` Config
- ✅ **PR #10** — TUIContext Singleton-Elimination (H.1): Zentraler Dependency Container, 8 von 14 Singletons eliminiert
- ✅ **A.8** — Parameter Packs: TupleView/ViewBuilder ~430 Zeilen Boilerplate → ~30 Zeilen, 10-Kind-Limit entfernt
- ✅ **A.10** — Container Cleanup: `renderContainer()` if/else eliminiert, Alert-Redundanz entfernt
- ✅ **H.7** — ANSI Regex vorkompiliert: Vermeidet pro-Aufruf Regex-Kompilierung im Hot Rendering Path
- ✅ macOS 14 Audit: Deployment Target auf macOS 14 angehoben (nötig für Parameter Packs)

### DocC Documentation + GitHub Pages (2026-01-30)
- ✅ Removed all old documentation (VitePress, MkDocs, legacy DocC)
- ✅ Added `swift-docc-plugin` to Package.swift
- ✅ Created DocC Catalog at `Sources/TUIKit/TUIKit.docc/`
- ✅ Wrote articles: Getting Started, Architecture, State Management, Theming Guide
- ✅ Full API topic organization on landing page
- ✅ GitHub Actions workflow for auto-deployment (`docc.yml`)
- ✅ Custom domain: https://tuikit.layered.work
- ✅ Fixed blank page issue (missing `theme-settings.json`)
- ✅ Fixed GitHub Pages build type (`legacy` → `workflow`)
- ✅ Root redirect `/` → `/documentation/tuikit`
- ✅ Removed leftover VitePress workflow

### Documentation System (2026-01-29)
- ✅ Replaced DocC with MkDocs (later replaced by DocC again)
- ✅ VitePress migration (later replaced by DocC)

### Git Cleanup (2026-01-29)
- ✅ Removed `.claude/` folder from entire Git history
- ✅ Added `.claude/` to .gitignore

### Infrastructure
- ✅ README.md updated with Spotnik screenshot
- ✅ GitHub Pages configured with custom domain

## 🔍 Notes

### Why DocC (final choice)
- Native Swift documentation — auto-generates API docs from code comments
- Apple standard for Swift packages
- `swift-docc-plugin` integrates cleanly with SPM
- Requires `theme-settings.json` workaround for GitHub Pages (injected via CI)

### Why not VitePress/MkDocs
- Redundant when DocC provides Swift-native API documentation
- DocC auto-documents all public types, protocols, functions from source

---

**Last Updated:** 2026-01-30
