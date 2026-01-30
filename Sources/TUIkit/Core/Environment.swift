//
//  Environment.swift
//  TUIkit
//
//  Environment system for passing values down the view hierarchy.
//  Similar to SwiftUI's @Environment property wrapper.
//

import Foundation

// MARK: - Environment Key Protocol

/// A key for accessing values in the environment.
///
/// Conform to this protocol to define custom environment values.
///
/// # Example
///
/// ```swift
/// struct MyCustomKey: EnvironmentKey {
///     static var defaultValue: String = "default"
/// }
///
/// extension EnvironmentValues {
///     var myCustomValue: String {
///         get { self[MyCustomKey.self] }
///         set { self[MyCustomKey.self] = newValue }
///     }
/// }
/// ```
public protocol EnvironmentKey {
    /// The type of value stored by this key.
    associatedtype Value

    /// The default value for this key.
    static var defaultValue: Value { get }
}

// MARK: - Environment Values

/// A collection of environment values propagated through the view hierarchy.
///
/// Environment values flow down from parent views to child views.
/// Each view can read environment values and optionally override them
/// for its children.
public struct EnvironmentValues: @unchecked Sendable {
    /// Storage for environment values.
    private var storage: [ObjectIdentifier: Any] = [:]

    /// Creates an empty environment values container.
    public init() {}

    /// Accesses the environment value for the given key.
    ///
    /// - Parameter key: The type of the environment key.
    /// - Returns: The value for the key, or its default value if not set.
    public subscript<K: EnvironmentKey>(key: K.Type) -> K.Value {
        get {
            if let value = storage[ObjectIdentifier(key)] as? K.Value {
                return value
            }
            return K.defaultValue
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    /// Creates a copy of this environment with a modified value.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the value to modify.
    ///   - value: The new value.
    /// - Returns: A new EnvironmentValues with the modified value.
    public func setting<V>(_ keyPath: WritableKeyPath<Self, V>, to value: V) -> Self {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
}

// MARK: - Current Environment

/// Thread-local storage for the current environment during rendering.
///
/// This allows views to access environment values without explicit passing.
/// The environment is set by the rendering system before rendering each view.
///
/// `AppRunner` creates and manages the active instance. Property wrappers
/// like ``Environment`` and view modifiers like ``EnvironmentModifier``
/// access it through ``active``.
public final class EnvironmentStorage: @unchecked Sendable {
    /// The active environment storage for the current application.
    ///
    /// Set by `AppRunner` during initialization. The ``Environment``
    /// property wrapper, ``FocusState``, and ``EnvironmentModifier``
    /// all read and write through this property.
    public nonisolated(unsafe) static var active = EnvironmentStorage()

    /// Lock protecting all mutable state.
    private let lock = NSLock()

    /// The current environment values.
    private var current = EnvironmentValues()

    /// Stack of environments for nested rendering.
    private var stack: [EnvironmentValues] = []

    /// Creates a new environment storage instance.
    public init() {}

    /// The current environment values.
    public var environment: EnvironmentValues {
        get {
            lock.lock()
            defer { lock.unlock() }
            return current
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            current = newValue
        }
    }

    /// Pushes a new environment onto the stack.
    ///
    /// - Parameter environment: The environment to push.
    public func push(_ environment: EnvironmentValues) {
        lock.lock()
        defer { lock.unlock() }
        stack.append(current)
        current = environment
    }

    /// Pops the current environment and restores the previous one.
    public func pop() {
        lock.lock()
        defer { lock.unlock() }
        if let previous = stack.popLast() {
            current = previous
        }
    }

    /// Executes a closure with the given environment.
    ///
    /// - Parameters:
    ///   - environment: The environment to use.
    ///   - body: The closure to execute.
    /// - Returns: The result of the closure.
    public func withEnvironment<T>(_ environment: EnvironmentValues, _ body: () -> T) -> T {
        push(environment)
        defer { pop() }
        return body()
    }

    /// Resets the environment to its initial state.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        current = EnvironmentValues()
        stack.removeAll()
    }
}

// MARK: - Environment Property Wrapper

/// A property wrapper that reads a value from the environment.
///
/// Use this property wrapper to access environment values in your views.
///
/// # Example
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.statusBar) var statusBar
///
///     var body: some View {
///         Button("Add Item") {
///             statusBar.push(context: "action") {
///                 StatusBarItem(shortcut: "⎋", label: "cancel")
///             }
///         }
///     }
/// }
/// ```
@propertyWrapper
public struct Environment<Value>: @unchecked Sendable {
    /// The key path to the environment value.
    private let keyPath: KeyPath<EnvironmentValues, Value>

    /// Creates an environment property wrapper.
    ///
    /// - Parameter keyPath: The key path to the environment value.
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }

    /// The current value from the environment.
    public var wrappedValue: Value {
        EnvironmentStorage.active.environment[keyPath: keyPath]
    }
}

// MARK: - Environment Modifier

/// A modifier that injects a value into the environment for child views.
///
/// `EnvironmentModifier` conforms to both `View` and ``Renderable``.
/// Because ``renderToBuffer(_:context:)`` checks `Renderable` first,
/// the `body` property below is **never called during rendering**.
/// It exists only to satisfy the `View` protocol requirement.
/// All actual work happens in `renderToBuffer(context:)`.
public struct EnvironmentModifier<Content: View, V>: View {
    /// The content view.
    let content: Content

    /// The key path to modify.
    let keyPath: WritableKeyPath<EnvironmentValues, V>

    /// The value to inject.
    let value: V

    /// Not used during rendering — ``Renderable`` conformance takes priority.
    public var body: some View {
        content
    }
}

extension EnvironmentModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Create modified environment
        let modifiedEnvironment = context.environment.setting(keyPath, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)

        // Render content with modified environment
        return EnvironmentStorage.active.withEnvironment(modifiedEnvironment) {
            TUIkit.renderToBuffer(content, context: modifiedContext)
        }
    }
}
