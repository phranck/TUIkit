# Toast View

## Superseded

Superseded on 2026-02-05 by the Notification System (PR #77). The final implementation diverged significantly: fire-and-forget `NotificationService.post()` instead of `Binding<Bool>`, no severity styles (just a notification), fixed top-right placement, `Box`-based rendering.

## Goal

Add a `.toast()` view modifier to TUIKit that shows a temporary notification message with auto-dismiss, fade-in/fade-out animation, and preset severity styles.

## API Design

```swift
// Simple usage
content.toast("Saved!", isPresented: $showToast)

// With style
content.toast("Failed to save", isPresented: $showError, style: .error)

// With custom duration
content.toast("Done!", isPresented: $showDone, style: .success, duration: 5.0)

// With alignment
content.toast("Info", isPresented: $show, style: .info, alignment: .top)
```

### Parameters

- `message: String` — the toast text
- `isPresented: Binding<Bool>` — controls visibility; auto-set to `false` after dismiss
- `style: ToastStyle` — visual preset (default: `.info`)
- `duration: TimeInterval` — how long the toast stays visible (default: 3.0)
- `alignment: Alignment` — where to position the toast (default: `.bottom`)

### ToastStyle

```swift
public enum ToastStyle {
    case info       // accent color
    case success    // green
    case warning    // yellow
    case error      // red
}
```

Each style provides a border color and an optional icon/prefix character.

## Architecture

### Animation via Opacity Interpolation

The toast uses the same lifecycle task pattern as Spinner, but instead of cycling frames, it interpolates an opacity value across three phases:

1. **Fade-In** (~200ms, ~5 frames at 40ms): opacity 0.0 → 1.0
2. **Visible** (duration seconds): opacity 1.0, no task needed
3. **Fade-Out** (~300ms, ~8 frames at 40ms): opacity 1.0 → 0.0
4. **Dismiss**: set `isPresented = false`

The current phase and start time are stored in `StateStorage`. A lifecycle task runs at 40ms intervals (matching the run loop), calculates the current opacity from elapsed time, and calls `setNeedsRender()`.

All text rendering goes through `ANSIRenderer.colorize()` which supports `Color.opacity()` — this gives us smooth fading using the existing RGB color system.

### Rendering

The toast is rendered as a bordered single-line (or multi-line) box:

```
┌─────────────────────┐
│ ✓ Operation saved!  │
└─────────────────────┘
```

Or minimal (no border, just colored text with background):

```
 ✓ Operation saved! 
```

Positioned via `.overlay(alignment:)` on the base content.

### State Management

The `ToastModifier` is a `Renderable` that manages:
- A lifecycle token (UUID-based) for the animation task
- StateStorage entries for: phase enum, phase start time, current opacity
- The `Binding<Bool>` for isPresented — flipped to `false` after fade-out completes

### Integration with Existing Systems

| Component | How Used |
|---|---|
| `OverlayModifier` / `.overlay()` | Positioning toast over content |
| `LifecycleManager.startTask/cancelTask` | Animation timer + auto-dismiss |
| `RenderNotifier.setNeedsRender()` | Trigger re-render during animation |
| `StateStorage` | Persist animation phase/timing across renders |
| `ContainerView` / `renderContainer()` | Toast box rendering (border + padding) |
| `Color.opacity()` + `ANSIRenderer.colorize()` | Fade effect |
| `Binding<Bool>` | isPresented control |

## Implementation

### Phase 1: Toast View + Style

- [ ] 1. Create `ToastStyle` enum with `.info`, `.success`, `.warning`, `.error`
- [ ] 2. Create `Toast` view (bordered box with icon + message, color from style)
- [ ] 3. Support opacity parameter for fade rendering

### Phase 2: ToastModifier + Animation

- [ ] 4. Create `ToastModifier` with lifecycle task for fade animation
- [ ] 5. Implement three-phase animation (fade-in → visible → fade-out → dismiss)
- [ ] 6. Store animation state in StateStorage
- [ ] 7. Flip `isPresented` binding to false after fade-out

### Phase 3: Public API + Integration

- [ ] 8. Add `.toast()` extension on `View`
- [ ] 9. Add Toast to Example App (SpinnersPage or new ToastsPage)
- [ ] 10. Write tests
- [ ] 11. Add DocC topic entry

## Open Questions

1. **Border or borderless?** Bordered box (like Alert) or minimal colored background strip?
2. **Icon characters?** `✓` success, `⚠` warning, `✕` error, `ℹ` info — or simpler?
3. **Max width?** Fixed width or auto-sized to message length?
