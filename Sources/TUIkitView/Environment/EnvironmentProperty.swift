//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentProperty.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Environment Property Wrapper

/// A property wrapper that reads a value from the environment.
///
/// Use `@Environment` to access environment values in your views.
/// The value is read dynamically during `body` evaluation, so it
/// always reflects the current environment (including any modifications
/// from parent views).
///
/// # Example
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.palette) var palette
///     @Environment(\.isDisabled) var isDisabled
///
///     var body: some View {
///         Text("Hello")
///             .foregroundColor(palette.accent)
///     }
/// }
/// ```
///
/// # How It Works
///
/// The rendering pipeline sets ``StateRegistration/activeEnvironment``
/// before evaluating each view's `body`. When your code accesses
/// `wrappedValue`, it reads from the active environment. This ensures
/// that `.environment()` modifiers applied by parent views are visible.
///
/// Outside the render tree (e.g., in tests without a render context),
/// default values from `EnvironmentValues()` are returned.
@propertyWrapper
public struct Environment<Value> {
    /// The key path to the environment value.
    private let keyPath: KeyPath<EnvironmentValues, Value>

    /// Creates an environment property wrapper for the given key path.
    ///
    /// - Parameter keyPath: The key path to the environment value to read.
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }

    /// The current environment value.
    ///
    /// Reads from the active render environment if available,
    /// otherwise returns the default value.
    public var wrappedValue: Value {
        let env = StateRegistration.activeEnvironment ?? EnvironmentValues()
        return env[keyPath: keyPath]
    }
}
