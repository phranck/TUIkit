//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Focus.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Focusable Protocol

/// A protocol for views that can receive focus.
///
/// Focusable views can receive keyboard input when focused.
/// The focus system manages which view currently has focus and
/// routes keyboard events accordingly.
public protocol Focusable: AnyObject {
    /// The unique identifier for this focusable element.
    var focusID: String { get }

    /// Whether this element can currently receive focus.
    var canBeFocused: Bool { get }

    /// Called when this element receives focus.
    func onFocusReceived()

    /// Called when this element loses focus.
    func onFocusLost()

    /// Handles a key event when focused.
    ///
    /// - Parameter event: The key event to handle.
    /// - Returns: True if the event was consumed, false to propagate.
    func handleKeyEvent(_ event: KeyEvent) -> Bool
}

// Default implementations
extension Focusable {
    public var canBeFocused: Bool { true }
    public func onFocusReceived() {}
    public func onFocusLost() {}
}

// MARK: - Focus Manager

/// Manages focus state across the application.
///
/// The focus manager organizes interactive elements into **focus sections**.
/// Each section is a named, focusable area (e.g. a sidebar, a content panel,
/// a modal) that contains its own list of focusable elements.
///
/// - **Tab / Shift+Tab** cycles between sections.
/// - **Up/Down arrows** navigate within the active section's focusable elements.
/// - **Enter/Space** activates the focused element.
///
/// Elements registered without an explicit section go into a default section.
/// When only one section exists, Tab cycles elements within it (legacy behavior).
///
/// `FocusManager` is injected via the Environment system.
/// Each app instance gets its own `FocusManager`, ensuring test isolation.
///
/// # Usage
///
/// ```swift
/// // Access via Environment in views
/// let focusManager = context.environment.focusManager
///
/// // Register a section (done by .focusSection() modifier)
/// focusManager.registerSection(id: "playlist")
///
/// // Register a focusable element in a section
/// focusManager.register(button, inSection: "playlist")
///
/// // Move focus
/// focusManager.focusNextInSection()     // within active section
/// focusManager.focusPreviousInSection() // within active section
/// focusManager.activateNextSection()    // switch to next section
///
/// // Check focus
/// if focusManager.isFocused(button) {
///     // render focused style
/// }
/// ```
public final class FocusManager: @unchecked Sendable {
    /// The default section ID for elements registered without an explicit section.
    static let defaultSectionID = "__default__"

    /// Registered focus sections in render order.
    private var sections: [FocusSection] = []

    /// The ID of the currently active section.
    private var activeSectionID: String?

    /// The currently focused element's ID within the active section.
    private var focusedID: String?

    /// Callback triggered when focus changes (element or section).
    public var onFocusChange: (() -> Void)?

    /// Creates a new focus manager instance.
    public init() {}

    /// The currently active focus section.
    var activeSection: FocusSection? {
        guard let activeID = activeSectionID else { return nil }
        return section(id: activeID)
    }

    /// The ID of the currently active section, if any.
    var activeSectionIdentifier: String? {
        activeSectionID
    }

    /// All registered section IDs in render order.
    var sectionIDs: [String] {
        sections.map(\.id)
    }

    /// Whether any sections are registered (besides potentially the default).
    var hasSections: Bool {
        !sections.isEmpty
    }

    /// The currently focused element, if any.
    public var currentFocused: Focusable? {
        guard let focusedIdentifier = focusedID else { return nil }
        // Search in active section first, then all sections
        if let section = activeSection,
            let element = section.focusables.first(where: { $0.focusID == focusedIdentifier })
        {
            return element
        }
        for section in sections where section.id != activeSectionID {
            if let element = section.focusables.first(where: { $0.focusID == focusedIdentifier }) {
                return element
            }
        }
        return nil
    }

    /// The ID of the currently focused element, if any.
    public var currentFocusedID: String? {
        focusedID
    }
}

// MARK: - Public API

public extension FocusManager {
    /// Registers a focusable element in a specific section.
    ///
    /// If the section doesn't exist, it is created automatically.
    /// If no element is focused yet in the active section, the element
    /// is auto-focused.
    ///
    /// - Parameters:
    ///   - element: The element to register.
    ///   - sectionID: The section to register in. Defaults to the active section
    ///     or the default section if no section is active.
    func register(_ element: Focusable, inSection sectionID: String? = nil) {
        let targetID = sectionID ?? activeSectionID ?? Self.defaultSectionID

        // Ensure section exists
        if !sections.contains(where: { $0.id == targetID }) {
            registerSection(id: targetID)
        }

        guard let section = section(id: targetID) else { return }
        section.register(element)

        // Auto-activate section and auto-focus first element if needed
        if activeSectionID == nil {
            activeSectionID = targetID
        }
        if targetID == activeSectionID && focusedID == nil && element.canBeFocused {
            focus(element)
        }
    }

    /// Registers a focusable element (legacy API, uses active or default section).
    ///
    /// This overload exists for backward compatibility. New code should use
    /// ``register(_:inSection:)`` to explicitly assign sections.
    ///
    /// - Parameter element: The element to register.
    func register(_ element: Focusable) {
        register(element, inSection: nil)
    }

    /// Unregisters a focusable element from all sections.
    ///
    /// - Parameter element: The element to unregister.
    func unregister(_ element: Focusable) {
        for section in sections {
            section.unregister(element)
        }

        // If the removed element was focused, focus the next available
        if focusedID == element.focusID {
            focusedID = nil
            focusNextInSection()
        }
    }

    /// Clears all sections and focusable elements, including selection state.
    ///
    /// This is a hard reset. For per-frame clearing that preserves the active
    /// section and focused element, use `beginRenderPass()` instead.
    func clear() {
        sections.removeAll()
        activeSectionID = nil
        focusedID = nil
    }

    /// Focuses a specific element.
    ///
    /// - Parameter element: The element to focus.
    func focus(_ element: Focusable) {
        guard element.canBeFocused else { return }

        notifyFocusLost()

        focusedID = element.focusID
        element.onFocusReceived()
        onFocusChange?()
    }

    /// Focuses an element by ID (searches all sections).
    ///
    /// - Parameter id: The focus ID of the element to focus.
    func focus(id: String) {
        for section in sections {
            if let element = section.focusables.first(where: { $0.focusID == id && $0.canBeFocused }) {
                // Also activate the section containing this element
                if activeSectionID != section.id {
                    activeSectionID = section.id
                }
                focus(element)
                return
            }
        }
    }

    /// Moves focus to the next element within the active section.
    func focusNextInSection() {
        moveFocusInSection(direction: .forward)
    }

    /// Moves focus to the previous element within the active section.
    func focusPreviousInSection() {
        moveFocusInSection(direction: .backward)
    }

    /// Moves focus to the next focusable element.
    ///
    /// When multiple sections exist, this cycles between sections.
    /// When only one section exists, this cycles within it.
    func focusNext() {
        if sections.count > 1 {
            activateNextSection()
        } else {
            moveFocusInSection(direction: .forward)
        }
    }

    /// Moves focus to the previous focusable element.
    ///
    /// When multiple sections exist, this cycles between sections.
    /// When only one section exists, this cycles within it.
    func focusPrevious() {
        if sections.count > 1 {
            activatePreviousSection()
        } else {
            moveFocusInSection(direction: .backward)
        }
    }

    /// Returns whether the given element is currently focused.
    ///
    /// - Parameter element: The element to check.
    /// - Returns: True if the element is focused.
    func isFocused(_ element: Focusable) -> Bool {
        focusedID == element.focusID
    }

    /// Returns whether an element with the given ID is currently focused.
    ///
    /// - Parameter id: The focus ID to check.
    /// - Returns: True if the element is focused.
    func isFocused(id: String) -> Bool {
        focusedID == id
    }

    /// Returns whether the given section is currently active.
    ///
    /// - Parameter sectionID: The section identifier to check.
    /// - Returns: True if the section is active.
    func isActiveSection(_ sectionID: String) -> Bool {
        activeSectionID == sectionID
    }

    /// Dispatches a key event through the focus system.
    ///
    /// Navigation model:
    /// - **Tab / Shift+Tab**: Cycles between sections (or within a single section).
    /// - **Up / Down arrows**: Cycles between focusable elements within the active section.
    /// - **Enter / Space**: Dispatched to the focused element for activation.
    /// - **Other keys**: Dispatched to the focused element.
    ///
    /// - Parameter event: The key event to dispatch.
    /// - Returns: True if the event was handled.
    @discardableResult
    func dispatchKeyEvent(_ event: KeyEvent) -> Bool {
        // Dispatch to focused element first — let it handle keys like Up/Down/Left/Right.
        // If element consumes the event, stop here.
        if let focused = currentFocused {
            if focused.handleKeyEvent(event) {
                return true
            }
        }

        // Tab navigation: cycle sections (or elements within single section)
        if event.key == .tab {
            if event.shift {
                focusPrevious()
            } else {
                focusNext()
            }
            return true
        }

        // Arrow keys: navigate within the active section (fallback if element didn't handle)
        // Up/Left go to previous, Down/Right go to next
        switch event.key {
        case .up, .left:
            focusPreviousInSection()
            return true
        case .down, .right:
            focusNextInSection()
            return true
        default:
            break
        }

        return false
    }
}

// MARK: - Internal API

extension FocusManager {
    /// Registers a focus section.
    ///
    /// If a section with the same ID already exists, it is reused (not duplicated).
    /// The first registered section becomes the active section automatically.
    ///
    /// - Parameter id: The unique section identifier.
    func registerSection(id: String) {
        guard !sections.contains(where: { $0.id == id }) else { return }
        let section = FocusSection(id: id)
        sections.append(section)

        // Auto-activate first section
        if activeSectionID == nil {
            activeSectionID = id
        }
    }

    /// Returns the section with the given ID, or nil if not found.
    ///
    /// - Parameter id: The section identifier.
    /// - Returns: The focus section, or nil.
    func section(id: String) -> FocusSection? {
        sections.first { $0.id == id }
    }

    /// Activates the next section (wrapping around).
    ///
    /// When switching sections, the first focusable element in the new
    /// section receives focus automatically.
    func activateNextSection() {
        cycleSection(direction: .forward)
    }

    /// Activates the previous section (wrapping around).
    ///
    /// When switching sections, the first focusable element in the new
    /// section receives focus automatically.
    func activatePreviousSection() {
        cycleSection(direction: .backward)
    }

    /// Activates a specific section by ID.
    ///
    /// The first focusable element in the section receives focus.
    ///
    /// - Parameter id: The section identifier to activate.
    func activateSection(id: String) {
        guard sections.contains(where: { $0.id == id }) else { return }

        // Notify current focused element
        notifyFocusLost()

        activeSectionID = id
        focusedID = nil

        // Auto-focus first element in the new section
        if let section = activeSection,
            let firstFocusable = section.focusables.first(where: { $0.canBeFocused })
        {
            focusedID = firstFocusable.focusID
            firstFocusable.onFocusReceived()
        }

        onFocusChange?()
    }

    /// Prepares the focus manager for a new render pass.
    ///
    /// Clears all sections and focusable elements so they can be re-registered
    /// from the current view tree. The active section ID and focused element ID
    /// are **preserved** — if they still exist after the render pass, focus
    /// continues seamlessly. If they don't, the first available element is
    /// auto-focused.
    ///
    /// Call this at the start of each render pass instead of ``clear()``.
    func beginRenderPass() {
        sections.removeAll()
        // activeSectionID and focusedID are intentionally preserved.
        // They will be validated after the render pass re-registers sections.
    }

    /// Validates focus state after a render pass.
    ///
    /// If the previously active section no longer exists, the first
    /// registered section is activated. If the previously focused element
    /// no longer exists, the first focusable in the active section is focused.
    func endRenderPass() {
        // Validate active section
        if let activeID = activeSectionID,
            !sections.contains(where: { $0.id == activeID })
        {
            activeSectionID = sections.first?.id
        }

        // Validate focused element
        if let focusID = focusedID, let section = activeSection {
            if !section.focusables.contains(where: { $0.focusID == focusID }) {
                // Previously focused element is gone — auto-focus first available
                self.focusedID = nil
                if let firstFocusable = section.focusables.first(where: { $0.canBeFocused }) {
                    self.focusedID = firstFocusable.focusID
                    firstFocusable.onFocusReceived()
                }
            }
        } else if focusedID == nil, let section = activeSection,
            let firstFocusable = section.focusables.first(where: { $0.canBeFocused })
        {
            self.focusedID = firstFocusable.focusID
            firstFocusable.onFocusReceived()
        }
    }
}

// MARK: - Private Helpers

/// The direction in which focus moves.
private enum FocusDirection {
    case forward, backward
}

private extension FocusManager {
    /// Cycles the active section in the given direction.
    func cycleSection(direction: FocusDirection) {
        guard sections.count > 1 else { return }

        let sectionIndex: Int
        if let activeID = activeSectionID,
            let currentIndex = sections.firstIndex(where: { $0.id == activeID })
        {
            switch direction {
            case .forward:
                sectionIndex = (currentIndex + 1) % sections.count
            case .backward:
                sectionIndex = currentIndex == 0 ? sections.count - 1 : currentIndex - 1
            }
        } else {
            sectionIndex = direction == .forward ? 0 : sections.count - 1
        }

        activateSection(id: sections[sectionIndex].id)
    }

    /// Moves focus within the active section.
    func moveFocusInSection(direction: FocusDirection) {
        guard let section = activeSection else { return }

        let available = section.focusables.filter { $0.canBeFocused }
        guard !available.isEmpty else { return }

        if let currentID = focusedID,
            let currentIndex = available.firstIndex(where: { $0.focusID == currentID })
        {
            let targetIndex: Int
            switch direction {
            case .forward:
                targetIndex = (currentIndex + 1) % available.count
            case .backward:
                targetIndex = currentIndex == 0 ? available.count - 1 : currentIndex - 1
            }
            focus(available[targetIndex])
        } else {
            let fallbackIndex = direction == .forward ? 0 : available.count - 1
            focus(available[fallbackIndex])
        }
    }

    /// Notifies the currently focused element that it lost focus.
    func notifyFocusLost() {
        guard let currentID = focusedID else { return }
        for section in sections {
            if let current = section.focusables.first(where: { $0.focusID == currentID }) {
                current.onFocusLost()
                return
            }
        }
    }
}

// MARK: - Focus Manager Environment Key

/// Environment key for the focus manager.
private struct FocusManagerKey: EnvironmentKey {
    static let defaultValue = FocusManager()
}

extension EnvironmentValues {
    /// The focus manager for managing keyboard focus.
    ///
    /// Access via `context.environment.focusManager` in `renderToBuffer(context:)`.
    public var focusManager: FocusManager {
        get { self[FocusManagerKey.self] }
        set { self[FocusManagerKey.self] = newValue }
    }
}

// MARK: - Focus State for Views

/// Tracks focus state for a specific element.
///
/// `FocusState` is a lightweight wrapper around a `FocusManager` that
/// provides a simple focused/unfocused API for a single element.
///
/// Create a `FocusState` with a reference to the focus manager
/// (typically obtained from `context.environment.focusManager`):
///
/// ```swift
/// let focus = FocusState(focusManager: context.environment.focusManager)
/// if focus.isFocused { /* render focused style */ }
/// ```
public class FocusState {
    /// The focus ID.
    public let id: String

    /// The focus manager that tracks focus state.
    private let focusManager: FocusManager

    /// Creates a focus state with the given ID and focus manager.
    ///
    /// - Parameters:
    ///   - id: The unique focus ID. Defaults to a new UUID.
    ///   - focusManager: The focus manager to query and mutate.
    public init(id: String = UUID().uuidString, focusManager: FocusManager) {
        self.id = id
        self.focusManager = focusManager
    }

    /// Whether this element is currently focused.
    public var isFocused: Bool {
        focusManager.isFocused(id: id)
    }
}

// MARK: - Public API

public extension FocusState {
    /// Requests focus for this element.
    func requestFocus() {
        focusManager.focus(id: id)
    }
}
