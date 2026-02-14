//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PreferenceKey.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Preference Key Protocol

/// A key for defining preference values that propagate up the view hierarchy.
///
/// Unlike Environment (which flows top-down), Preferences flow bottom-up
/// from child views to parent views.
///
/// # Example
///
/// ```swift
/// struct NavigationTitleKey: PreferenceKey {
///     static var defaultValue: String = ""
///
///     static func reduce(value: inout String, nextValue: () -> String) {
///         value = nextValue()
///     }
/// }
///
/// extension PreferenceValues {
///     var navigationTitle: String {
///         get { self[NavigationTitleKey.self] }
///         set { self[NavigationTitleKey.self] = newValue }
///     }
/// }
/// ```
public protocol PreferenceKey {
    /// The type of value for this preference.
    associatedtype Value

    /// The default value when no preference is set.
    static var defaultValue: Value { get }

    /// Combines a sequence of values into a single value.
    ///
    /// This is called when multiple children set the same preference.
    /// The default implementation uses the last value.
    ///
    /// - Parameters:
    ///   - value: The current accumulated value.
    ///   - nextValue: A closure that returns the next value to combine.
    static func reduce(value: inout Value, nextValue: () -> Value)
}

// Default implementation: use the last value
extension PreferenceKey {
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

// MARK: - Preference Values

/// A collection of preference values propagated up the view hierarchy.
public struct PreferenceValues: @unchecked Sendable {
    /// Storage for preference values.
    private var storage: [ObjectIdentifier: Any] = [:]

    /// Creates empty preference values.
    public init() {}

    /// Accesses the preference value for the given key.
    public subscript<K: PreferenceKey>(key: K.Type) -> K.Value {
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
}

// MARK: - Public API

public extension PreferenceValues {
    /// Merges another set of preference values into this one.
    ///
    /// - Parameter other: The other preference values to merge.
    mutating func merge(_ other: Self) {
        for (key, value) in other.storage {
            storage[key] = value
        }
    }
}

// MARK: - Preference Storage

/// Thread-local storage for collecting preferences during rendering.
public final class PreferenceStorage: @unchecked Sendable {
    /// Stack of preference values for nested rendering.
    private var stack: [PreferenceValues] = [PreferenceValues()]

    /// Callbacks registered to receive preference changes.
    private var callbacks: [ObjectIdentifier: [(Any) -> Void]] = [:]

    /// Creates a new preference storage.
    public init() {}

    /// The current preference values.
    public var current: PreferenceValues {
        get { stack.last ?? PreferenceValues() }
        set {
            if stack.isEmpty {
                stack.append(newValue)
            } else {
                stack[stack.count - 1] = newValue
            }
        }
    }
}

// MARK: - Public API

public extension PreferenceStorage {
    /// Pushes a new preference context.
    func push() {
        stack.append(PreferenceValues())
    }

    /// Pops the current preference context and merges into parent.
    func pop() -> PreferenceValues {
        guard stack.count > 1 else {
            return stack.last ?? PreferenceValues()
        }

        let popped = stack.removeLast()

        // Merge into parent
        if !stack.isEmpty {
            stack[stack.count - 1].merge(popped)
        }

        return popped
    }

    /// Sets a preference value.
    func setValue<K: PreferenceKey>(_ value: K.Value, forKey key: K.Type) {
        var currentValues = current
        K.reduce(value: &currentValues[key]) { value }
        current = currentValues

        // Notify callbacks
        let keyId = ObjectIdentifier(key)
        if let keyCallbacks = callbacks[keyId] {
            for callback in keyCallbacks {
                callback(value)
            }
        }
    }

    /// Registers a callback for preference changes.
    func onPreferenceChange<K: PreferenceKey>(
        _ key: K.Type,
        callback: @escaping (K.Value) -> Void
    ) {
        let keyId = ObjectIdentifier(key)
        let wrappedCallback: (Any) -> Void = { value in
            if let typedValue = value as? K.Value {
                callback(typedValue)
            }
        }

        if callbacks[keyId] == nil {
            callbacks[keyId] = []
        }
        callbacks[keyId]?.append(wrappedCallback)
    }

    /// Prepares preference storage for a new render pass.
    ///
    /// Clears all accumulated callbacks and resets the value stack
    /// to a single empty context. Called at the start of each frame
    /// by `RenderLoop.render()` to prevent callback accumulation.
    func beginRenderPass() {
        callbacks.removeAll()
        stack = [PreferenceValues()]
    }

    /// Resets all preference state.
    ///
    /// Called once during app shutdown by `TUIContext.reset()`.
    func reset() {
        stack = [PreferenceValues()]
        callbacks.removeAll()
    }
}
