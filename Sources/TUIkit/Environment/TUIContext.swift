//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TUIContext.swift
//
//  Created by LAYERED.work
//  License: MIT  Owned by AppRunner and threaded through RenderContext.
//

import Foundation

// MARK: - Lifecycle Manager

/// Manages view lifecycle tracking, disappear callbacks, and async tasks.
///
/// Bundles lifecycle tracking, disappear callbacks, and async task management
/// into a single cohesive manager.
/// All mutable state is protected by `NSLock`.
final class LifecycleManager: @unchecked Sendable {
    /// A stable key for one lifecycle or task slot.
    private struct Slot: Hashable, Sendable {
        let value: String

        init(identity: ViewIdentity) {
            self.value = "identity:\(identity.path)"
        }
    }

    /// Type-erased task restart identity.
    private struct TaskID: Equatable, @unchecked Sendable {
        let value: AnyHashable
    }

    /// Mounted task and the value controlling its restart behavior.
    private struct TaskRecord: @unchecked Sendable {
        let id: TaskID?
        let task: Task<Void, Never>
    }

    /// Lock protecting all mutable state.
    private let lock = NSLock()

    // MARK: - Lifecycle Tracking

    /// Set of lifecycle slots that have appeared.
    private var appearedSlots: Set<Slot> = []

    /// Set of lifecycle slots that are currently visible.
    private var visibleSlots: Set<Slot> = []

    /// Lifecycle slots seen during the current render pass.
    private var currentRenderSlots: Set<Slot> = []

    // MARK: - Disappear Callbacks

    /// Callbacks registered for view disappearance.
    private var disappearCallbacks: [Slot: () -> Void] = [:]

    // MARK: - Task Storage

    /// Mounted async tasks keyed by structural lifecycle slot.
    private var tasks: [Slot: TaskRecord] = [:]

    // MARK: - Init

    /// Creates a new lifecycle manager.
    init() {}
}

// MARK: - Internal API

extension LifecycleManager {
    /// Marks the start of a new render pass.
    func beginRenderPass() {
        lock.lock()
        defer { lock.unlock() }
        currentRenderSlots.removeAll(keepingCapacity: true)
    }

    /// Marks the end of a render pass and triggers onDisappear for views that are no longer visible.
    func endRenderPass() {
        lock.lock()
        let disappeared = visibleSlots.subtracting(currentRenderSlots).sorted {
            $0.value < $1.value
        }
        for slot in disappeared {
            appearedSlots.remove(slot)
        }
        visibleSlots = currentRenderSlots
        let callbacks = disappeared.compactMap { disappearCallbacks.removeValue(forKey: $0) }
        let removedTasks = disappeared.compactMap { tasks.removeValue(forKey: $0)?.task }
        lock.unlock()

        // Cancellation and callbacks run outside the lock to avoid deadlocks.
        for task in removedTasks {
            task.cancel()
        }
        for callback in callbacks {
            callback()
        }
    }

    /// Records an appearance for a structurally derived runtime slot.
    ///
    /// - Parameters:
    ///   - identity: The runtime slot's structural identity.
    ///   - action: The onAppear action to execute.
    /// - Returns: True if this is the first appearance (action was executed).
    @discardableResult
    func recordAppear(identity: ViewIdentity, action: () -> Void) -> Bool {
        recordAppear(slot: Slot(identity: identity), action: action)
    }

    private func recordAppear(slot: Slot, action: () -> Void) -> Bool {
        lock.lock()
        currentRenderSlots.insert(slot)

        if !appearedSlots.contains(slot) {
            appearedSlots.insert(slot)
            lock.unlock()
            action()
            return true
        }
        lock.unlock()
        return false
    }

    /// Checks whether a structural runtime slot has appeared.
    func hasAppeared(identity: ViewIdentity) -> Bool {
        hasAppeared(slot: Slot(identity: identity))
    }

    private func hasAppeared(slot: Slot) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return appearedSlots.contains(slot)
    }

    /// Resets appearance state for a structural runtime slot so the next
    /// `recordAppear` treats it as a fresh first appearance.
    func resetAppearance(identity: ViewIdentity) {
        resetAppearance(slot: Slot(identity: identity))
    }

    private func resetAppearance(slot: Slot) {
        lock.lock()
        appearedSlots.remove(slot)
        lock.unlock()
    }

    /// Registers a callback for when a structurally derived runtime slot
    /// disappears.
    ///
    /// - Parameters:
    ///   - identity: The runtime slot's structural identity.
    ///   - action: The onDisappear action to execute.
    func registerDisappear(identity: ViewIdentity, action: @escaping () -> Void) {
        registerDisappear(slot: Slot(identity: identity), action: action)
    }

    private func registerDisappear(slot: Slot, action: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        disappearCallbacks[slot] = action
    }

    /// Unregisters a callback for a structurally derived runtime slot.
    func unregisterDisappear(identity: ViewIdentity) {
        unregisterDisappear(slot: Slot(identity: identity))
    }

    private func unregisterDisappear(slot: Slot) {
        lock.lock()
        defer { lock.unlock() }
        disappearCallbacks.removeValue(forKey: slot)
    }

    /// Starts or preserves a task at a structural slot.
    ///
    /// The task remains mounted across unchanged render passes. A changed ID
    /// cancels the existing task and starts exactly one replacement.
    @discardableResult
    func updateTask<ID: Hashable>(
        identity: ViewIdentity,
        id: ID,
        priority: TaskPriority,
        @_inheritActorContext operation: @escaping @isolated(any) @Sendable () async -> Void
    ) -> Bool {
        let slot = Slot(identity: identity)
        let taskID = TaskID(value: AnyHashable(id))

        lock.lock()
        currentRenderSlots.insert(slot)
        if tasks[slot]?.id == taskID {
            lock.unlock()
            return false
        }

        let previousTask = tasks.removeValue(forKey: slot)?.task
        previousTask?.cancel()
        let task = Task(priority: priority) {
            await operation()
        }
        tasks[slot] = TaskRecord(id: taskID, task: task)
        lock.unlock()

        return true
    }

    /// Cancels and removes a task at a structural runtime slot.
    func cancelTask(identity: ViewIdentity) {
        cancelTask(slot: Slot(identity: identity))
    }

    private func cancelTask(slot: Slot) {
        lock.lock()
        let task = tasks.removeValue(forKey: slot)?.task
        lock.unlock()
        task?.cancel()
    }

    /// Number of retained disappearance callbacks for tests and diagnostics.
    var disappearCallbackCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return disappearCallbacks.count
    }

    /// Number of retained mounted task records for tests and diagnostics.
    var taskCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return tasks.count
    }

    /// Resets all lifecycle state.
    ///
    /// Cancels all running tasks, clears all callbacks and tracking state.
    func reset() {
        lock.lock()
        appearedSlots.removeAll()
        visibleSlots.removeAll()
        currentRenderSlots.removeAll()
        disappearCallbacks.removeAll()
        let runningTasks = tasks.values.map(\.task)
        tasks.removeAll()
        lock.unlock()

        for task in runningTasks {
            task.cancel()
        }
    }
}

// MARK: - TUI Context

/// Central dependency container for TUIkit runtime services.
///
/// `TUIContext` bundles all framework-internal services into a single
/// object owned by `AppRunner`. It is threaded through `RenderContext`
/// so that view modifiers can access services during rendering.
///
/// ## Services
///
/// - ``lifecycle``: View lifecycle tracking (appear/disappear/task)
/// - ``keyEventDispatcher``: Key event handler registration and dispatch
/// - ``preferences``: Preference value collection during rendering
/// - ``stateStorage``: Persistent `@State` value storage indexed by view identity
///
/// ## Usage
///
/// View modifiers access services through `RenderContext.environment`:
///
/// ```swift
/// extension MyModifier: Renderable {
///     func renderToBuffer(context: RenderContext) -> FrameBuffer {
///         context.environment.keyEventDispatcher!.addHandler { event in
///             // handle key
///         }
///         return TUIkit.renderToBuffer(content, context: context)
///     }
/// }
/// ```
@MainActor
final class TUIContext {

    /// Thread-safe render state and invalidation sink owned by this runtime.
    let appState: AppState

    /// View lifecycle tracking (appear, disappear, task management).
    let lifecycle: LifecycleManager

    /// Key event handler registration and dispatch.
    let keyEventDispatcher: KeyEventDispatcher

    /// Preference value collection during rendering.
    let preferences: PreferenceStorage

    /// Diagnostics emitted while traversing this runtime's view tree.
    let runtimeDiagnostics: RuntimeDiagnostics

    /// Persistent `@State` value storage indexed by `ViewIdentity`.
    let stateStorage: StateStorage

    /// Identity-bound Observation registrations for this runtime.
    let observationRegistry: ObservationRegistry

    /// Cache for memoized subtree rendering results.
    ///
    /// Stores rendered ``FrameBuffer`` output for ``EquatableView`` instances,
    /// keyed by `ViewIdentity`. Cleared on every `@State` change; entries
    /// for removed views are garbage-collected at the end of each render pass.
    let renderCache: RenderCache

    /// Localization state owned by this runtime.
    let localizationService: LocalizationService

    /// Notification queue owned by this runtime.
    let notificationService: NotificationService

    /// Persistent application storage owned by this runtime.
    let storageBackend: StorageBackend

    /// Clock used by time-based views and services.
    let clock: RuntimeClock

    /// Keyboard focus state owned by this runtime.
    let focusManager: FocusManager

    /// Color palette selection owned by this runtime.
    let paletteManager: ThemeManager

    /// Border appearance selection owned by this runtime.
    let appearanceManager: ThemeManager

    /// Status bar state owned by this runtime.
    let statusBar: StatusBarState

    /// Application header state owned by this runtime.
    let appHeader: AppHeaderState

    /// Image loader used by this runtime.
    let imageLoader: any ImageLoader

    /// URL image cache owned by this runtime.
    let imageCache: URLImageCache

    /// Creates a new isolated TUI context with injectable services.
    ///
    /// Every omitted service is created fresh, so contexts do not share state,
    /// caches, or service instances. Tests can inject deterministic substitutes.
    ///
    /// - Parameters:
    ///   - appState: The render state and invalidation sink to use.
    ///   - lifecycle: The lifecycle manager to use.
    ///   - keyEventDispatcher: The key event dispatcher to use.
    ///   - preferences: The preference storage to use.
    ///   - runtimeDiagnostics: The diagnostic collector to use.
    ///   - stateStorage: The state storage to use.
    ///   - observationRegistry: The Observation registry to use.
    ///   - renderCache: The render cache to use.
    ///   - storageBackend: The AppStorage backend to use.
    ///   - localizationService: Optional localization service to adopt.
    ///   - notificationService: Optional notification service to adopt.
    ///   - clock: Clock used by time-based services.
    ///   - focusManager: Focus state to use.
    ///   - appHeader: Application header state to use.
    ///   - imageLoader: Loader for file and URL image requests.
    ///   - imageCache: Cache for URL image results.
    nonisolated init(
        appState: AppState = AppState(),
        lifecycle: LifecycleManager = LifecycleManager(),
        keyEventDispatcher: KeyEventDispatcher = KeyEventDispatcher(),
        preferences: PreferenceStorage = PreferenceStorage(),
        runtimeDiagnostics: RuntimeDiagnostics = RuntimeDiagnostics(),
        stateStorage: StateStorage = StateStorage(),
        observationRegistry: ObservationRegistry = ObservationRegistry(),
        renderCache: RenderCache = RenderCache(),
        storageBackend: StorageBackend = VolatileStorageBackend(),
        localizationService: LocalizationService? = nil,
        notificationService: NotificationService? = nil,
        clock: RuntimeClock = .system,
        focusManager: FocusManager = FocusManager(),
        appHeader: AppHeaderState = AppHeaderState(),
        imageLoader: any ImageLoader = PlatformImageLoader(),
        imageCache: URLImageCache = URLImageCache()
    ) {
        let localizationService = localizationService ?? LocalizationService.transient()
        let notificationService = notificationService ?? NotificationService()

        localizationService.setInvalidationSink(appState)
        notificationService.setRuntimeDependencies(
            clock: clock,
            invalidationSink: appState
        )
        stateStorage.setInvalidationSink(appState)
        let existingFocusChangeHandler = focusManager.onFocusChange
        focusManager.onFocusChange = { [appState] in
            existingFocusChangeHandler?()
            appState.setNeedsRender()
        }

        self.appState = appState
        self.lifecycle = lifecycle
        self.keyEventDispatcher = keyEventDispatcher
        self.preferences = preferences
        self.runtimeDiagnostics = runtimeDiagnostics
        self.stateStorage = stateStorage
        self.observationRegistry = observationRegistry
        self.renderCache = renderCache
        self.localizationService = localizationService
        self.notificationService = notificationService
        self.storageBackend = storageBackend
        self.clock = clock
        self.focusManager = focusManager
        self.paletteManager = ThemeManager(
            items: PaletteRegistry.all,
            renderTrigger: { [appState] in appState.setNeedsRender() }
        )
        self.appearanceManager = ThemeManager(
            items: AppearanceRegistry.all,
            renderTrigger: { [appState] in appState.setNeedsRender() }
        )
        self.statusBar = StatusBarState(appState: appState)
        self.appHeader = appHeader
        self.imageLoader = imageLoader
        self.imageCache = imageCache
    }
}

// MARK: - Internal API

extension TUIContext {
    /// Creates a runtime backed by the user's persistent configuration.
    static func production() -> TUIContext {
        TUIContext(
            runtimeDiagnostics: .standardError(),
            storageBackend: StorageDefaults.runtimeBackend,
            localizationService: LocalizationService()
        )
    }

    /// Starts a complete view render pass for this runtime.
    func beginRenderPass() {
        keyEventDispatcher.clearHandlers()
        preferences.beginRenderPass()
        runtimeDiagnostics.beginRenderPass()
        focusManager.beginRenderPass()
        statusBar.clearSectionItems()
        appHeader.beginRenderPass()
        statusBar.focusManager = focusManager
        lifecycle.beginRenderPass()
        stateStorage.beginRenderPass()
        observationRegistry.beginRenderPass()
        renderCache.beginRenderPass()
        applyPendingRenderInvalidations()
    }

    /// Finishes lifecycle, state, and cache tracking for a render pass.
    func endRenderPass() {
        lifecycle.endRenderPass()
        stateStorage.endRenderPass()
        observationRegistry.endRenderPass()
        renderCache.removeInactive()
        renderCache.logFrameStats()
    }

    /// Applies the committed frame's GC liveness to the identity-based
    /// managers.
    ///
    /// This is commit step "6d preparation" of the frame choreography: the
    /// FINAL pass's liveness sets (collected in ``PendingFrameEffects``)
    /// mark state, cache, and observation records alive, so the subsequent
    /// ``endRenderPass()`` sweeps everything that only discarded passes
    /// touched. Runs after the deferred-effect replay, which may add its own
    /// direct markings (e.g. preference change tracking).
    ///
    /// - Parameter pendingEffects: The final pass's pending records.
    func applyFrameLiveness(from pendingEffects: PendingFrameEffects) {
        for identity in pendingEffects.activeIdentities {
            stateStorage.markActive(identity)
            renderCache.markActive(identity)
            observationRegistry.markActive(identity)
        }
        for root in pendingEffects.activeSubtreeRoots {
            stateStorage.markSubtreeActive(root)
            observationRegistry.markSubtreeActive(root)
            renderCache.markActive(root)
        }
    }

    /// Builds complete environment values for this runtime.
    func environmentValues(
        extending base: EnvironmentValues = EnvironmentValues()
    ) -> EnvironmentValues {
        var environment = base
        environment.stateStorage = stateStorage
        environment.observationRegistry = observationRegistry
        environment.lifecycle = lifecycle
        environment.keyEventDispatcher = keyEventDispatcher
        environment.renderCache = renderCache
        environment.renderInvalidationSink = appState
        environment.preferenceStorage = preferences
        environment.runtimeDiagnostics = runtimeDiagnostics
        environment.localizationService = localizationService
        environment.notificationService = notificationService
        environment.storageBackend = storageBackend
        environment.runtimeClock = clock
        environment.focusManager = focusManager
        environment.paletteManager = paletteManager
        environment.appearanceManager = appearanceManager
        environment.statusBar = statusBar
        environment.appHeader = appHeader
        environment.imageLoader = imageLoader
        environment.imageCache = imageCache

        if let palette = paletteManager.currentPalette {
            environment.palette = palette
        }
        if let appearance = appearanceManager.currentAppearance {
            environment.appearance = appearance
        }
        return environment
    }

    /// Applies cache invalidations queued by state producers.
    ///
    /// This method runs on the render owner before a frame, keeping the
    /// non-thread-safe render cache away from background state tasks.
    func applyPendingRenderInvalidations() {
        for invalidation in appState.consumePendingCacheInvalidations() {
            switch invalidation {
            case .renderOnly:
                break
            case .subtree(let identity):
                renderCache.clearAffected(by: identity)
            case .all:
                renderCache.clearAll()
            }
        }
    }

    /// Resets all services to their initial state.
    func reset() {
        appState.reset()
        lifecycle.reset()
        keyEventDispatcher.clearHandlers()
        preferences.reset()
        runtimeDiagnostics.reset()
        stateStorage.reset()
        observationRegistry.reset()
        renderCache.reset()
        notificationService.clear()
        focusManager.clear()
        imageCache.removeAll()
        storageBackend.synchronize()
    }
}
