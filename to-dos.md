# TUIKit — Tasks

## In Progress

- [ ] **Toggle / Checkbox** — Boolean toggle with Space/Enter, two visual styles ([plan](plans/open/2026-02-06-toggle.md))

## Open

### Components

#### High

- [ ] **TextInput / TextField** — Single-line text input with cursor, backspace, delete, scrolling
- [ ] **Table** — Column alignment with ANSI-aware padding

#### Medium

- [ ] **List (scrollable)** — Scrollable list with selection for arbitrary views


#### Low

(none)

### Performance

- [ ] **`View._printChanges()` Equivalent** — Debug mechanism that logs why body was re-evaluated

### Infrastructure

- [ ] **Example App Redesign** — Feature catalog → multiple small example apps

### Testing & Docs

- [ ] **Mobile/Tablet Docs** — Test DocC on mobile devices (landing page done)
- [ ] **Code Examples** — Counter, Todo List, Form, Table/List

## Completed

### 2026-02-06

- [x] **Dashboard Cache + Auto-Refresh** — localStorage cache (5 min TTL), auto-refresh timer, Framer Motion list animations, no skeleton flash (PR #80)
- [x] **License Change** — CC BY-NC-SA 4.0 → MIT, 141 Swift files + LICENSE file
- [x] **Mobile Responsive** — SiteNav hamburger, StatCards vertical, heatmap hidden, CommitList compact, HeroTerminal power-button disabled on phones, footer stacked/centered

### 2026-02-05

- [x] **ProgressView** — 5 bar styles, SwiftUI API parity, `darker(by:)`/`lighter(by:)` → relative % (PR #79)
- [x] **Remove Block/Flat Appearances** — Eliminated block, flat, ascii. BorderedView consolidated into ContainerView. Consistent 1-char padding in all containers. DocC overhauled. (PR #78)
- [x] **Notification System** — Fire-and-forget `NotificationService`, fade-in/out animation, word-wrap, top-right overlay, Box rendering. No severity styles, no Binding. (PR #77)

- [x] **Render Performance Phase 2** — Cache invalidation fix, Equatable on 15 types/views, debug tooling, example app decomposition + `.equatable()`, DocC documentation (PR #74)
- [x] **Social Lookup Optimization** — GitHub Social API, NodeInfo instance validation, timeouts, false positives eliminated
- [x] **Dashboard: Branches → Open Issues** — StatCard replaced with `SFBubbleLeftAndExclamationmarkBubbleRightFill` icon
- [x] **GH Actions: Social Cache Workflow** — 403 push denied, fixed with PAT + `contents: write` permissions
- [x] **TupleView Equatable** — Conditional Equatable via parameter packs, enables `.equatable()` on VStack/HStack/ZStack compositions (PR #76)
- [x] **Markdown Language Audit** — German remnants translated to English across 4 files (PR #75)

### 2026-02-03

- [x] **Subtree Memoization** — EquatableView + RenderCache, opt-in via `.equatable()`, cache cleared on @State change
- [x] **Palette Consolidation** — 6 Palette-Structs → `SystemPalette.Preset` enum + `SystemPalette` (PR #70)
- [x] **Extension Separation** — 35 source files: functions moved to access-level extensions (PR #69)
- [x] **AppHeader** — Framework-managed Header Bar, `.appHeader {}` Modifier
- [x] **Focus Sections** — `.focusSection()`, section-aware FocusManager, StatusBar Cascading
- [x] **Dimmed Overlay Rewrite** — Palette-based dimming, ornament stripping, ANSI-aware splitting
- [x] **Unified File Headers** — 136 Swift files standardized
- [x] **OverlaysPage Redesign** — 8 overlay variants, modal focus isolation (PR #67)

### 2026-02-02

- [x] **Render-Pipeline Phase 1–4** — Line-Diffing, Output Buffering, Caching, Architecture Cleanup (PR #62, #63)
- [x] **Spinner View** — dots/line/bouncing Styles, auto-animating (PR #61)
- [x] **Structural Identity for @State** — ViewIdentity, StateStorage, self-hydrating @State (PR #60)
- [x] **Landing Page Optimization** — CRT boot/shutdown, terminal Markdown parser, smart typing, SEO
- [x] **Test Quality Audits** — 134 worthless tests removed, 33 weak assertions tightened
- [x] **CI Automation** — Test-Badge, Git Author Cleanup

### 2026-01-31

- [x] **Source Restructure** — Directory-Reorg, Phosphor→Palette Rename (PR #30)
- [x] **EnvironmentStorage Elimination** — Singleton removed, SemanticColor system (PR #31)
- [x] **Palette Protocol Split** — `Palette` + `BlockPalette` (later removed), ANSI→RGB (PR #48)
- [x] **Access-Level Refactor** — Public API surface restricted (PR #37)
- [x] **DocC Documentation** — 8 guide articles, diagrams, palette/keyboard reference

### 2026-01-30

- [x] **Code Quality PR #5–#18** — Dead Code, Singletons, SwiftLint, Linux Compat, AppRunner Decomposition
- [x] **Testing PR #20–#23** — 4 phases, 569 tests initial
- [x] **DocC + GitHub Pages** — swift-docc-plugin, CI Deploy, Custom Domain
- [x] **Landing Page** — Next.js, CRT Terminal, Blade Runner Atmosphere (PR #40–#54)

### 2026-01-29

- [x] **Git Cleanup** — `.claude/` removed from history, branches deleted

## Notes

- DocC: `swift-docc-plugin`, GitHub Pages with `theme-settings.json` workaround
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

**Last Updated:** 2026-02-06 01:15
