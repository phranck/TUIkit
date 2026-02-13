//  🖥️ TUIKit — Terminal UI Kit for Swift
//  InputHandler.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Input Handler

/// Dispatches key events through a 4-layer priority chain.
///
/// The dispatch order is:
/// 1. **Status bar** — items with actions get first priority
/// 2. **View handlers** — registered via `onKeyPress` modifiers
/// 3. **Focus system** — Tab/Shift+Tab navigation, Enter/Space on focused buttons
/// 4. **Default bindings** — `q` (quit), `t` (theme), `a` (appearance)
///
/// If a layer consumes the event, subsequent layers are skipped.
internal struct InputHandler {
    /// The status bar state for item-level event handling.
    let statusBar: StatusBarState

    /// The key event dispatcher for view-registered handlers.
    let keyEventDispatcher: KeyEventDispatcher

    /// The focus manager for Tab navigation and focused element activation.
    let focusManager: FocusManager

    /// The palette manager for theme cycling (`t` key).
    let paletteManager: ThemeManager

    /// The appearance manager for appearance cycling (`a` key).
    let appearanceManager: ThemeManager

    /// Called when the user requests to quit the application.
    let onQuit: () -> Void
}

// MARK: - Internal API

extension InputHandler {
    /// Dispatches a key event through the 4-layer priority chain.
    ///
    /// - Parameter event: The key event to handle.
    func handle(_ event: KeyEvent) {
        // Text-Input Priority: when a text-input element (TextField/SecureField)
        // is focused, let it handle the event FIRST. This ensures printable
        // characters, backspace, delete, arrows, home, end, and enter reach the
        // text field before any other layer can intercept them.
        //
        // Only structural/navigation keys that the text field does NOT consume
        // (Escape, Tab, unhandled Ctrl+shortcuts) fall through to other layers.
        if focusManager.hasTextInputFocus {
            if focusManager.dispatchKeyEvent(event) {
                return
            }
        }

        // Layer 1: Status bar items with actions
        if statusBar.handleKeyEvent(event) {
            return
        }

        // Layer 2: View-registered key handlers (onKeyPress, Menu arrow keys)
        if keyEventDispatcher.dispatch(event) {
            return
        }

        // Layer 3: Focus system (Tab navigation, Enter/Space on focused buttons)
        // Skipped when text-input has focus since it was already dispatched above.
        if !focusManager.hasTextInputFocus {
            if focusManager.dispatchKeyEvent(event) {
                return
            }
        }

        // Layer 4: Default key bindings
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
