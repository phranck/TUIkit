//
//  Environment.swift
//  SwiftTUI
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
    public func setting<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, to value: V) -> EnvironmentValues {
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
public final class EnvironmentStorage: @unchecked Sendable {
    /// The shared environment storage.
    public static let shared = EnvironmentStorage()

    /// The current environment values.
    private var current: EnvironmentValues = EnvironmentValues()

    /// Stack of environments for nested rendering.
    private var stack: [EnvironmentValues] = []

    private init() {}

    /// The current environment values.
    public var environment: EnvironmentValues {
        get { current }
        set { current = newValue }
    }

    /// Pushes a new environment onto the stack.
    ///
    /// - Parameter environment: The environment to push.
    public func push(_ environment: EnvironmentValues) {
        stack.append(current)
        current = environment
    }

    /// Pops the current environment and restores the previous one.
    public func pop() {
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
/// struct MyView: TView {
///     @Environment(\.statusBar) var statusBar
///
///     var body: some TView {
///         Button("Add Item") {
///             statusBar.push(context: "action") {
///                 TStatusBarItem(shortcut: "⎋", label: "cancel")
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
        EnvironmentStorage.shared.environment[keyPath: keyPath]
    }
}

// MARK: - Environment Modifier

/// A modifier that injects a value into the environment for child views.
public struct EnvironmentModifier<Content: TView, V>: TView {
    /// The content view.
    let content: Content

    /// The key path to modify.
    let keyPath: WritableKeyPath<EnvironmentValues, V>

    /// The value to inject.
    let value: V

    public var body: some TView {
        content
    }
}

extension EnvironmentModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Create modified environment
        let modifiedEnvironment = context.environment.setting(keyPath, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)

        // Render content with modified environment
        return EnvironmentStorage.shared.withEnvironment(modifiedEnvironment) {
            renderView(content, context: modifiedContext)
        }
    }
}

// MARK: - Internal Rendering Helper

/// Internal helper to render a view (avoids name collision with Renderable.renderToBuffer).
private func renderView<V: TView>(_ view: V, context: RenderContext) -> FrameBuffer {
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    if V.Body.self != Never.self {
        return renderView(view.body, context: context)
    }

    return FrameBuffer()
}

// MARK: - View Extension for Environment

extension TView {
    /// Sets an environment value for this view and its children.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the environment value.
    ///   - value: The value to set.
    /// - Returns: A view with the modified environment.
    public func environment<V>(
        _ keyPath: WritableKeyPath<EnvironmentValues, V>,
        _ value: V
    ) -> some TView {
        EnvironmentModifier(content: self, keyPath: keyPath, value: value)
    }
}
