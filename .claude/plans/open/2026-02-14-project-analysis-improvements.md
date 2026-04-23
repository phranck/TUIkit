# Project Analysis Improvements

## Preface

Tracks all recommendations from `papers/project_analysis.md` (2026-02-14). The analysis reviewed 135 Swift source files (28,126 lines) and identified 29 improvements across four priority levels (P1 quick wins, P2 high-impact/medium-effort, P3 medium-impact/higher-effort, P4 long-term architectural) plus nine additional findings (code style, test coverage). Twenty-four of twenty-nine items are complete; this plan focuses the remaining five items on the test-coverage gap in image processing, notifications, view extensions, and the `App/` subsystem, plus the organizational question around `project-template/`.

## Specification / Goal

Close the remaining five improvements identified in `papers/project_analysis.md`:

1. Resolve the organizational status of `project-template/` (keep inline, move to a separate repository, or fold into examples).
2. Add unit tests for `ASCIIConverter` and `RGBAImage`.
3. Add unit tests for the `Notification/` subsystem.
4. Add unit tests for View extension files under `Extensions/`.
5. Evaluate and document test coverage for the `App/` subsystem (`RenderLoop`, `InputHandler`, related runtime components).

Acceptance:

- All new tests pass on macOS and Linux (via `./scripts/test-linux.sh`).
- No regressions in existing tests.
- `project-template/` location decision documented in CONTRIBUTING or equivalent.
- Coverage evaluation of `App/` produces either concrete test additions or a documented rationale for gaps.

## Design

### Test Coverage Targets

| Target | Scope | Test file location |
|--------|-------|-------------------|
| `ASCIIConverter` | Grayscale/color mapping, dithering paths, edge cases (1×1, empty) | `Tests/TUIkitTests/Image/ASCIIConverterTests.swift` |
| `RGBAImage` | Pixel accessors, bounds, transforms, `Codable` round-trip if applicable | `Tests/TUIkitTests/Image/RGBAImageTests.swift` |
| `Notification/` | Post/receive, host modifier lifecycle, service singleton behavior, `RenderNotifier` interplay | `Tests/TUIkitTests/Notification/*` |
| `Extensions/` | View extension files (per-file test or grouped by theme) | `Tests/TUIkitTests/Extensions/*` |
| `App/` subsystem | `RenderLoop`, `InputHandler`, `AppRunner` runtime behavior | Either extend existing tests or add `Tests/TUIkitTests/App/*` |

### `project-template/` Decision

Three realistic options:

- **A) Keep inline** — lowest effort. Document as "starter kit", leave in repo root.
- **B) Move to separate repo** — cleaner core repo, but adds maintenance surface + version-skew risk.
- **C) Fold into examples** — consolidate with `Sources/TUIkitExample/` if applicable.

Decision is made during implementation after evaluating how often contributors actually use the template.

### `App/` Subsystem Evaluation

`RenderLoop` and `InputHandler` coordinate the main-actor render tick and key dispatch chain. Evaluation produces either:

- A concrete set of unit/integration tests (preferred), or
- A written rationale in `papers/` explaining why a given component is intentionally not unit-tested (e.g. requires a real terminal, covered by E2E).

## Implementation

### Step 1: `project-template/` Organization

1. Audit usage and contributor feedback (issues, PRs, README references).
2. Pick option A/B/C.
3. Execute move/rewrite/document.
4. Update `CONTRIBUTING.md` or equivalent with the rationale.

### Step 2: Image Subsystem Tests

1. Add `ASCIIConverterTests` covering grayscale conversion, color mapping, dithering modes, and edge cases.
2. Add `RGBAImageTests` covering pixel access, transformations, and serialization if exposed.
3. Run `swift test` on macOS + `./scripts/test-linux.sh` for Linux parity.

### Step 3: Notification Subsystem Tests

1. Identify public API surface (`NotificationService`, `NotificationHostModifier`).
2. Add tests for post/receive lifecycle, host mounting/unmounting, interaction with `RenderNotifier.current`.
3. Run on both platforms.

### Step 4: Extensions Tests

1. Enumerate `Extensions/` files.
2. For each public extension, add a targeted test or grouped test file.
3. Skip/note any extension whose behavior is fully covered elsewhere (e.g. by a View test that uses the extension).

### Step 5: `App/` Subsystem Coverage

1. Map current test coverage for `App/` (list files with/without corresponding tests).
2. For each gap, decide: add test vs document rationale.
3. Add tests where feasible without a real terminal (mock `TerminalProtocol`).
4. Commit rationale for intentionally uncovered components in `papers/` or in-file doc comments.

### Completed Work (Context)

The following is preserved as historical context; all items are done.

**Priority 1 (Quick Wins):** P1.1 `ViewConstants` opacity constants, P1.2 empty-list placeholder constant, P1.3 shared `LinesContentView` analysis, P1.4 `EdgeInsets` named constants, P1.5 standardized file headers.

**Priority 2 (High-Impact, Medium Effort):** P2.6 shared List/Table visual state analysis, P2.7 `configureSelectionBindings<T: Hashable>()` helper, P2.8 descriptive variable renames in image processing, P2.9 `StatusBarItem.swift` split (Shortcut enum extracted), P2.10 `sanitizedForTerminal` ANSI sanitization.

**Priority 3 (Medium Impact, Higher Effort):** P3.11 shared Slider/Stepper protocol analysis, P3.12 `ButtonProvider` protocol replacing Mirror-based button extraction, P3.13 image module extraction analysis (deferred via P4.20), P3.14 `View`/`ViewBuilder` documentation review (already comprehensive), P3.15 `sanitizedProcessName` for storage paths.

**Priority 4 (Long-term Architectural):** P4.16 `RenderNotifier.current` global analysis (kept as-is, architecturally correct), P4.17 generic `ItemListHandler` analysis (kept `AnyHashable` boundary), P4.18 `@preconcurrency Equatable` migration across 20 conformances, P4.19 `imageMaxPixelCount` + `imageURLTimeout` environment-driven configuration, P4.20 module-split feasibility analysis (deferred).

**Code Style / Cleanup:** `import Foundation` removed from 29 files; 500-line split targets (`TextFieldHandler`, `Color`, `Renderable`); `UserDefaultsStorage` Linux convenience methods kept; `progressBarStyle(_:)` deprecation noted and tests migrated to `trackStyle`.

## Checklist

### Remaining

- [ ] `project-template/` organization decision + action (keep / move / fold)
- [ ] `ASCIIConverterTests.swift`
- [ ] `RGBAImageTests.swift`
- [ ] `Notification/` subsystem tests
- [ ] `Extensions/` view extension tests
- [ ] `App/` subsystem coverage evaluation + resulting tests or rationale

### Verification

- [ ] `swift test` green on macOS
- [ ] `./scripts/test-linux.sh` green on Linux
- [ ] No regressions in existing test suite
- [ ] `project-template/` rationale documented

### Summary

| Priority | Total | Completed | Remaining |
|----------|-------|-----------|-----------|
| P1       | 5     | 5         | 0         |
| P2       | 5     | 5         | 0         |
| P3       | 5     | 5         | 0         |
| P4       | 5     | 5         | 0         |
| Additional | 9   | 4         | 5         |
| **Total** | **29** | **24**  | **5**     |

---

*Source: `papers/project_analysis.md` (2026-02-14)*
