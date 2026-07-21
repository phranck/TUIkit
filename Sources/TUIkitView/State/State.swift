//  🖥️ TUIKit — Terminal UI Kit for Swift
//  State.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import TUIkitCore

// MARK: - App State

/// Application state that triggers re-renders when modified.
///
/// `AppState` is thread-safe: ``setNeedsRender()`` can be called from any thread.
/// Internal state is protected by an `NSLock`.
///
/// The `AppRunner` subscribes to state changes and re-renders when notified.
/// Property wrappers route changes to the runtime-owned instance through
/// ``RenderInvalidationSink``.
///
/// - Important: This is framework infrastructure. Prefer using ``State`` for reactive state
///   management in your views. Direct use of `AppState` is only necessary in advanced scenarios
///   where you manage state outside the view hierarchy.
public final class AppState: Sendable {
    /// Internal state protected by a lock.
    private struct StateData: Sendable {
        var needsRender = false
        var invalidatesAllCachedOutput = false
        var invalidatedSubtrees: Set<ViewIdentity> = []
        var observers: [@Sendable () -> Void] = []
        var traversalThreadID: ObjectIdentifier?
        var traversalViolationHandler: (@Sendable (RenderInvalidation) -> Void)?
    }

    /// Lock protecting all mutable state.
    private let lock = Lock(initialState: StateData())

    /// Creates a new app state instance.
    public init() {}
}

// MARK: - Public API

public extension AppState {
    /// Marks state as changed and notifies observers.
    ///
    /// This method is thread-safe and can be called from any thread.
    ///
    /// Callers that change visual output (theme, palette, appearance) do
    /// **not** need to manually clear the render cache. `RenderLoop`
    /// automatically detects environment changes via `EnvironmentSnapshot`
    /// comparison and clears the cache when needed.
    func setNeedsRender() {
        invalidate(.renderOnly)
    }

    /// Marks state as changed and requests a full cache clear on next render.
    ///
    /// Called by `withObservationTracking` when an `@Observable` property
    /// changes. Unlike ``setNeedsRender()``, this also sets a flag that tells
    /// the render loop to clear the entire render cache, ensuring cached
    /// `EquatableView` subtrees re-render with the new model data.
    ///
    /// Thread-safe: can be called from any thread.
    func setNeedsRenderWithCacheClear() {
        invalidate(.all)
    }
}

// MARK: - Internal API

extension AppState {
    /// Whether state has changed since last render.
    public var needsRender: Bool {
        lock.withLock { $0.needsRender }
    }

    /// Registers an observer to be notified of state changes.
    ///
    /// - Parameter callback: The callback to invoke on state change.
    public func observe(_ callback: @escaping @Sendable () -> Void) {
        lock.withLock { state in
            state.observers.append(callback)
        }
    }

    /// Clears all observers.
    public func clearObservers() {
        lock.withLock { state in
            state.observers.removeAll()
        }
    }

    /// Resets the needs render flag.
    public func didRender() {
        lock.withLock { state in
            state.needsRender = false
        }
    }

    /// Consumes pending cache invalidations.
    ///
    /// Called by the render loop at the start of each frame. Returns `true`
    /// The returned invalidations are applied by the owning runtime on the
    /// main actor before rendering. Render-only requests are represented by
    /// an empty array because they do not affect cached output.
    public func consumePendingCacheInvalidations() -> [RenderInvalidation] {
        lock.withLock { state in
            if state.invalidatesAllCachedOutput {
                state.invalidatesAllCachedOutput = false
                state.invalidatedSubtrees.removeAll(keepingCapacity: true)
                return [.all]
            }

            let invalidations = state.invalidatedSubtrees.map(RenderInvalidation.subtree)
            state.invalidatedSubtrees.removeAll(keepingCapacity: true)
            return invalidations
        }
    }

    /// Consumes pending invalidations and reports whether a full cache clear was requested.
    ///
    /// Prefer ``consumePendingCacheInvalidations()`` when subtree invalidations
    /// must be preserved.
    public func consumeNeedsCacheClear() -> Bool {
        consumePendingCacheInvalidations().contains { invalidation in
            if case .all = invalidation {
                return true
            }
            return false
        }
    }

    /// Clears render flags, pending invalidations, and observers.
    public func reset() {
        lock.withLock { state in
            state.needsRender = false
            state.invalidatesAllCachedOutput = false
            state.invalidatedSubtrees.removeAll()
            state.observers.removeAll()
            state.traversalThreadID = nil
        }
    }

    // MARK: - Traversal Diagnostics

    /// Marks the start of a view-tree traversal window.
    ///
    /// Between ``beginTraversal()`` and ``endTraversal()``, invalidations
    /// arriving **from the traversing thread itself** are unsupported user
    /// side effects (state mutated while a body evaluates or a view renders)
    /// and are reported through the traversal-violation handler.
    /// Invalidations from background tasks remain legitimate and stay
    /// silent, as do all invalidations outside the window (input handlers,
    /// committed effect actions, timers).
    ///
    /// The window is keyed to the calling thread's identity instead of
    /// `Thread.isMainThread`, which is not reliable under the Swift
    /// concurrency runtime on Linux.
    package func beginTraversal() {
        let threadID = ObjectIdentifier(Thread.current)
        lock.withLock { state in
            state.traversalThreadID = threadID
        }
    }

    /// Marks the end of a view-tree traversal window.
    package func endTraversal() {
        lock.withLock { state in
            state.traversalThreadID = nil
        }
    }

    /// Installs the handler that reports main-thread invalidations raised
    /// during a traversal window.
    ///
    /// Set once by the owning runtime (`TUIContext`), which routes the
    /// report into its diagnostics collector.
    ///
    /// - Parameter handler: The violation reporter, or `nil` to disable.
    package func setTraversalViolationHandler(
        _ handler: (@Sendable (RenderInvalidation) -> Void)?
    ) {
        lock.withLock { state in
            state.traversalViolationHandler = handler
        }
    }
}

// MARK: - Render Invalidation Sink

extension AppState: RenderInvalidationSink {
    public func invalidate(_ invalidation: RenderInvalidation) {
        let currentThreadID = ObjectIdentifier(Thread.current)

        let (observers, violationHandler) = lock.withLock { state -> ([@Sendable () -> Void], (@Sendable (RenderInvalidation) -> Void)?) in
            state.needsRender = true

            switch invalidation {
            case .renderOnly:
                break
            case .subtree(let identity):
                if !state.invalidatesAllCachedOutput {
                    state.invalidatedSubtrees.insert(identity)
                }
            case .all:
                state.invalidatesAllCachedOutput = true
                state.invalidatedSubtrees.removeAll(keepingCapacity: true)
            }

            let handler = (state.traversalThreadID == currentThreadID)
                ? state.traversalViolationHandler
                : nil
            return (state.observers, handler)
        }

        // Report and notify outside the lock to avoid potential deadlocks.
        // A main-thread invalidation inside a traversal window is an
        // unsupported user side effect; the invalidation itself is still
        // honored so rendering stays consistent.
        violationHandler?(invalidation)
        for observer in observers {
            observer()
        }
    }
}

// MARK: - Hydration Context

/// The render context used to bind dynamic properties to runtime storage.
///
/// Created by `renderToBuffer(_:context:)` after a view reaches its final
/// structural position and before evaluating that view's `body`.
public struct HydrationContext: Sendable {
    /// The current view's structural identity.
    public let identity: ViewIdentity

    /// The persistent state storage.
    public let storage: StateStorage

    /// The runtime that owns state created in this context.
    public let invalidationSink: (any RenderInvalidationSink)?

    /// Creates a new hydration context.
    public init(
        identity: ViewIdentity,
        storage: StateStorage,
        invalidationSink: (any RenderInvalidationSink)? = nil
    ) {
        self.identity = identity
        self.storage = storage
        self.invalidationSink = invalidationSink
    }
}

// MARK: - Runtime Dynamic Property

/// Internal binding contract for property wrappers that need their committed
/// view identity before `body` is evaluated.
package protocol RuntimeDynamicProperty {
    /// Binds the property to one stable slot on the final structural identity.
    func bind(to context: HydrationContext, propertyIndex: Int)
}

// MARK: - State Registration

/// Framework-internal context for dynamic-property and environment evaluation.
///
/// The renderer first reflects the owning view's dynamic properties and binds
/// them to its final structural identity. Ambient context remains available
/// while evaluating `body` for environment-backed construction APIs.
public enum StateRegistration {
    /// Dynamically scoped hydration context used by production rendering.
    @TaskLocal package static var runtimeContext: HydrationContext?

    /// Dynamically scoped environment used by production rendering.
    @TaskLocal package static var runtimeEnvironment: EnvironmentValues?

    /// Current dynamically scoped context.
    package static var currentContext: HydrationContext? {
        runtimeContext
    }

    /// Current dynamically scoped environment.
    package static var currentEnvironment: EnvironmentValues? {
        runtimeEnvironment
    }

    /// Evaluates a closure with a hydration context active.
    ///
    /// Installs task-local runtime context and environment values while
    /// calling the closure, then restores the enclosing scope. This pattern
    /// is needed whenever `view.body` is evaluated outside the normal
    /// `renderToBuffer` dispatch (e.g., in `measureChild`).
    ///
    /// - Parameters:
    ///   - context: The render context providing identity and environment.
    ///   - block: The closure to execute with hydration active.
    /// - Returns: The result of the closure.
    public static func withHydration<R>(
        context: RenderContext,
        _ block: () -> R
    ) -> R {
        withHydration(owner: nil, context: context, block)
    }

    /// Evaluates a view or app body after binding its dynamic properties to
    /// the final structural identity supplied by the renderer.
    package static func withHydration<Owner, R>(
        of owner: Owner,
        context: RenderContext,
        _ block: () -> R
    ) -> R {
        withHydration(owner: owner, context: context, block)
    }

    /// Binds direct dynamic-property fields for tests and specialized runtime paths.
    package static func bindDynamicProperties<Owner>(
        in owner: Owner,
        context: HydrationContext
    ) {
        var propertyIndex = 0
        var mirror: Mirror? = Mirror(reflecting: owner)

        while let currentMirror = mirror {
            for child in currentMirror.children {
                guard let property = child.value as? any RuntimeDynamicProperty else { continue }
                property.bind(to: context, propertyIndex: propertyIndex)
                propertyIndex += 1
            }
            mirror = currentMirror.superclassMirror
        }
    }

    private static func withHydration<R>(
        owner: Any?,
        context: RenderContext,
        _ block: () -> R
    ) -> R {
        let hydrationContext = context.environment.stateStorage.map {
            HydrationContext(
                identity: context.identity,
                storage: $0,
                invalidationSink: context.environment.renderInvalidationSink
            )
        }

        return $runtimeContext.withValue(hydrationContext) {
            $runtimeEnvironment.withValue(context.environment) {
                if let owner, let hydrationContext {
                    bindDynamicProperties(in: owner, context: hydrationContext)
                }
                return block()
            }
        }
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
///
/// # Render Integration
///
/// Immediately before a view's `body` is evaluated, the renderer binds each
/// `@State` property to a persistent `StateBox` using the view's final
/// structural identity and the property's declaration slot.
///
/// Binding after structural traversal prevents a child constructed in its
/// parent's body from claiming the parent's identity. State therefore survives
/// reconstruction while independent siblings retain independent storage.
///
/// Mutations signal re-renders through the owning runtime's invalidation sink.
@propertyWrapper
public struct State<Value> {
    /// Stable indirection that can adopt the box for the committed view identity.
    private let location: StateLocation<Value>

    /// The default value provided at init time.
    ///
    /// Used by `StateStorage` to create a new entry when no persistent
    /// value exists for this property yet.
    let defaultValue: Value

    /// The current state value.
    public var wrappedValue: Value {
        get { location.box.value }
        nonmutating set {
            location.box.value = newValue
        }
    }

    /// A binding to the state value.
    public var projectedValue: Binding<Value> {
        return Binding(
            get: { self.location.box.value },
            set: { self.location.box.value = $0 }
        )
    }

    /// Creates a state with an initial value.
    ///
    /// The wrapper starts with local storage. The renderer replaces that storage
    /// with the persistent box for the committed view identity before `body`
    /// evaluation.
    ///
    /// - Parameter wrappedValue: The initial/default value.
    public init(wrappedValue: Value) {
        self.defaultValue = wrappedValue
        self.location = StateLocation(defaultValue: wrappedValue)
    }
}

// MARK: - Runtime Binding

extension State: RuntimeDynamicProperty {
    package func bind(to context: HydrationContext, propertyIndex: Int) {
        location.bind(to: context, propertyIndex: propertyIndex)
    }
}

// MARK: - State Location

private final class StateLocation<Value> {
    let defaultValue: Value
    var box: StateBox<Value>
    private weak var storage: StateStorage?
    private var key: StateStorage.StateKey?

    init(defaultValue: Value) {
        self.defaultValue = defaultValue
        self.box = StateBox(defaultValue)
    }

    func bind(to context: HydrationContext, propertyIndex: Int) {
        let key = StateStorage.StateKey(
            identity: context.identity,
            propertyIndex: propertyIndex
        )

        if self.key != key || storage !== context.storage {
            box = context.storage.storage(for: key, default: defaultValue)
            storage = context.storage
            self.key = key
        }
        box.bind(identity: context.identity, invalidationSink: context.invalidationSink)
    }
}
