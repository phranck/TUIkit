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

// MARK: - Environment Property Wrapper

/// A property wrapper that reads a value from the environment.
///
/// - Important: Deprecated. Use `context.environment` in ``Renderable/renderToBuffer(context:)``
///   instead. The `@Environment` wrapper relied on a global singleton that has been removed.
///   Environment values now flow exclusively through ``RenderContext``.
@available(*, deprecated, message: "Use context.environment in renderToBuffer(context:) instead")
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

    /// Returns the default value for the key — the backing singleton has been removed.
    public var wrappedValue: Value {
        EnvironmentValues()[keyPath: keyPath]
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
        // Create modified environment and render content with it.
        // The modified context carries the environment through the render tree —
        // no singleton sync needed.
        let modifiedEnvironment = context.environment.setting(keyPath, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}
