# ProgressView — Determinate Progress Bar

## Preface

`ProgressView` adds progress bars to TUI apps: horizontal bars that fill to a percentage (0–100), with five Unicode styles (block, blockFine, shade, bar, dot), optional labels, and SwiftUI API parity. Supports `BinaryFloatingPoint` values with total, ViewBuilder label closures, and currentValueLabel for custom percentage display. Optional `.disabled()` modifier, proper width clamping, and edge-case handling for nil/negative/overflow values.

## Completed

**2026-02-05** — PR merged with all progress bar styles, full SwiftUI API parity, and 26 tests passing.

## Checklist

- [x] Create ProgressView struct with all 4 initializer variants
- [x] Implement Equatable conformance
- [x] Implement 5 bar styles (block, blockFine, shade, bar, dot)
- [x] Create .progressBarStyle(_:) modifier
- [x] Implement Renderable with bar rendering
- [x] Add .disabled() modifier
- [x] Write 26 comprehensive tests
- [x] Add to example app (ContainersPage)
- [x] swift build + swiftlint + swift test

## Goal

Add a `ProgressView` that matches SwiftUI's determinate progress API. Renders as a horizontal bar using Unicode block characters.

## SwiftUI API Parity

```swift
// Minimal
ProgressView(value: 0.5)

// With total
ProgressView(value: 3, total: 10)

// With String title
ProgressView("Loading...", value: 0.5)

// With ViewBuilder label
ProgressView(value: 0.5) {
    Text("Downloading")
}

// With label + currentValueLabel
ProgressView(value: 0.5) {
    Text("Downloading")
} currentValueLabel: {
    Text("50%")
}
```

### Signatures implemented

```swift
init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0)
    where Label == EmptyView, CurrentValueLabel == EmptyView

init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0, @ViewBuilder label: () -> Label)
    where CurrentValueLabel == EmptyView

init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0, @ViewBuilder label: () -> Label, @ViewBuilder currentValueLabel: () -> CurrentValueLabel)

init<S: StringProtocol, V: BinaryFloatingPoint>(_ title: S, value: V?, total: V = 1.0)
    where Label == Text, CurrentValueLabel == EmptyView
```

## TUI Rendering

### Visual Output

```
Downloading        50%
████████████████▌░░░░░░░░░░░░░░░
```

- **Line 1** (optional): Label (left) + CurrentValueLabel (right)
- **Line 2**: Progress bar (no brackets)

### Styles

5 built-in styles via `.progressBarStyle(_:)` modifier:

```
block:     ████████████████░░░░░░░░░░░░░░░░       (whole blocks)
blockFine: ████████████████▍░░░░░░░░░░░░░░░       (sub-character precision via ▉▊▋▌▍▎▏)
shade:     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░
bar:       ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌────────────────
dot:       ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬●────────────────       (● head in accent color)
```

### Width

- Fills `availableWidth` (no brackets, no width reduction)

### Colors

| Part | Color |
|------|-------|
| Filled bar | `palette.foregroundSecondary` |
| Empty bar | `palette.foregroundTertiary` |
| Dot head (`.dot` only) | `palette.accent` |
| Label | inherited from label view |
| CurrentValueLabel | inherited from value label view |

### Edge Cases

- `value: nil` → indeterminate → renders empty bar (0% fallback)
- `value < 0` → clamp to 0
- `value > total` → clamp to total
- `total <= 0` → show empty bar
- No label, no currentValueLabel → bar only (1 line)

## Steps

- [x] Create `Sources/TUIkit/Views/ProgressView.swift`
- [x] Implement all 4 initializers with SwiftUI-matching signatures
- [x] Implement `Renderable` with bar rendering
- [x] Add `Equatable` conformance
- [x] Implement 5 bar styles via `ProgressBarStyle` enum + `.progressBarStyle(_:)` modifier
- [x] Create tests in `Tests/TUIkitTests/ProgressViewTests.swift` (26 tests / 3 suites)
- [x] Add to example app (ContainersPage — ProgressViewRow)
- [x] `swift build` + `swiftlint` + `swift test`
