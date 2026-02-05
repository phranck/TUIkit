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

- [ ] **TupleView Equatable** — `VStack { Text("A"); Text("B") }` erzeugt `TupleView<(Text, Text)>`, braucht per-arity conditional Equatable
- [ ] **`View._printChanges()` Equivalent** — Debug-Mechanismus der loggt warum body re-evaluiert wurde

### Infrastructure

- [ ] **Example App Neugestaltung** — Feature-Katalog → mehrere kleine Example Apps
- [ ] **GitHub → Codeberg Migration** — `gh2cb`, Woodpecker CI, DNS-Umstellung
- [ ] **GH Actions: Social Cache Workflow** — 403 push denied, `github-actions[bot]` braucht Write-Permissions auf Repo oder PAT

### Testing & Docs

- [ ] **Mobile/Tablet Docs** — Landing Page + DocC auf mobilen Geräten testen
- [ ] **Code Examples** — Counter, Todo List, Form, Table/List

## Completed

### 2026-02-05

- [x] **Render Performance Phase 2** — Cache invalidation fix, Equatable on 15 types/views, debug tooling, example app decomposition + `.equatable()`, DocC documentation (PR #74)
- [x] **Social Lookup Optimization** — GitHub Social API, NodeInfo instance validation, timeouts, false positives eliminated
- [x] **Dashboard: Branches → Open Issues** — StatCard replaced with `SFBubbleLeftAndExclamationmarkBubbleRightFill` icon

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

## Feature Ideas (Backlog)

### Render Performance — Architectural Guidelines from SwiftUI Patterns - 2026-02-05 12:21

Permanent architectural concern. Synthesized from the [SwiftUI performance article](https://www.swiftdifferently.com/blog/swiftui/swiftui-performance-article) by Omar Elsayed, the [SwiftUI Agent Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) by Antoine van der Lee (references: `performance-patterns.md`, `view-structure.md`, `list-patterns.md`, `layout-best-practices.md`), and evaluated for applicability to a TUI framework.

**Problem:** State changes trigger body re-evaluation. The cost scales with the number of primitive views in the body. SwiftUI diffs old vs. new body output to find what changed — the more primitives, the more work. Identical patterns apply to TUIKit's render pipeline.

**Core principles and TUIKit applicability:**

1. **View struct decomposition = diffing boundaries**
   Separate structs let the framework skip body re-evaluation when inputs haven't changed. `@ViewBuilder` functions and computed properties do NOT create boundaries — they inline at runtime. *Directly applicable.* Already partially addressed via `EquatableView` + `RenderCache`, but structural decomposition should be a documented best practice.

2. **POD (Plain Old Data) views for fast diffing**
   Views containing only simple value types (no property wrappers) use `memcmp` for fastest comparison. Wrap expensive non-POD views in POD parent structs. *Applicable:* TUIKit views with only `let` properties and no `@State` can benefit from this pattern.

3. **Pass only needed values, not entire models**
   Passing large context/config objects creates broad dependencies — any property change triggers updates in all observing views. Pass specific values instead. *Directly applicable:* TUIKit views should receive only the data they render, not entire app state objects.

4. **Avoid redundant state updates in hot paths**
   Check for value changes before assigning state. Gate frequent updates (scroll, resize) by thresholds. *Applicable to TUIKit:* terminal resize events, keyboard repeat, timer ticks — guard with `if newValue != oldValue`.

5. **No object creation or heavy computation in body**
   Formatters, sorting, filtering — all belong outside body. Body should be a pure structural declaration. *Directly applicable.* DateFormatters → static properties; sorted arrays → computed on state change, not in body.

6. **Stable identity for ForEach / list items**
   Never use `.indices` for dynamic content. Ensure constant view count per element. Prefilter arrays instead of inline filtering. Avoid `AnyView` in list rows. *Applicable when TUIKit gets List/Table components:* stable identity prevents excessive diffing and potential crashes.

7. **Prefer modifiers over conditional views for state changes**
   `opacity(0)` vs. `if isVisible { ... }` — conditionals destroy view identity and state. Use modifiers to represent different states of the *same* view. *Partially applicable:* TUIKit's modifier chain (`.hidden()`, `.disabled()`) should be preferred over conditional inclusion where possible.

8. **Container views: `@ViewBuilder let content` over closures**
   Closures can't be compared → always cause re-renders. `@ViewBuilder let content: Content` allows the framework to diff the content. *Directly applicable to TUIKit container views.*

9. **Equatable as escape hatch for closure identity**
   When closures prevent comparison, conform to `Equatable` + use `.equatable()`. *Already implemented in TUIKit.* Ensure it's documented for user-facing views.

10. **Debug: `Self._printChanges()` equivalent**
    SwiftUI has `Self._printChanges()` to identify what caused body re-evaluation. *Consider:* adding a similar debug mechanism to TUIKit's render pipeline (e.g., log which views re-evaluated and why).

**Action items:**
- Document these as architectural guidelines in DocC
- Audit existing complex views (example apps, overlay compositions) for monolithic bodies
- Ensure `@ViewBuilder` helper methods in existing views don't mask performance issues
- Add debug logging for view re-evaluation in development builds

---

**Last Updated:** 2026-02-05 15:00
