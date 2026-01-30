//
//  InputHandler.swift
//  TUIkit
//
//  Dispatches key events through a 3-layer priority chain.
//

// MARK: - Input Handler

/// Dispatches key events through a 3-layer priority chain.
///
/// The dispatch order is:
/// 1. **Status bar** — items with actions get first priority
/// 2. **View handlers** — registered via `onKeyPress` modifiers
/// 3. **Default bindings** — `q` (quit), `t` (theme), `a` (appearance)
///
/// If a layer consumes the event, subsequent layers are skipped.
internal struct InputHandler {
    /// The status bar state for item-level event handling.
    let statusBar: StatusBarState

    /// The key event dispatcher for view-registered handlers.
    let keyEventDispatcher: KeyEventDispatcher

    /// The palette manager for theme cycling (`t` key).
    let paletteManager: ThemeManager

    /// The appearance manager for appearance cycling (`a` key).
    let appearanceManager: ThemeManager

    /// Called when the user requests to quit the application.
    let onQuit: () -> Void

    /// Dispatches a key event through the 3-layer priority chain.
    ///
    /// - Parameter event: The key event to handle.
    func handle(_ event: KeyEvent) {
        // Layer 1: Status bar items with actions
        if statusBar.handleKeyEvent(event) {
            return
        }

        // Layer 2: View-registered key handlers
        if keyEventDispatcher.dispatch(event) {
            return
        }

        // Layer 3: Default key bindings
        switch event.key {
        case .character(let character) where character == "q" || character == "Q":
            if statusBar.isQuitAllowed {
                onQuit()
            }

        case .character(let character) where character == "t" || character == "T":
            if statusBar.showThemeItem {
                paletteManager.cycleNext()
            }

        case .character(let character) where character == "a" || character == "A":
            appearanceManager.cycleNext()

        default:
            break
        }
    }
}
