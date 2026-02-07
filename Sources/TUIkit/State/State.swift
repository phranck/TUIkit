//  🖥️ TUIKit — Terminal UI Kit for Swift
//  State.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import os

// MARK: - App State

/// Application state that triggers re-renders when modified.
///
/// `AppState` is thread-safe: ``setNeedsRender()`` can be called from any thread
/// (e.g., from ``PulseTimer`` on a background queue). Internal state is protected
/// by an `OSAllocatedUnfairLock`.
///
/// The ``AppRunner`` subscribes to state changes and re-renders when notified.
/// `AppRunner` creates the instance and registers it with ``RenderNotifier``
/// on startup. Property wrappers like ``State`` and ``AppStorage`` access it
/// through ``RenderNotifier/current``.
///
/// - Important: This is framework infrastructure. Prefer using ``State`` for reactive state
///   management in your views. Direct use of `AppState` is only necessary in advanced scenarios
///   where you manage state outside the view hierarchy.
public final class AppState: Sendable {
    /// Internal state protected by a lock.
    private struct StateData: Sendable {
        var needsRender = false
        var observers: [@Sendable () -> Void] = []
    }

    /// Lock protecting all mutable state.
    private let lock = OSAllocatedUnfairLock(initialState: StateData())

    /// Creates a new app state instance.
    public init() {}
}

// MARK: - Public API

public extension AppState {
    /// Marks state as changed and notifies observers.
    ///
    /// This method is thread-safe and can be called from any thread.
    ///
    /// Callers that change visual output (theme, palette, appearance) do
    /// **not** need to manually clear the render cache. ``RenderLoop``
    /// automatically detects environment changes via ``EnvironmentSnapshot``
    /// comparison and clears the cache when needed.
    func setNeedsRender() {
        let observers = lock.withLock { state -> [@Sendable () -> Void] in
            state.needsRender = true
            return state.observers
        }
        // Call observers outside the lock to avoid potential deadlocks
        for observer in observers {
            observer()
        }
    }
}

// MARK: - Internal API

extension AppState {
    /// Whether state has changed since last render.
    var needsRender: Bool {
        lock.withLock { $0.needsRender }
    }

    /// Registers an observer to be notified of state changes.
    ///
    /// - Parameter callback: The callback to invoke on state change.
    func observe(_ callback: @escaping @Sendable () -> Void) {
        lock.withLock { state in
            state.observers.append(callback)
        }
    }

    /// Clears all observers.
    func clearObservers() {
        lock.withLock { state in
            state.observers.removeAll()
        }
    }

    /// Resets the needs render flag.
    func didRender() {
        lock.withLock { state in
            state.needsRender = false
        }
    }
}

// MARK: - Render Notifier

/// Framework-internal registry that connects property wrappers to the active ``AppState``.
///
/// Property wrappers (`@State`, `@AppStorage`) use `RenderNotifier.current` to signal
/// re-renders when values change. `AppRunner` sets ``current`` once at startup before
/// entering the run loop.
///
/// Services like `StatusBarState` and `ThemeManager` receive ``AppState`` directly
/// via constructor injection. `RenderNotifier` exists specifically for property wrappers
/// which have no access to `RenderContext` or `TUIContext` at mutation time.
///
/// ```
/// AppRunner (owns AppState)
///     │
///     ├─► RenderNotifier.current = appState   (set once at startup)
///     │
///     ├─► @State<Value>.Storage.didSet
///     │       └─► RenderNotifier.current.setNeedsRender()
///     │
///     ├─► StatusBarState (injected via init)
///     │       └─► appState.setNeedsRender()
///     │
///     └─► ThemeManager (injected via init)
///             └─► appState.setNeedsRender()
/// ```
///
/// - Important: This type is framework-internal. User code should never access it directly.
enum RenderNotifier {
    /// The active ``AppState`` for the running application.
    ///
    /// This is a static accessor because `@State`, `@AppStorage`, and
    /// ``NotificationService`` need to trigger re-renders from contexts
    /// that have no access to `EnvironmentValues` — property wrapper
    /// setters, button callbacks, and `onSelect` handlers all run outside
    /// the render pipeline. A static reference is the only way to reach
    /// the render notifier from those call sites.
    ///
    /// - Precondition: Must be set before any `@State` mutation occurs.
    ///   This is guaranteed because `AppRunner.run()` sets it before
    ///   the first render pass.
    nonisolated(unsafe) static var current = AppState()

    /// The active render cache for subtree memoization.
    ///
    /// Set by `AppRunner` alongside ``current``. Cleared on every
    /// `@State` mutation to invalidate memoized subtrees.
    nonisolated(unsafe) static var renderCache: RenderCache?
}

// MARK: - Hydration Context

/// The active render context used by `@State` during self-hydration.
///
/// Set by ``renderToBuffer(_:context:)`` before evaluating a composite view's `body`,
/// and cleared immediately after. Provides the view identity and state storage
/// that `@State.init` needs to retrieve or create persistent state.
struct HydrationContext {
    /// The current view's structural identity.
    let identity: ViewIdentity

    /// The persistent state storage.
    let storage: StateStorage
}

// MARK: - State Registration

/// Framework-internal state for `@State` self-hydration during rendering.
///
/// When ``renderToBuffer(_:context:)`` is about to evaluate a composite view's `body`,
/// it sets ``activeContext`` and resets ``counter`` to 0. Each `@State.init` that runs
/// during `body` evaluation checks ``activeContext``:
///
/// - **Non-nil:** Claims the next property index from ``counter`` and retrieves a
///   persistent ``StateBox`` from ``StateStorage``.
/// - **Nil:** Creates a local ``StateBox`` (pre-render or outside the render tree).
///
/// This is safe because TUIKit runs on a single thread — no concurrent access.
enum StateRegistration {
    /// The active hydration context, set during composite view body evaluation.
    ///
    /// - Important: Must be set before and cleared after each `body` call.
    ///   Nested composite views save/restore the previous context.
    nonisolated(unsafe) static var activeContext: HydrationContext?

    /// The current property index, incremented by each `@State` during hydration.
    nonisolated(unsafe) static var counter: Int = 0
}

// MARK: - Binding

/// A two-way connection to a mutable value.
///
/// `Binding` provides read and write access to a value owned elsewhere.
/// Use bindings to connect interactive views to state.
///
/// # Example
///
/// ```swift
/// struct ContentView: View {
///     @State var selectedIndex = 0
///
///     var body: some View {
///         Menu(items: menuItems, selection: $selectedIndex)
///     }
/// }
/// ```
@propertyWrapper
public struct Binding<Value> {
    /// The getter for the value.
    private let getValue: () -> Value

    /// The setter for the value.
    private let setValue: (Value) -> Void

    /// The current value.
    public var wrappedValue: Value {
        get { getValue() }
        nonmutating set { setValue(newValue) }
    }

    /// The binding itself (for projectedValue access).
    public var projectedValue: Binding<Value> {
        self
    }

    /// Creates a binding with custom getter and setter.
    ///
    /// - Parameters:
    ///   - get: The getter closure.
    ///   - set: The setter closure.
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getValue = get
        self.setValue = set
    }

    /// Creates a constant binding that never changes.
    ///
    /// - Parameter value: The constant value.
    /// - Returns: A binding that always returns the given value.
    public static func constant(_ value: Value) -> Binding<Value> {
        Self(get: { value }, set: { _ in })
    }
}

// MARK: - State Property Wrapper

/// A property wrapper that stores mutable state for a view.
///
/// When the value changes, the view hierarchy is re-rendered.
/// Use `@State` for simple value types owned by a single view.
///
/// # Example
///
/// ```swift
/// struct CounterView: View {
///     @State var count = 0
///
///     var body: some View {
///         VStack {
///             Text("Count: \(count)")
///             // When count changes, view re-renders
///         }
///     }
/// }
/// ```
///
/// # Accessing the Binding
///
/// Use the `$` prefix to get a `Binding` to the state:
///
/// ```swift
/// Menu(selection: $selectedIndex)
/// ```
///
/// # Render Integration
///
/// `@State` uses **self-hydrating init**: when `@State.init` runs while a
/// render context is active (``StateRegistration/activeContext``), it claims
/// the next property index and retrieves (or creates) a persistent ``StateBox``
/// from ``StateStorage``.
///
/// The render loop sets the active context **before** evaluating `App.body`,
/// so views constructed inside `WindowGroup { ... }` closures self-hydrate
/// immediately. For nested composite views, ``renderToBuffer(_:context:)``
/// saves and restores the context around each `body` evaluation.
///
/// State is keyed by ``ViewIdentity`` and property index, ensuring values
/// survive view reconstruction across render passes.
///
/// Mutations signal re-renders through ``RenderNotifier``.
@propertyWrapper
public struct State<Value> {
    /// The backing storage box for this state value.
    ///
    /// Either a local box (when no render context is active) or a persistent
    /// box from ``StateStorage`` (during rendering). Since ``StateBox`` is a
    /// reference type, mutations through `nonmutating set` are visible everywhere.
    private let box: StateBox<Value>

    /// The default value provided at init time.
    ///
    /// Used by ``StateStorage`` to create a new entry when no persistent
    /// value exists for this property yet.
    let defaultValue: Value

    /// The current state value.
    public var wrappedValue: Value {
        get { box.value }
        nonmutating set { box.value = newValue }
    }

    /// A binding to the state value.
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.box.value },
            set: { self.box.value = $0 }
        )
    }

    /// Creates a state with an initial value.
    ///
    /// If a render context is active (``StateRegistration/activeContext``),
    /// the state self-hydrates: it claims a property index and retrieves
    /// or creates a persistent ``StateBox`` from ``StateStorage``.
    ///
    /// Otherwise, a local ``StateBox`` is created with the default value.
    ///
    /// - Parameter wrappedValue: The initial/default value.
    public init(wrappedValue: Value) {
        self.defaultValue = wrappedValue
        if let context = StateRegistration.activeContext {
            let index = StateRegistration.counter
            StateRegistration.counter += 1
            let key = StateStorage.StateKey(identity: context.identity, propertyIndex: index)
            self.box = context.storage.storage(for: key, default: wrappedValue)
        } else {
            self.box = StateBox(wrappedValue)
        }
    }
}
