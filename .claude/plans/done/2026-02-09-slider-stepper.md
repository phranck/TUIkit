# Slider & Stepper Components

## Preface

This plan implements Slider and Stepper, two essential numeric input controls for TUIKit. Both components allow users to adjust values using keyboard navigation. Slider displays a visual track with a thumb indicator, while Stepper shows increment/decrement arrows around a value. Both use consistent focus indicators (pulsing vertical bars) matching TextField. The existing `ProgressBarStyle` will be renamed to `TrackStyle` for reuse across ProgressView and Slider.

## Completed

**2026-02-09** - Slider and Stepper complete with 59 new tests (892 total). TrackStyle refactor done with backwards-compatible typealias. TrackRenderer utility extracted and shared between ProgressView and Slider. Both components feature SwiftUI-conformant API, keyboard controls, focus indicators, and Example app demo pages.

## Checklist

### Phase 1: TrackStyle Refactor
- [x] Rename `ProgressBarStyle` to `TrackStyle`
- [x] Add backwards-compatible typealias
- [x] Extract `TrackRenderer` utility
- [x] Update ProgressView to use TrackRenderer
- [x] Verify ProgressView tests pass

### Phase 2: Slider
- [x] Create SliderHandler class (14 tests)
- [x] Create Slider struct with body: some View
- [x] Implement _SliderCore with Renderable
- [x] Render track with arrows and value display
- [x] Focus indicators (pulsing bars)
- [x] Keyboard controls (arrow keys, +/-, Home/End)
- [x] `.trackStyle(_:)` modifier
- [x] `.disabled()` support
- [x] `onEditingChanged` callback
- [x] SliderPage in Example app (14 tests)

### Phase 3: Stepper
- [x] Create StepperHandler class (19 tests)
- [x] Create Stepper struct with body: some View
- [x] Implement _StepperCore with Renderable
- [x] Render arrows around value
- [x] Focus indicators (pulsing bars + arrows)
- [x] Keyboard controls (arrow keys, +/-, Home/End)
- [x] `init(_ title:, value:, step:)` - basic
- [x] `init(_ title:, value:, in:, step:)` - with range
- [x] `init(_ title:, onIncrement:, onDecrement:)` - callbacks
- [x] `.disabled()` support
- [x] StepperPage in Example app (12 tests)

## Context / Problem

TUIKit currently lacks controls for numeric value adjustment. Users need ways to:

- Select values from a continuous range (volume, brightness, opacity)
- Increment/decrement discrete values (quantity, count, rating)

Both Slider and Stepper are fundamental SwiftUI controls that fill this gap.

## Specification / Goal

### Success Criteria

1. **Slider**: Interactive track with keyboard control, SwiftUI-conformant API
2. **Stepper**: Increment/decrement with arrows, SwiftUI-conformant API
3. **TrackStyle**: Rename `ProgressBarStyle` to `TrackStyle` for shared use
4. **Consistent focus**: Both use `❙ content ❙` pattern like TextField
5. **All tests pass**

### SwiftUI API Reference

**Slider:**
```swift
init(value: Binding<V>, in: ClosedRange<V>, step: V.Stride, onEditingChanged: (Bool) -> Void)
init(_ title: String, value: Binding<V>, in: ClosedRange<V>)
```

**Stepper:**
```swift
init(_ title: String, value: Binding<V>, step: V.Stride)
init(_ title: String, value: Binding<V>, in: ClosedRange<V>, step: V.Stride)
init(_ title: String, onIncrement: (() -> Void)?, onDecrement: (() -> Void)?)
```

## Design

### Visual Rendering

**Slider:**
```
// Unfocused (block style - default):
Volume:    ◀ ████████████░░░░░░░░ ▶  50%

// Focused:
Volume:  ❙ ◀ ████████████░░░░░░░░ ▶ ❙ 50%

// Unfocused (dot style):
Volume:    ◀ ▬▬▬▬▬▬▬▬▬▬▬▬●─────── ▶  50%

// Focused (dot style):
Volume:  ❙ ◀ ▬▬▬▬▬▬▬▬▬▬▬▬●─────── ▶ ❙ 50%
```

**Stepper:**
```
// Unfocused:
Quantity:    ◀  5  ▶

// Focused:
Quantity:  ❙ ◀  5  ▶ ❙    (bars + arrows pulsing in accent)
```

### TrackStyle (renamed from ProgressBarStyle)

```swift
public enum TrackStyle: Sendable, Equatable {
    case block      // ████████░░░░░░░░ (default for Slider)
    case blockFine  // ████████▍░░░░░░░ (sub-character precision)
    case shade      // ▓▓▓▓▓▓▓▓░░░░░░░░
    case bar        // ▌▌▌▌▌▌▌▌────────
    case dot        // ▬▬▬▬▬▬▬▬●───────
}
```

### Keyboard Controls

**Both Slider and Stepper:**
| Key | Action |
|-----|--------|
| `←` or `-` | Decrement |
| `→` or `+` | Increment |
| `Home` | Jump to minimum (if range defined) |
| `End` | Jump to maximum (if range defined) |

### Architecture

Both components follow the established TUIKit pattern:

```swift
// Public View
public struct Slider<Label: View>: View {
    public var body: some View {
        _SliderCore(...)
    }
}

// Internal Renderable
private struct _SliderCore: View, Renderable {
    var body: Never { fatalError() }
    func renderToBuffer(context: RenderContext) -> FrameBuffer { ... }
}

// Focus Handler
final class SliderHandler: Focusable {
    func handleKeyEvent(_ event: KeyEvent) -> Bool { ... }
}
```

### Shared Track Rendering

Extract track rendering from `_ProgressViewCore` into a shared utility:

```swift
enum TrackRenderer {
    static func render(
        fraction: Double,
        width: Int,
        style: TrackStyle,
        filledColor: Color,
        emptyColor: Color,
        accentColor: Color
    ) -> String
}
```

## Implementation Plan

### Phase 1: TrackStyle Refactor

1. Rename `ProgressBarStyle` to `TrackStyle`
2. Add `typealias ProgressBarStyle = TrackStyle` for backwards compatibility
3. Extract track rendering into `TrackRenderer` utility
4. Update ProgressView to use `TrackRenderer`
5. Verify all ProgressView tests still pass

### Phase 2: Slider

1. Create `SliderHandler` in `Sources/TUIkit/Focus/`
2. Create `Slider.swift` in `Sources/TUIkit/Views/`
3. Implement rendering with `◀ track ▶` and value display
4. Implement focus indicators (pulsing bars)
5. Add keyboard controls (←/→, -/+, Home/End)
6. Add `.trackStyle(_:)` modifier

### Phase 3: Stepper

1. Create `StepperHandler` in `Sources/TUIkit/Focus/`
2. Create `Stepper.swift` in `Sources/TUIkit/Views/`
3. Implement rendering with `◀ value ▶`
4. Implement focus indicators (pulsing bars + arrows)
5. Add keyboard controls (←/→, -/+, Home/End)
6. Add `onIncrement`/`onDecrement` callback variant

### Phase 4: Testing & Demo

1. Unit tests for SliderHandler
2. Unit tests for StepperHandler
3. Rendering tests for Slider
4. Rendering tests for Stepper
5. Example app demo pages

## Original Checklist (archived)

### Phase 1: TrackStyle Refactor
- [x] Rename `ProgressBarStyle` to `TrackStyle`
- [x] Add backwards-compatible typealias
- [x] Extract `TrackRenderer` utility
- [x] Update ProgressView to use TrackRenderer
- [x] Verify ProgressView tests pass

### Phase 2: Slider
- [x] Create SliderHandler class
- [x] Create Slider struct with body: some View
- [x] Implement _SliderCore with Renderable
- [x] Render track with arrows
- [x] Render value label (percentage or custom)
- [x] Focus indicators (pulsing bars)
- [x] Keyboard: arrow keys for increment/decrement
- [x] Keyboard: - + for increment/decrement
- [x] Keyboard: Home/End for min/max
- [x] `.trackStyle(_:)` modifier
- [x] `.disabled()` support
- [x] `onEditingChanged` callback
- [x] Default width + `.frame(width:)` support

### Phase 3: Stepper
- [x] Create StepperHandler class
- [x] Create Stepper struct with body: some View
- [x] Implement _StepperCore with Renderable
- [x] Render arrows around value
- [x] Focus indicators (pulsing bars + arrows)
- [x] Keyboard: arrow keys for increment/decrement
- [x] Keyboard: - + for increment/decrement
- [x] Keyboard: Home/End for min/max (when range defined)
- [ ] `init(_ title:, value:, step:)` - basic
- [ ] `init(_ title:, value:, in:, step:)` - with range
- [ ] `init(_ title:, onIncrement:, onDecrement:)` - callbacks
- [ ] `.disabled()` support
- [ ] `onEditingChanged` callback

### Phase 4: Testing & Demo
- [ ] SliderHandler key event tests
- [ ] StepperHandler key event tests
- [ ] Slider rendering tests
- [ ] Stepper rendering tests
- [ ] SliderPage in Example app
- [ ] StepperPage in Example app

## Files

### New Files
- `Sources/TUIkit/Rendering/TrackRenderer.swift`
- `Sources/TUIkit/Focus/SliderHandler.swift`
- `Sources/TUIkit/Focus/StepperHandler.swift`
- `Sources/TUIkit/Views/Slider.swift`
- `Sources/TUIkit/Views/Stepper.swift`
- `Tests/TUIkitTests/SliderTests.swift`
- `Tests/TUIkitTests/SliderHandlerTests.swift`
- `Tests/TUIkitTests/StepperTests.swift`
- `Tests/TUIkitTests/StepperHandlerTests.swift`
- `Sources/TUIkitExample/Pages/SliderPage.swift`
- `Sources/TUIkitExample/Pages/StepperPage.swift`

### Modified Files
- `Sources/TUIkit/Views/ProgressView.swift` - use TrackStyle + TrackRenderer
- `Sources/TUIkit/Styles/TrackStyle.swift` - renamed from ProgressBarStyle (or new file)

## Dependencies

- FocusManager (for focus registration)
- StateStorage (for handler persistence)
- Existing View/Renderable architecture
- ProgressView track rendering (to be extracted)
