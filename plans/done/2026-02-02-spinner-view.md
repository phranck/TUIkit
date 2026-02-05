# Spinner View

## Completed

Completed on 2026-02-02. PR #61 merged.

Three styles (dots, line, bouncing Knight Rider with ● dot fade trail). Simplified API: `Spinner("Label", style: .bouncing, color: .green)`. Fixed calibrated intervals, 9-position track with 2-position edge overshoot for smooth trail fade-in/out. Run loop upgraded to ~25 FPS (VTIME=0 + usleep 40ms).

### Final API

```swift
Spinner()                                        // default: .dots
Spinner("Loading...", style: .line)
Spinner("Processing...", style: .bouncing, color: .cyan)
```

### Key Design Decisions

- **Radically simplified API** — Removed `SpinnerSpeed`, `BouncingTrackWidth`, `BouncingTrailLength` enums. One init with 3 parameters.
- **Uniform dot character (●)** — All track positions use the same character. Visual distinction comes purely from opacity fade. Avoids Unicode alignment issues between different dot characters.
- **Edge overshoot (2 positions)** — Highlight travels from -2 to trackWidth+1, so the trail fades smoothly at edges instead of being cut off.
- **6-step trail** — Opacities: [1.0, 0.75, 0.5, 0.35, 0.22, 0.15]. Last step matches inactive dot opacity (0.15) for seamless blend.
- **Fixed intervals** — Dots: 110ms, Line: 140ms, Bouncing: 100ms. Calibrated by user testing.
- **Time-based frames** — Frame index calculated from elapsed time, not counter-based. Prevents drift.
- **VTIME=0 run loop** — Non-blocking stdin read + usleep(40ms) for ~25 FPS. Benefits all future animations.

## Goal

Add an auto-animating `Spinner` view to TUIKit with three built-in styles: dots (braille rotation), line (ASCII rotation), and bouncing (Knight Rider / Larson scanner).

## Architecture

### Timer Strategy

The run loop uses non-blocking stdin (VTIME=0) with usleep(40ms) polling (~25 FPS). The Spinner uses `LifecycleManager.startTask()` to run a background async loop that calls `setNeedsRender()` at 40ms intervals. The actual animation speed is determined by time-based frame index calculation, not the trigger interval.

### Frame Index Persistence

The Spinner stores its start time in `StateStorage` using the view's identity from `RenderContext`. Frame index is calculated from elapsed time divided by the style's interval.

### Rendering

- **dots/line:** Single character from the frame array, colored, followed by optional label
- **bouncing:** 9 ● dots with opacity fade trail. Highlight bounces with 2-position overshoot at edges.

## Implementation

- [x] 1. Create `SpinnerStyle` enum with `dots`, `line`, `bouncing` cases
- [x] 2. Implement frame generation with bounce positions and edge overshoot
- [x] 3. Fixed intervals: dots 110ms, line 140ms, bouncing 100ms
- [x] 4. Create `Spinner` struct with label, style, color properties
- [x] 5. Implement `Renderable` conformance with time-based frame calculation
- [x] 6. Implement lifecycle-based timer (startTask/cancelTask pattern)
- [x] 7. Start time persistence via StateStorage
- [x] 8. Add Spinner to Example App (SpinnersPage)
- [x] 9. Write tests (frame generation, bounce positions, rendering output)
- [x] 10. Add DocC topic entry
- [x] 11. Simplify API (remove speed/track/trail enums)
- [x] 12. Switch to uniform ● dot character with opacity-only fade
- [x] 13. Add edge overshoot for smooth trail fade at track edges
