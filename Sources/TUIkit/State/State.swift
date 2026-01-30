//
//  State.swift
//  TUIkit
//
//  State management for TUIkit views.
//

import Foundation

// MARK: - App State

/// Global application state that triggers re-renders when modified.
///
/// Since TUIkit runs in a single-threaded event loop, we use a simple
/// observable pattern. The AppRunner subscribes to state changes and
/// re-renders when notified.
///
/// `AppRunner` creates and assigns the active instance on startup.
/// Property wrappers like ``State`` and ``AppStorage`` access it
/// through ``active``.
public final class AppState: @unchecked Sendable {
    /// The active app state for the current application.
    ///
    /// Set by `AppRunner` during initialization. Property wrappers
    /// (`@State`, `@AppStorage`, `@SceneStorage`) and services
    /// (`StatusBarState`, `ThemeManager`) use this to trigger re-renders.
    public nonisolated(unsafe) static var active = AppState()

    /// Callbacks to invoke when state changes.
    private var observers: [() -> Void] = []

    /// Whether state has changed since last render.
    private(set) var needsRender = false

    /// Creates a new app state instance.
    public init() {}

    /// Registers an observer to be notified of state changes.
    ///
    /// - Parameter callback: The callback to invoke on state change.
    internal func observe(_ callback: @escaping () -> Void) {
        observers.append(callback)
    }

    /// Clears all observers.
    internal func clearObservers() {
        observers.removeAll()
    }

    /// Marks state as changed and notifies observers.
    public func setNeedsRender() {
        needsRender = true
        for observer in observers {
            observer()
        }
    }

    /// Resets the needs render flag.
    internal func didRender() {
        needsRender = false
    }
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
@propertyWrapper
public struct State<Value> {
    /// The storage for the state value.
    private final class Storage {
        var value: Value {
            didSet {
                AppState.active.setNeedsRender()
            }
        }

        init(_ value: Value) {
            self.value = value
        }
    }

    private let storage: Storage

    /// The current state value.
    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    /// A binding to the state value.
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.storage.value },
            set: { self.storage.value = $0 }
        )
    }

    /// Creates a state with an initial value.
    ///
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: Value) {
        self.storage = Storage(wrappedValue)
    }
}
