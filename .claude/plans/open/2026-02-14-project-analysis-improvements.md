# Project Analysis: Improvement Plan

## Preface

This plan tracks all recommendations from `papers/project_analysis.md` (2026-02-14).
The analysis reviewed 135 Swift source files (28,126 lines) and identified improvements
across four priority levels. This checklist serves as the single source of truth for
tracking progress.

## Priority 1: High Impact, Low Effort (Quick Wins)

### P1.1: Extract shared visual state constants (opacity values) into ViewConstants enum
- **Affected:** 15+ files (Button, Toggle, Slider, Stepper, RadioButton, List, Table, SecureField, TextField, etc.)
- **Approach:** Created `ViewConstants` enum in `Sources/TUIkit/Styling/ViewConstants.swift`
- [x] 1.1.1 Create `ViewConstants` enum with opacity constants
- [x] 1.1.2 Replace opacity literals in List/Table (`_ListCore.swift`, `Table.swift`)
- [x] 1.1.3 Replace opacity literals in interactive views (Button, Stepper, Slider, RadioButton, Toggle)
- [x] 1.1.4 Replace opacity literals in rendering/focus files (SecureField, TextField, NavigationSplitView, BorderRenderer, FocusSectionModifier, TextFieldContentRenderer)
- [x] 1.1.5 Build verification

### P1.2: Extract "No items" and repeated strings into constants
- **Affected:** `List.swift`, `Table.swift`
- [x] 1.2.1 Add `emptyListPlaceholder` to `ViewConstants`
- [x] 1.2.2 Replace string literals in `List.swift` init body assignments
- [x] 1.2.3 Note: `Table.swift` public init default params cannot use internal `ViewConstants`
- [x] 1.2.4 Build verification

### P1.3: Shared LinesContentView for List/Table
- **Analysis Result:** Investigated but determined to be over-engineering. Only 2 usages,
  each is a trivial 10-line struct. The duplication is minimal and merging would add
  import coupling without meaningful benefit.
- [x] 1.3.1 Analysis complete (decided against implementation)

### P1.4: Extract EdgeInsets named constants
- **Affected:** `ContainerView.swift`, `Alert.swift`, `Dialog.swift`, `Panel.swift`
- [x] 1.4.1 Add `EdgeInsets.containerDefault` and `.dialogDefault` to `ViewConstants.swift`
- [x] 1.4.2 Replace scattered `EdgeInsets(horizontal:vertical:)` literals
- [x] 1.4.3 Build verification

### P1.5: Standardize file headers (emoji vs plain)
- **Affected:** ~10 files using non-standard header
- [x] 1.5.1 Audit all file headers
- [x] 1.5.2 Standardize to `//  TUIKit - Terminal UI Kit for Swift` format with emoji
- [x] 1.5.3 Build verification

## Priority 2: High Impact, Medium Effort

### P2.6: Shared List/Table visual state logic
- **Analysis Result:** Investigated the focus pulse pattern between List and Table. Only 2
  occurrences of the exact `Color.lerp` pattern, and each view uses different row types,
  generic constraints, and return structures. A shared helper would be over-engineering.
  The opacity constants extraction (P1.1) already addresses the core duplication.
- [x] 2.6.1 Analysis complete (addressed via P1.1 constants)

### P2.7: Extract selection binding conversion into ItemListHandler helper
- **Affected:** `_ListCore.swift`, `Table.swift`, `ItemListHandler.swift`
- [x] 2.7.1 Add generic `configureSelectionBindings<T: Hashable>(single:multi:)` to `ItemListHandler`
- [x] 2.7.2 Replace 16-line boilerplate in `_ListCore.swift` with single helper call
- [x] 2.7.3 Replace equivalent boilerplate in `Table.swift`
- [x] 2.7.4 Build verification

### P2.8: Rename short variables to descriptive names
- **Affected:** `ASCIIConverter.swift`, `RGBAImage.swift`, `_ImageCore.swift`, `String+ANSI.swift`, `ImageLoader.swift`
- **Approach:** Renamed only truly unclear variables. Domain-standard names (x, y, r, g, b)
  were intentionally kept as they are idiomatic in image processing code.
- [x] 2.8.1 Rename `p` to `pixel` in `RGBAImage.swift`
- [x] 2.8.2 Rename `w`/`h` to `proposedWidth`/`proposedHeight` in `_ImageCore.swift`
- [x] 2.8.3 Rename `v` to `scalarValue` in `String+ANSI.swift`
- [x] 2.8.4 Rename `w` to `charWidth` in `String+ANSI.swift`
- [x] 2.8.5 Rename `i` to `pixelIndex` in `ImageLoader.swift`
- [x] 2.8.6 Build verification

### P2.9: Split StatusBarItem.swift (757 lines)
- **Affected:** `Sources/TUIkit/StatusBar/StatusBarItem.swift`
- [x] 2.9.1 Extract `Shortcut` enum (~240 lines) into `Shortcut.swift`
- [x] 2.9.2 Verify `StatusBarItem.swift` is under 500 lines (516 lines)
- [x] 2.9.3 Build verification

### P2.10: Add ANSI escape sequence sanitization
- **Affected:** `String+ANSI.swift`
- **Approach:** Opt-in `sanitizedForTerminal` property (delegates to `stripped`).
  Auto-sanitization in `Text.init()` was rejected to avoid breaking internal ANSI strings.
- [x] 2.10.1 Add `sanitizedForTerminal` public property to String extension
- [x] 2.10.2 Build verification

## Priority 3: Medium Impact, Higher Effort

### P3.11: Extract shared Slider/Stepper editing state into protocol
- **Affected:** `SliderHandler.swift`, `StepperHandler.swift`
- **Analysis Result:** Detailed code comparison revealed that while the editing state
  methods (`beginEditingIfNeeded`, `endEditingIfNeeded`) are identical (10 lines total),
  a protocol cannot provide stored properties (`isEditing`, `onEditingChanged`).
  Both handlers would still need to declare these properties themselves. The protocol
  would only save ~10 lines while adding a new type and conformance boilerplate.
  Value manipulation (`increment`/`decrement`/`clampValue`) differs significantly
  between handlers (`BinaryFloatingPoint` vs `Strideable`, optional vs required bounds,
  callback-based stepper variant). Net savings do not justify the added complexity.
- [x] 3.11.1 Analysis complete (decided against implementation - over-engineering)

### P3.12: Replace Mirror-based button extraction in Alert
- **Affected:** `Alert.swift`
- **Approach:** Created `ButtonProvider` protocol with conformances for `Button`,
  `EmptyView`, and `TupleView`. TupleView uses `repeat` over parameter pack to
  iterate children. Replaced fragile `Mirror(reflecting:)` + string-based type
  checks with a single `as? ButtonProvider` cast.
- [x] 3.12.1 Design `ButtonProvider` protocol approach
- [x] 3.12.2 Implement protocol with conformances (Button, EmptyView, TupleView)
- [x] 3.12.3 Remove Mirror usage from `_AlertCore.collectButtons()`
- [x] 3.12.4 Build verification

### P3.13: Modularize image processing into separate target
- **Affected:** `Image/`, `CSTBImage/`
- **Effort:** Large. Requires reorganizing package structure.
- [ ] 3.13.1 Evaluate coupling between Image module and core framework
- [ ] 3.13.2 Define module boundaries and public API surface
- [ ] 3.13.3 Create `TUIkitImage` package target
- [ ] 3.13.4 Move image files and update imports
- [ ] 3.13.5 Build and test verification

### P3.14: Document View protocol and ViewBuilder
- **Affected:** `Core/View.swift`, `Core/ViewBuilder.swift`
- **Analysis Result:** Reviewed all mentioned files. Documentation is already comprehensive:
  - `View` protocol: Full doc with dual rendering system explanation, composite/primitive
    examples, and thread safety notes
  - `ViewBuilder`: Struct-level doc with all supported constructs, plus per-method docs
  - `ChildInfo`, `ChildInfoProvider`, `ChildViewProvider`: All have doc comments
  - `renderToBuffer()` free function: 20+ line doc with example flow diagram
  - `Renderable` protocol: Extensive doc explaining the rendering dispatch and conformance rules
  The documentation gaps from the initial analysis no longer exist.
- [x] 3.14.1 Review complete (documentation already comprehensive)

### P3.15: Add process name sanitization in file storage paths
- **Affected:** `AppStorage.swift`, `UserDefaultsStorage.swift`
- **Approach:** Added `sanitizedProcessName(_:)` function in `AppStorage.swift` (internal,
  accessible from `UserDefaultsStorage.swift`). Strips `/`, `\0`, and `..` sequences.
  Falls back to `"app"` if result is empty.
- [x] 3.15.1 Add `sanitizedProcessName(_:)` function in `AppStorage.swift`
- [x] 3.15.2 Apply sanitization in `appConfigDirectory()` (`AppStorage.swift`)
- [x] 3.15.3 Apply sanitization in `UserDefaultsStorage.createStorage()`
- [x] 3.15.4 Build verification

## Priority 4: Long-term Architectural

### P4.16: Replace RenderNotifier.current global with dependency injection
- **Affected:** `State/State.swift`, entire `@State` system
- **Effort:** Large. Fundamental change to how property wrappers trigger re-renders.
- [ ] 4.16.1 Research dependency injection approaches for property wrappers
- [ ] 4.16.2 Design alternative to `nonisolated(unsafe) static var`
- [ ] 4.16.3 Implement and migrate all usages
- [ ] 4.16.4 Verify no regression in render pipeline

### P4.17: Generic ItemListHandler to preserve type safety
- **Affected:** `ItemListHandler.swift`, `_ListCore.swift`, `Table.swift`
- **Effort:** Large. Currently uses `[AnyHashable]` for item IDs.
- [ ] 4.17.1 Design `ItemListHandler<ID: Hashable>` approach
- [ ] 4.17.2 Evaluate impact on `StateStorage` (generic type erasure)
- [ ] 4.17.3 Implement generic handler
- [ ] 4.17.4 Update List and Table to use generic handler

### P4.18: Evaluate MainActor.assumeIsolated in Equatable safety
- **Affected:** 20 Equatable conformances across 17 files
- **Approach:** Replaced `nonisolated static func == ... MainActor.assumeIsolated { }` with
  `@preconcurrency Equatable` (SE-0423). This eliminates runtime `fatalError` risk when
  called from non-main contexts, removes boilerplate, and provides a clean migration path
  to `@MainActor Equatable` (SE-0470) in Swift 6.2.
- **Files changed:** VStack, HStack, ZStack, Box, Image, Card, Panel, Dialog,
  NavigationSplitView, ProgressView, LazyStacks (×2), ContainerView (×2),
  DimmedModifier, SelectionDisabledModifier, BadgeModifier, OverlayModifier,
  FlexibleFrameView, ListRowSeparatorModifier
- [x] 4.18.1 Evaluate Swift 6 concurrency evolution proposals
- [x] 4.18.2 Test behavior when called from non-main contexts
- [x] 4.18.3 Document findings and decide on approach
- [x] 4.18.4 Migrate all 20 conformances to `@preconcurrency Equatable`
- [x] 4.18.5 Build and test verification

### P4.19: Add image size limits and URL timeout configuration
- **Affected:** `ImageLoader.swift`, `Image.swift`, `_ImageCore.swift`
- **Approach:** Added two environment-driven configurations via modifier-first pattern:
  - `.imageMaxPixelCount(_:)` - rejects images exceeding a total pixel count limit
  - `.imageURLTimeout(_:)` - configurable URL download timeout (default: 30s)
  Replaced `Data(contentsOf:)` with `URLSession.dataTask` + semaphore for proper
  timeout support. Added `ImageLoadError.imageTooLarge` error case. Both limits
  propagate through environment and are captured before the async loading task.
- [x] 4.19.1 Add environment keys and View modifiers (`imageMaxPixelCount`, `imageURLTimeout`)
- [x] 4.19.2 Add `imageTooLarge` error case to `ImageLoadError`
- [x] 4.19.3 Add `maxPixelCount` parameter to `PlatformImageLoader.loadImage` methods
- [x] 4.19.4 Replace `Data(contentsOf:)` with `URLSession` + configurable timeout
- [x] 4.19.5 Wire environment values in `_ImageCore.renderToBuffer`
- [x] 4.19.6 Build and test verification

### P4.20: Split framework into multiple Swift package modules
- **Affected:** Entire package structure
- **Effort:** Very large.
- [ ] 4.20.1 Define module boundaries (Core, Styling, Focus, Image, Notification, StatusBar)
- [ ] 4.20.2 Resolve cross-module dependencies
- [ ] 4.20.3 Create separate targets in Package.swift
- [ ] 4.20.4 Update all imports and access levels
- [ ] 4.20.5 Build and test all modules

## Additional Findings (from Analysis Sections 3-4, 10)

### Code Style and Cleanup

- [x] Remove unnecessary `import Foundation` from files that don't use Foundation types
  - Removed from 29 files. 3 initially flagged files (Spinner, Focus, View+Events) were
    restored after build failure (they use TimeInterval, Date, UUID from Foundation).
- [x] Split remaining 500+ line files:
  - `TextFieldHandler.swift` 633 -> 447 (clipboard ops -> `TextFieldHandler+Clipboard.swift` 193)
  - `Color.swift` 600 -> 533 (`ANSIColor` enum -> `ANSIColor.swift` 70)
  - `Renderable.swift` 553 -> 279 (`RenderContext` -> `RenderContext.swift` 279)
  - `Focus.swift` 598 unchanged (FocusState too small for standalone file)
- [x] Review `UserDefaultsStorage` Linux convenience methods for potential removal
  - Reviewed: Methods provide UserDefaults API compatibility for Linux users. Not used
    internally but useful for migration from Apple platforms. Keeping as-is.
- [x] Add deprecation timeline for `progressBarStyle(_:)` in `ProgressView.swift`
  - Added "Scheduled for removal in the next major version" note
  - Migrated all tests from `progressBarStyle` to `trackStyle`
- [ ] Organize `project-template/` or move to separate repository

### Test Coverage Improvements

- [ ] Add tests for `ASCIIConverter` and `RGBAImage`
- [ ] Add tests for `Notification/` subsystem
- [ ] Add tests for View extension files in `Extensions/`
- [ ] Evaluate test coverage for `App/` subsystem (RenderLoop, InputHandler, etc.)

## Summary

| Priority | Total Topics | Completed | Remaining |
|----------|-------------|-----------|-----------|
| P1       | 5           | 5         | 0         |
| P2       | 5           | 5         | 0         |
| P3       | 5           | 4         | 1         |
| P4       | 5           | 2         | 3         |
| Additional | 9         | 4         | 5         |
| **Total**  | **29**    | **20**    | **9**     |

---

*Generated from `papers/project_analysis.md` (2026-02-14)*
*Last updated: 2026-02-14T23:00:00Z*
