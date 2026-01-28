//
//  Preferences.swift
//  SwiftTUI
//
//  Preferences system for bottom-up data flow (child → parent).
//  Similar to SwiftUI's PreferenceKey system.
//

import Foundation

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

    /// Merges another set of preference values into this one.
    ///
    /// - Parameter other: The other preference values to merge.
    public mutating func merge(_ other: PreferenceValues) {
        for (key, value) in other.storage {
            storage[key] = value
        }
    }
}

// MARK: - Preference Storage

/// Thread-local storage for collecting preferences during rendering.
public final class PreferenceStorage: @unchecked Sendable {
    /// The shared preference storage.
    public static let shared = PreferenceStorage()

    /// Stack of preference values for nested rendering.
    private var stack: [PreferenceValues] = [PreferenceValues()]

    /// Callbacks registered to receive preference changes.
    private var callbacks: [ObjectIdentifier: [(Any) -> Void]] = [:]

    private init() {}

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

    /// Pushes a new preference context.
    public func push() {
        stack.append(PreferenceValues())
    }

    /// Pops the current preference context and merges into parent.
    public func pop() -> PreferenceValues {
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
    public func setValue<K: PreferenceKey>(_ value: K.Value, forKey key: K.Type) {
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
    public func onPreferenceChange<K: PreferenceKey>(
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

    /// Clears all callbacks.
    public func clearCallbacks() {
        callbacks.removeAll()
    }

    /// Resets all preference state.
    public func reset() {
        stack = [PreferenceValues()]
        callbacks.removeAll()
    }
}

// MARK: - Preference Modifier

/// A modifier that sets a preference value.
public struct PreferenceModifier<Content: TView, K: PreferenceKey>: TView {
    /// The content view.
    let content: Content

    /// The preference value to set.
    let value: K.Value

    public var body: Never {
        fatalError("PreferenceModifier renders via Renderable")
    }
}

extension PreferenceModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Set the preference value
        PreferenceStorage.shared.setValue(value, forKey: K.self)

        // Render content
        return SwiftTUI.renderToBuffer(content, context: context)
    }
}

// MARK: - OnPreferenceChange Modifier

/// A modifier that reacts to preference changes.
public struct OnPreferenceChangeModifier<Content: TView, K: PreferenceKey>: TView
where K.Value: Equatable {
    /// The content view.
    let content: Content

    /// The action to perform when the preference changes.
    let action: (K.Value) -> Void

    public var body: Never {
        fatalError("OnPreferenceChangeModifier renders via Renderable")
    }
}

extension OnPreferenceChangeModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Register callback for preference changes
        PreferenceStorage.shared.onPreferenceChange(K.self, callback: action)

        // Push a new preference context
        PreferenceStorage.shared.push()

        // Render content
        let buffer = SwiftTUI.renderToBuffer(content, context: context)

        // Pop and get collected preferences
        let preferences = PreferenceStorage.shared.pop()

        // Trigger action with current value
        action(preferences[K.self])

        return buffer
    }
}

// MARK: - TView Extension

extension TView {
    /// Sets a preference value for this view.
    ///
    /// Preferences propagate up the view hierarchy, allowing child views
    /// to communicate values to their ancestors.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Page Title")
    ///     .preference(key: NavigationTitleKey.self, value: "Home")
    /// ```
    ///
    /// - Parameters:
    ///   - key: The preference key type.
    ///   - value: The value to set.
    /// - Returns: A view that sets the preference.
    public func preference<K: PreferenceKey>(key: K.Type, value: K.Value) -> some TView {
        PreferenceModifier<Self, K>(content: self, value: value)
    }

    /// Adds an action to perform when a preference value changes.
    ///
    /// # Example
    ///
    /// ```swift
    /// NavigationView {
    ///     content
    /// }
    /// .onPreferenceChange(NavigationTitleKey.self) { title in
    ///     self.title = title
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The preference key type.
    ///   - action: The action to perform with the new value.
    /// - Returns: A view that reacts to preference changes.
    public func onPreferenceChange<K: PreferenceKey>(
        _ key: K.Type,
        perform action: @escaping (K.Value) -> Void
    ) -> some TView where K.Value: Equatable {
        OnPreferenceChangeModifier<Self, K>(content: self, action: action)
    }
}

// MARK: - Common Preference Keys

/// A preference key for the navigation title.
public struct NavigationTitleKey: PreferenceKey {
    public static let defaultValue: String = ""
}

/// A preference key for tab bar badge values.
public struct TabBadgeKey: PreferenceKey {
    public static let defaultValue: [Int: String] = [:]

    public static func reduce(value: inout [Int: String], nextValue: () -> [Int: String]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// A preference key for anchor positions (useful for scroll targets).
public struct AnchorPreferenceKey: PreferenceKey {
    public static let defaultValue: [String: Int] = [:]

    public static func reduce(value: inout [String: Int], nextValue: () -> [String: Int]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Convenience Extensions

extension TView {
    /// Sets the navigation title for this view.
    ///
    /// # Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("Content")
    /// }
    /// .navigationTitle("Home")
    /// ```
    ///
    /// - Parameter title: The navigation title.
    /// - Returns: A view with the navigation title preference set.
    public func navigationTitle(_ title: String) -> some TView {
        preference(key: NavigationTitleKey.self, value: title)
    }
}
