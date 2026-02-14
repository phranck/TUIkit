//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Preferences.swift
//
//  Created by LAYERED.work
//  License: MIT  Similar to SwiftUI's PreferenceKey system.
//


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
    init() {}

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

// MARK: - Internal API

extension PreferenceValues {
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
final class PreferenceStorage: @unchecked Sendable {
    /// Stack of preference values for nested rendering.
    private var stack: [PreferenceValues] = [PreferenceValues()]

    /// Callbacks registered to receive preference changes.
    private var callbacks: [ObjectIdentifier: [(Any) -> Void]] = [:]

    /// Creates a new preference storage.
    init() {}

    /// The current preference values.
    var current: PreferenceValues {
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

// MARK: - Internal API

extension PreferenceStorage {
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

// MARK: - Preference Modifier

/// A modifier that sets a preference value.
struct PreferenceModifier<Content: View, K: PreferenceKey>: View {
    /// The content view.
    let content: Content

    /// The preference value to set.
    let value: K.Value

    var body: Never {
        fatalError("PreferenceModifier renders via Renderable")
    }
}

extension PreferenceModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Set the preference value
        context.tuiContext.preferences.setValue(value, forKey: K.self)

        // Render content
        return TUIkit.renderToBuffer(content, context: context)
    }
}

// MARK: - OnPreferenceChange Modifier

/// A modifier that reacts to preference changes.
struct OnPreferenceChangeModifier<Content: View, K: PreferenceKey>: View
where K.Value: Equatable {
    /// The content view.
    let content: Content

    /// The action to perform when the preference changes.
    let action: (K.Value) -> Void

    var body: Never {
        fatalError("OnPreferenceChangeModifier renders via Renderable")
    }
}

extension OnPreferenceChangeModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let prefs = context.tuiContext.preferences

        // Register callback for preference changes
        prefs.onPreferenceChange(K.self, callback: action)

        // Push a new preference context
        prefs.push()

        // Render content
        let buffer = TUIkit.renderToBuffer(content, context: context)

        // Pop and get collected preferences
        let preferences = prefs.pop()

        // Trigger action with current value
        action(preferences[K.self])

        return buffer
    }
}

// MARK: - Common Preference Keys

/// A preference key for the navigation title.
public struct NavigationTitleKey: PreferenceKey {
    /// The default navigation title (empty string).
    public static let defaultValue: String = ""
}
