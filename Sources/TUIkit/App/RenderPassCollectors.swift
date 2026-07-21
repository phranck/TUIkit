//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderPassCollectors.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Render Pass Collectors

/// Per-pass scratch sinks for effects that do **not** outlive the frame.
///
/// A frame may traverse the view tree several times (first-frame header
/// measurement, main pass, header-correction pass), but only ONE traversal
/// produces the frame's output. Effect sites must therefore never write
/// per-frame registrations directly into the live managers — a discarded
/// pass would leave ghost handlers, items, or buffers behind.
///
/// `RenderPassCollectors` solves this with the collector half of the effect
/// classification rule (see ``RenderPhase``):
///
/// > Does the effect outlive the frame? **No → pass collector (this type).**
/// > Yes → pending diff (issue #57).
///
/// ## How it works
///
/// `RenderLoop` creates one `RenderPassCollectors` per traversal and injects
/// its members into that pass's environment. Effect sites stay completely
/// unchanged — they keep writing to `context.environment.keyEventDispatcher`
/// and friends; the environment simply hands them the scratch instance of
/// the current pass instead of the live manager.
///
/// At frame commit, `RenderLoop` adopts the FINAL pass's collectors into the
/// live managers (`adopt(from:)` on each manager type). Collectors of
/// discarded passes are dropped without further ceremony: because nothing
/// live was ever touched, discarding requires no rollback.
///
/// ## What is collected here
///
/// - Key handlers (`KeyEventDispatcher`)
/// - Preference values and change callbacks (`PreferenceStorage`)
/// - Declarative status-bar registrations (`StatusBarState`)
/// - The app-header buffer (`AppHeaderState`) — the first-frame measurement
///   pass reads the header height from its scratch instance, which is then
///   discarded, so sizing never mutates live state
///
/// Focus registrations are the deliberate exception: focus queries
/// (`isFocused`) must read live state during traversal, so `FocusManager`
/// stages registrations internally instead of using a scratch instance
/// (see `FocusManager.beginPass()`).
@MainActor
struct RenderPassCollectors {
    /// Scratch sink for key handlers registered by this pass's tree.
    let keyEventDispatcher = KeyEventDispatcher()

    /// Scratch sink for preference values and change callbacks.
    let preferences = PreferenceStorage()

    /// Scratch sink for declarative status-bar registrations.
    let statusBar: StatusBarState

    /// Scratch sink for the app-header buffer.
    let appHeader = AppHeaderState()

    /// Creates fresh collectors for one render pass.
    ///
    /// - Parameter appState: The runtime's render-state sink; required by
    ///   `StatusBarState` for its (unsupported but non-crashing) imperative
    ///   re-render paths.
    init(appState: AppState) {
        self.statusBar = StatusBarState(appState: appState)
    }

    /// Adopts this pass's collected registrations into the live managers.
    ///
    /// This is commit step "6a" of the frame choreography (see `RenderLoop`):
    /// the single point where per-frame effect state reaches the live
    /// runtime, called exactly once per frame with the FINAL pass's
    /// collectors.
    ///
    /// - Parameter tuiContext: The runtime whose live managers adopt the
    ///   collected state.
    func adoptIntoLiveManagers(of tuiContext: TUIContext) {
        tuiContext.keyEventDispatcher.adopt(from: keyEventDispatcher)
        tuiContext.preferences.adopt(from: preferences)
        tuiContext.statusBar.adoptPassRegistrations(from: statusBar)
        tuiContext.appHeader.adopt(from: appHeader)
    }
}
