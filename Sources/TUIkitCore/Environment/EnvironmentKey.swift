//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentKey.swift
//
//  Created by LAYERED.work
//  License: MIT

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
