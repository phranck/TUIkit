//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentProperty.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import TUIkitCore

// MARK: - Environment Property Wrapper

/// A property wrapper that reads a value from the environment.
///
/// Use `@Environment` to access environment values in your views.
/// The value is read dynamically during `body` evaluation, so it
/// always reflects the current environment (including any modifications
/// from parent views).
///
/// # KeyPath-Based Access
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
/// # Type-Based Access (Observable Objects)
///
/// ```swift
/// @Observable
/// class AppModel {
///     var count = 0
///     init() {}
/// }
///
/// struct ContentView: View {
///     @Environment(AppModel.self) var model
///
///     var body: some View {
///         Text("Count: \(model.count)")
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
    /// Strategy for resolving the environment value.
    private enum LookupStrategy {
        case keyPath(KeyPath<EnvironmentValues, Value>)
        case observable((EnvironmentValues) -> Value?)
    }

    /// The lookup strategy used by this instance.
    private let strategy: LookupStrategy

    /// Creates an environment property wrapper for the given key path.
    ///
    /// - Parameter keyPath: The key path to the environment value to read.
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.strategy = .keyPath(keyPath)
    }

    /// Creates an environment property wrapper that reads an observable
    /// object by its type.
    ///
    /// The object must have been injected via `.environment(model)`.
    ///
    /// ```swift
    /// @Environment(AppModel.self) var model
    /// ```
    ///
    /// - Parameter type: The observable type to look up.
    public init(_ type: Value.Type) where Value: Observable {
        self.strategy = .observable { env in
            env[observable: type]
        }
    }

    /// The current environment value.
    ///
    /// Reads from the active render environment if available,
    /// otherwise returns the default value.
    public var wrappedValue: Value {
        let env = StateRegistration.activeEnvironment ?? EnvironmentValues()
        switch strategy {
        case .keyPath(let keyPath):
            return env[keyPath: keyPath]
        case .observable(let lookup):
            guard let object = lookup(env) else {
                fatalError(
                    "@Environment(\(Value.self).self): "
                    + "No object of type \(Value.self) found in the environment. "
                    + "Did you forget to call .environment(model)?"
                )
            }
            return object
        }
    }
}
