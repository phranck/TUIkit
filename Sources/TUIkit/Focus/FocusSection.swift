//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FocusSection.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// A named, focusable area of the UI.
///
/// A focus section groups interactive children (buttons, menus, etc.)
/// into a navigable unit. Users cycle between sections with Tab/Shift+Tab,
/// and each section can declare its own StatusBar items.
///
/// Focus sections are registered during rendering by the
/// ``FocusSectionModifier``. The ``FocusManager`` tracks all sections
/// and manages which one is currently active.
final class FocusSection {
    /// The unique identifier for this section.
    let id: String

    /// The focusable elements registered within this section.
    private(set) var focusables: [Focusable] = []

    /// Creates a new focus section with the given identifier.
    ///
    /// - Parameter id: A unique identifier for this section.
    init(id: String) {
        self.id = id
    }

    /// Registers a focusable element in this section.
    ///
    /// Duplicate registrations (same `focusID`) are ignored.
    ///
    /// - Parameter element: The element to register.
    func register(_ element: Focusable) {
        guard !focusables.contains(where: { $0.focusID == element.focusID }) else { return }
        focusables.append(element)
    }

    /// Unregisters a focusable element from this section.
    ///
    /// - Parameter element: The element to remove.
    func unregister(_ element: Focusable) {
        focusables.removeAll { $0.focusID == element.focusID }
    }

    /// Removes all focusable elements from this section.
    func clearFocusables() {
        focusables.removeAll()
    }
}
