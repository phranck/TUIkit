# Code Review Fixes: Swift 6 Concurrency and Architectural Improvements

## Preface

A comprehensive code review identified critical issues with Swift 6 concurrency readiness, missing abstractions for testability, and minor architectural debt. This plan addresses all findings systematically: introducing `@MainActor` isolation for render-loop-only types, adding thread-safe synchronization where cross-thread access occurs, extracting a `TerminalProtocol` for testability, fixing ForEach's runtime crash, and consolidating duplicated focus handler code. The result is a codebase ready for Swift 6 strict concurrency mode with improved testability and maintainability.

## Context / Problem

The code review identified the following issues:

### Critical: Swift 6 Concurrency
- 23 types use `@unchecked Sendable` without actual synchronization
- `PulseTimer` fires on a background queue and calls `setNeedsRender()` on shared state
- Signal handlers write to global flags without atomics
- All types assume single-threaded execution but don't enforce it

### High: Missing Abstractions
- `Terminal` class has no protocol, preventing test mocking
- Direct I/O operations cannot be intercepted for testing

### Medium: Runtime Errors
- `ForEach` crashes at runtime if used outside ViewBuilder context
- Should fail at compile-time instead

### Medium: Code Duplication
- `ButtonHandler`, `ToggleHandler`, `RadioButtonGroupHandler` share identical patterns
- Focus registration and key event handling is duplicated

### Medium: Initialization Patterns
- `AppRunner` uses implicitly unwrapped optionals (`!`)
- Could crash if initialization order changes

## Specification / Goal

1. Make all render-loop-only types `@MainActor` isolated
2. Protect cross-thread state access with `OSAllocatedUnfairLock`
3. Extract `TerminalProtocol` for test mocking
4. Make `ForEach` fail at compile-time when misused
5. Consolidate focus handlers into reusable `ActionHandler`
6. Remove implicitly unwrapped optionals from `AppRunner`
7. All changes must pass build, tests, and lint on macOS and Linux

## Design

### Phase 1: Thread-Safe Primitives

Before adding `@MainActor`, we need thread-safe primitives for cross-thread communication.

#### AppState.needsRender with Lock

```swift
import os

public final class AppState: Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: AppStateData())
    
    private struct AppStateData {
        var needsRender = false
        var observers: [() -> Void] = []
    }
    
    public func setNeedsRender() {
        lock.withLock { state in
            state.needsRender = true
            for observer in state.observers {
                observer()
            }
        }
    }
    
    var needsRender: Bool {
        lock.withLock { $0.needsRender }
    }
    
    func didRender() {
        lock.withLock { $0.needsRender = false }
    }
}
```

#### Signal Flags with Lock

```swift
// SignalManager.swift
private let signalLock = OSAllocatedUnfairLock(initialState: SignalFlags())

private struct SignalFlags {
    var needsRerender = false
    var terminalResized = false
    var needsShutdown = false
}

// Signal handlers set flags atomically
signal(SIGINT) { _ in
    signalLock.withLockUnchecked { $0.needsShutdown = true }
}
```

Note: `withLockUnchecked` is required in signal handlers because they cannot throw.

### Phase 2: @MainActor on Core Types

After thread-safe primitives are in place, add `@MainActor` to types that are only accessed from the render loop.

#### Types to Annotate

| Type | File | Notes |
|------|------|-------|
| `Terminal` | Terminal.swift | All I/O is render-loop |
| `RenderCache` | RenderCache.swift | Only accessed during render |
| `StateStorage` | StateStorage.swift | Only accessed during render |
| `StateBox<Value>` | StateStorage.swift | Mutations trigger re-render |
| `FocusManager` | Focus.swift | Only accessed during render |
| `KeyEventDispatcher` | KeyEvent.swift | Only accessed from input loop |
| `TUIContext` | TUIContext.swift | Container for other @MainActor types |
| `LifecycleManager` | TUIContext.swift | Already uses NSLock internally |
| `ThemeManager` | ThemeManager.swift | Only accessed from render loop |
| `StatusBarState` | StatusBarState.swift | Only accessed from render loop |
| `AppHeaderState` | AppHeaderState.swift | Only accessed from render loop |
| `NotificationService` | NotificationService.swift | Only accessed from render loop |
| `PreferenceStorage` | Preferences.swift | Only accessed during render |

#### Example: Terminal

```swift
@MainActor
final class Terminal: Sendable {
    private var isRawMode = false
    private var frameBuffer: [UInt8] = []
    
    // All methods are now MainActor-isolated
    func write(_ string: String) { ... }
    func readKeyEvent() -> KeyEvent? { ... }
}
```

#### PulseTimer Adaptation

`PulseTimer` fires on a background queue. Two options:

**Option A: Dispatch to MainActor (Recommended)**
```swift
source.setEventHandler { [weak self] in
    guard let self else { return }
    self.currentStep = (self.currentStep + 1) % (self.totalHalfSteps * 2)
    // Dispatch to MainActor
    Task { @MainActor in
        self.renderNotifier?.setNeedsRender()
    }
}
```

**Option B: Keep AppState.setNeedsRender() nonisolated**

If `AppState` uses internal locking, `setNeedsRender()` can be `nonisolated`:
```swift
@MainActor
public final class AppState: Sendable {
    private let lock = OSAllocatedUnfairLock(...)
    
    // Can be called from any thread
    nonisolated public func setNeedsRender() {
        lock.withLock { ... }
    }
}
```

We choose **Option B** because it avoids Task creation overhead on every pulse tick.

### Phase 3: TerminalProtocol for Testability

```swift
// TerminalProtocol.swift (new file)
protocol TerminalProtocol: Sendable {
    func getSize() -> (width: Int, height: Int)
    func write(_ string: String)
    func readKeyEvent() -> KeyEvent?
    func enableRawMode()
    func disableRawMode()
    func beginFrame()
    func endFrame()
    func moveCursor(toRow row: Int, column: Int)
    func hideCursor()
    func showCursor()
    func enterAlternateScreen()
    func exitAlternateScreen()
}

// Terminal.swift
@MainActor
final class Terminal: TerminalProtocol { ... }

// For tests:
final class MockTerminal: TerminalProtocol {
    var writtenOutput: [String] = []
    var keyEventQueue: [KeyEvent] = []
    var size: (width: Int, height: Int) = (80, 24)
    
    func write(_ string: String) {
        writtenOutput.append(string)
    }
    
    func readKeyEvent() -> KeyEvent? {
        keyEventQueue.isEmpty ? nil : keyEventQueue.removeFirst()
    }
    
    // ... other methods
}
```

### Phase 4: ForEach Compile-Time Error

Currently:
```swift
public struct ForEach<...>: View {
    public var body: Never {
        fatalError("ForEach is expanded by ViewBuilder, not rendered directly")
    }
}
```

Change to:
```swift
public struct ForEach<...>: View {
    @available(*, unavailable, message: "ForEach must be used inside a @ViewBuilder closure")
    public var body: Never {
        fatalError()
    }
}
```

This produces a compile-time error when someone tries to access `.body` directly.

### Phase 5: Consolidated ActionHandler

Current duplication:
```swift
final class ButtonHandler: Focusable { ... }
final class ToggleHandler: Focusable { ... }
final class RadioButtonGroupHandler: Focusable { ... }
```

Consolidate into:
```swift
// ActionHandler.swift (new file)
final class ActionHandler: Focusable {
    let focusID: String
    let action: () -> Void
    var canBeFocused: Bool
    let triggerKeys: Set<KeyEvent.Key>
    
    init(
        focusID: String,
        action: @escaping () -> Void,
        canBeFocused: Bool = true,
        triggerKeys: Set<KeyEvent.Key> = [.enter, .character(" ")]
    ) {
        self.focusID = focusID
        self.action = action
        self.canBeFocused = canBeFocused
        self.triggerKeys = triggerKeys
    }
    
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        guard triggerKeys.contains(event.key) else { return false }
        action()
        return true
    }
}
```

Usage in Button:
```swift
let handler = ActionHandler(
    focusID: focusID,
    action: action,
    canBeFocused: !isDisabled
)
```

Usage in Toggle:
```swift
let handler = ActionHandler(
    focusID: focusID,
    action: { binding.wrappedValue.toggle() },
    canBeFocused: !isDisabled
)
```

### Phase 6: AppRunner Initialization

Current:
```swift
private var inputHandler: InputHandler!
private var renderer: RenderLoop<A>!
private var pulseTimer: PulseTimer!
```

Change to lazy initialization or struct-based dependencies:
```swift
private struct Dependencies {
    let inputHandler: InputHandler
    let renderer: RenderLoop<A>
    let pulseTimer: PulseTimer
}

private var dependencies: Dependencies?

func run() throws {
    let deps = Dependencies(
        inputHandler: InputHandler(...),
        renderer: RenderLoop(...),
        pulseTimer: PulseTimer(...)
    )
    self.dependencies = deps
    // ... use deps directly
}
```

## Implementation Plan

### Phase 1: Thread-Safe Primitives (Foundation)
1. Add `OSAllocatedUnfairLock` to `AppState` for `needsRender` and observers
2. Update `SignalManager` to use locked access for signal flags
3. Update `PulseTimer` to call `setNeedsRender()` safely (nonisolated method)
4. Build and test

### Phase 2: @MainActor on Core Types
1. Add `@MainActor` to `Terminal`
2. Add `@MainActor` to `RenderCache`
3. Add `@MainActor` to `StateStorage` and `StateBox`
4. Add `@MainActor` to `FocusManager`
5. Add `@MainActor` to `KeyEventDispatcher`
6. Add `@MainActor` to `TUIContext` and `LifecycleManager`
7. Add `@MainActor` to `ThemeManager`, `StatusBarState`, `AppHeaderState`
8. Add `@MainActor` to `NotificationService`
9. Add `@MainActor` to `PreferenceStorage`
10. Fix any resulting compiler errors (add `nonisolated` where needed)
11. Build and test

### Phase 3: TerminalProtocol
1. Create `TerminalProtocol.swift` with protocol definition
2. Make `Terminal` conform to `TerminalProtocol`
3. Create `MockTerminal` for tests
4. Update `AppRunner` to accept `TerminalProtocol` (optional, for future DI)
5. Build and test

### Phase 4: ForEach Compile-Time Error
1. Add `@available(*, unavailable, ...)` to `ForEach.body`
2. Verify compile-time error appears when accessing `body` directly
3. Build and test

### Phase 5: ActionHandler Consolidation
1. Create `ActionHandler.swift` with consolidated handler
2. Update `Button` to use `ActionHandler`
3. Update `Toggle` to use `ActionHandler`
4. Update `RadioButtonGroup` to use `ActionHandler`
5. Remove `ButtonHandler`, `ToggleHandler`, `RadioButtonGroupHandler`
6. Build and test

### Phase 6: AppRunner Cleanup
1. Replace implicitly unwrapped optionals with `Dependencies` struct
2. Update initialization flow
3. Build and test

### Phase 7: Final Verification
1. Run full test suite
2. Run SwiftLint
3. Test on Linux (CI or Docker)
4. Update documentation if needed

## Checklist

### Phase 1: Thread-Safe Primitives
- [x] Add OSAllocatedUnfairLock to AppState
- [x] Update SignalManager with improved documentation (flags stay nonisolated for signal handler safety)
- [x] AppState.setNeedsRender() is now thread-safe with internal lock
- [x] Build passes
- [x] Tests pass

### Phase 2: @MainActor Isolation
- [x] Terminal: @MainActor
- [x] FrameDiffWriter: @MainActor
- [x] RenderLoop: @MainActor
- [x] AppRunner: @MainActor
- [x] ViewRenderer: @MainActor
- [x] App.main() uses MainActor.assumeIsolated
- [x] renderOnce(): @MainActor
- [x] Tests updated with @MainActor
- [x] Build passes
- [x] Tests pass (591/591)

#### Phase 2b: Additional @MainActor (pending)
- [ ] RenderCache: @MainActor
- [ ] StateStorage, StateBox: @MainActor
- [ ] FocusManager: @MainActor
- [ ] KeyEventDispatcher: @MainActor
- [ ] TUIContext, LifecycleManager: @MainActor
- [ ] ThemeManager: @MainActor
- [ ] StatusBarState: @MainActor
- [ ] AppHeaderState: @MainActor
- [ ] NotificationService: @MainActor
- [ ] PreferenceStorage: @MainActor

### Phase 3: TerminalProtocol
- [ ] Create TerminalProtocol.swift
- [ ] Terminal conforms to TerminalProtocol
- [ ] Create MockTerminal for tests
- [ ] Build passes
- [ ] Tests pass

### Phase 4: ForEach
- [ ] Add @available(*, unavailable) to ForEach.body
- [ ] Verify compile-time error
- [ ] Build passes
- [ ] Tests pass

### Phase 5: ActionHandler
- [ ] Create ActionHandler.swift
- [ ] Update Button to use ActionHandler
- [ ] Update Toggle to use ActionHandler
- [ ] Update RadioButtonGroup to use ActionHandler
- [ ] Remove old handler classes
- [ ] Build passes
- [ ] Tests pass

### Phase 6: AppRunner
- [ ] Replace implicitly unwrapped optionals
- [ ] Update initialization flow
- [ ] Build passes
- [ ] Tests pass

### Phase 7: Final
- [ ] Full test suite passes (591+ tests)
- [ ] SwiftLint passes
- [ ] Linux CI passes
- [ ] Documentation updated

## Files Affected

### New Files
- `Sources/TUIkit/Rendering/TerminalProtocol.swift`
- `Sources/TUIkit/Focus/ActionHandler.swift`
- `Tests/TUIkitTests/MockTerminal.swift` (optional)

### Modified Files
- `Sources/TUIkit/State/State.swift` (AppState with lock)
- `Sources/TUIkit/App/SignalManager.swift` (locked flags)
- `Sources/TUIkit/App/PulseTimer.swift` (nonisolated call)
- `Sources/TUIkit/Rendering/Terminal.swift` (@MainActor)
- `Sources/TUIkit/Rendering/RenderCache.swift` (@MainActor)
- `Sources/TUIkit/State/StateStorage.swift` (@MainActor)
- `Sources/TUIkit/Focus/Focus.swift` (@MainActor)
- `Sources/TUIkit/Core/KeyEvent.swift` (@MainActor)
- `Sources/TUIkit/Environment/TUIContext.swift` (@MainActor)
- `Sources/TUIkit/Styling/ThemeManager.swift` (@MainActor)
- `Sources/TUIkit/StatusBar/StatusBarState.swift` (@MainActor)
- `Sources/TUIkit/AppHeader/AppHeaderState.swift` (@MainActor)
- `Sources/TUIkit/Notification/NotificationService.swift` (@MainActor)
- `Sources/TUIkit/Environment/Preferences.swift` (@MainActor)
- `Sources/TUIkit/Views/ForEach.swift` (@available)
- `Sources/TUIkit/Views/Button.swift` (use ActionHandler)
- `Sources/TUIkit/Views/Toggle.swift` (use ActionHandler)
- `Sources/TUIkit/Views/RadioButton.swift` (use ActionHandler)
- `Sources/TUIkit/App/AppRunner.swift` (remove IUOs)

## Risks and Mitigations

### Risk: OSAllocatedUnfairLock not available on older Linux
**Mitigation:** Check Swift version. Fall back to `NSLock` if needed:
```swift
#if canImport(os)
    import os
    private let lock = OSAllocatedUnfairLock(...)
#else
    private let lock = NSLock()
#endif
```

### Risk: @MainActor breaks async code paths
**Mitigation:** Use `nonisolated` for methods that must be callable from any context. Test thoroughly.

### Risk: ActionHandler consolidation changes behavior
**Mitigation:** Existing tests for Button, Toggle, RadioButton will catch regressions.

### Risk: Large PR is hard to review
**Mitigation:** Can split into multiple PRs by phase if needed.

## Dependencies

- Swift 6.0 (already required by Package.swift)
- macOS 14+ for OSAllocatedUnfairLock (or fallback to NSLock)
- No external package dependencies

## Timeline Estimate

- Phase 1: 30 minutes
- Phase 2: 2 hours (many files, potential compiler errors)
- Phase 3: 30 minutes
- Phase 4: 10 minutes
- Phase 5: 45 minutes
- Phase 6: 20 minutes
- Phase 7: 30 minutes

**Total: ~4-5 hours**

## Success Criteria

1. `swift build` succeeds on macOS and Linux
2. All 591+ tests pass
3. SwiftLint reports no serious issues
4. No `@unchecked Sendable` remains (except where justified with documentation)
5. Swift 6 strict concurrency mode produces no warnings (future verification)
