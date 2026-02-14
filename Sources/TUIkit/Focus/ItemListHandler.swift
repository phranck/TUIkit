//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ItemListHandler.swift
//
//  Created by LAYERED.work
//  License: MIT


// MARK: - Selection Mode

/// The selection mode for a list or table component.
public enum SelectionMode: Sendable {
    /// Single selection with optional binding (nil = no selection).
    case single

    /// Multi-selection with Set binding.
    case multi
}

// MARK: - Item List Handler

/// A reusable focus handler for list and table components.
///
/// `ItemListHandler` consolidates the navigation and selection logic shared by
/// `List` and `Table`. It handles:
/// - Focus registration with the focus manager
/// - Keyboard navigation (Up/Down/Home/End/PageUp/PageDown)
/// - Single and multi-selection modes
/// - Scroll offset management to keep the focused item visible
/// - Disabled state (prevents focus when disabled)
///
/// ## Usage
///
/// ```swift
/// // In List's renderToBuffer:
/// let handler = ItemListHandler(
///     focusID: focusID,
///     itemCount: items.count,
///     viewportHeight: visibleRows,
///     selectionMode: .single,
///     canBeFocused: !isDisabled
/// )
/// handler.singleSelection = singleSelectionBinding
/// focusManager.register(handler, inSection: sectionID)
/// ```
///
/// ## Navigation Keys
///
/// | Key | Action |
/// |-----|--------|
/// | Up | Move focus up (wrap to end) |
/// | Down | Move focus down (wrap to start) |
/// | Home | Jump to first item |
/// | End | Jump to last item |
/// | PageUp | Move up by viewport height |
/// | PageDown | Move down by viewport height |
/// | Enter/Space | Toggle selection at focused index |
final class ItemListHandler: Focusable {
    /// The unique identifier for this focusable element.
    let focusID: String

    /// The total number of items in the list.
    var itemCount: Int

    /// The number of visible items in the viewport.
    var viewportHeight: Int

    /// The selection mode (single or multi).
    let selectionMode: SelectionMode

    /// Whether this element can currently receive focus.
    var canBeFocused: Bool

    /// The currently focused item index (keyboard cursor).
    var focusedIndex: Int = 0

    /// The scroll offset (first visible item index).
    var scrollOffset: Int = 0

    /// Binding for single selection mode (optional ID).
    var singleSelection: Binding<AnyHashable?>?

    /// Binding for multi-selection mode (Set of IDs).
    var multiSelection: Binding<Set<AnyHashable>>?

    /// Maps item indices to their IDs for selection management.
    var itemIDs: [AnyHashable] = []

    /// The set of indices that can be selected and focused.
    ///
    /// Headers and footers have non-selectable indices (not in this set).
    /// Only content rows have indices in `selectableIndices`.
    /// When empty, all items are considered selectable (backward compatibility).
    var selectableIndices: Set<Int> = []

    /// Creates an item list handler.
    ///
    /// - Parameters:
    ///   - focusID: The unique focus identifier.
    ///   - itemCount: The total number of items.
    ///   - viewportHeight: The number of visible items.
    ///   - selectionMode: Single or multi-selection mode.
    ///   - canBeFocused: Whether this element can receive focus.
    init(
        focusID: String,
        itemCount: Int,
        viewportHeight: Int,
        selectionMode: SelectionMode,
        canBeFocused: Bool = true
    ) {
        self.focusID = focusID
        self.itemCount = itemCount
        self.viewportHeight = viewportHeight
        self.selectionMode = selectionMode
        self.canBeFocused = canBeFocused
    }
}

// MARK: - Focus Lifecycle

extension ItemListHandler {
    func onFocusLost() {
        // When focus is lost, reset focused index to the first selected item
        // (if any) so that when focus returns, the user sees the selection.
        switch selectionMode {
        case .single:
            if let selection = singleSelection?.wrappedValue,
               let index = itemIDs.firstIndex(of: selection) {
                focusedIndex = index
            }
        case .multi:
            if let selection = multiSelection?.wrappedValue,
               let firstSelected = selection.first,
               let index = itemIDs.firstIndex(of: firstSelected) {
                focusedIndex = index
            }
        }

        // Ensure scroll offset keeps focused item visible
        ensureFocusedItemVisible()
    }

    func onFocusReceived() {
        // Ensure the focused item is visible when focus is received
        ensureFocusedItemVisible()
    }
}

// MARK: - Key Event Handling

extension ItemListHandler {
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        guard itemCount > 0 else { return false }

        switch event.key {
        case .up:
            moveFocus(by: -1, wrap: true)
            return true

        case .down:
            moveFocus(by: 1, wrap: true)
            return true

        case .home:
            if selectableIndices.isEmpty {
                focusedIndex = 0
            } else if let firstSelectable = selectableIndices.min() {
                focusedIndex = firstSelectable
            } else {
                return false
            }
            ensureFocusedItemVisible()
            return true

        case .end:
            if selectableIndices.isEmpty {
                focusedIndex = itemCount - 1
            } else if let lastSelectable = selectableIndices.max() {
                focusedIndex = lastSelectable
            } else {
                return false
            }
            ensureFocusedItemVisible()
            return true

        case .pageUp:
            moveFocus(by: -viewportHeight, wrap: false)
            return true

        case .pageDown:
            moveFocus(by: viewportHeight, wrap: false)
            return true

        case .enter, .character(" "):
            toggleSelectionAtFocusedIndex()
            return true

        default:
            return false
        }
    }
}

// MARK: - Navigation Helpers

extension ItemListHandler {
    /// Moves focus by the given delta, optionally wrapping around.
    ///
    /// - Parameters:
    ///   - delta: The number of items to move (negative = up, positive = down).
    ///   - wrap: Whether to wrap around at boundaries.
    func moveFocus(by delta: Int, wrap: Bool) {
        guard itemCount > 0 else { return }

        var newIndex = focusedIndex + delta

        // If selectableIndices is populated, skip non-selectable rows
        if !selectableIndices.isEmpty {
            let maxAttempts = itemCount + 1
            var attempts = 0

            // Keep moving until we find a selectable index or hit max attempts
            while attempts < maxAttempts {
                if wrap {
                    // Wrap around: -1 becomes last, count becomes 0
                    newIndex = ((newIndex % itemCount) + itemCount) % itemCount
                } else {
                    // Clamp to valid range and stop if out of bounds
                    if newIndex < 0 || newIndex >= itemCount {
                        return
                    }
                }

                // Check if this index is selectable
                if selectableIndices.contains(newIndex) {
                    break
                }

                newIndex += delta
                attempts += 1
            }

            // If we couldn't find a selectable index, don't move
            if attempts >= maxAttempts {
                return
            }
        } else {
            // Backward compatibility: all items are selectable
            if wrap {
                // Wrap around: -1 becomes last, count becomes 0
                newIndex = ((newIndex % itemCount) + itemCount) % itemCount
            } else {
                // Clamp to valid range
                newIndex = max(0, min(itemCount - 1, newIndex))
            }
        }

        focusedIndex = newIndex
        ensureFocusedItemVisible()
    }

    /// Adjusts scroll offset to keep the focused item visible.
    func ensureFocusedItemVisible() {
        guard viewportHeight > 0 else { return }

        // If focused item is above the viewport, scroll up
        if focusedIndex < scrollOffset {
            scrollOffset = focusedIndex
        }

        // If focused item is below the viewport, scroll down
        if focusedIndex >= scrollOffset + viewportHeight {
            scrollOffset = focusedIndex - viewportHeight + 1
        }

        // Clamp scroll offset to valid range
        let maxOffset = max(0, itemCount - viewportHeight)
        scrollOffset = max(0, min(maxOffset, scrollOffset))
    }
}

// MARK: - Selection Helpers

extension ItemListHandler {
    /// Toggles the selection state at the focused index.

    /// Configures selection bindings by converting typed bindings to type-erased `AnyHashable` bindings.
    ///
    /// This helper eliminates duplicated binding conversion code in `_ListCore` and `_TableCore`.
    ///
    /// - Parameters:
    ///   - single: An optional single-selection binding.
    ///   - multi: An optional multi-selection binding.
    func configureSelectionBindings<T: Hashable>(
        single: Binding<T?>?,
        multi: Binding<Set<T>>?
    ) {
        if let binding = single {
            singleSelection = Binding<AnyHashable?>(
                get: { binding.wrappedValue.map { AnyHashable($0) } },
                set: { newValue in
                    binding.wrappedValue = newValue?.base as? T
                }
            )
        }
        if let binding = multi {
            multiSelection = Binding<Set<AnyHashable>>(
                get: { Set(binding.wrappedValue.map { AnyHashable($0) }) },
                set: { newValue in
                    binding.wrappedValue = Set(newValue.compactMap { $0.base as? T })
                }
            )
        }
    }

    func toggleSelectionAtFocusedIndex() {
        guard focusedIndex >= 0 && focusedIndex < itemIDs.count else { return }

        let itemID = itemIDs[focusedIndex]

        switch selectionMode {
        case .single:
            // Single selection: set to this item (or nil if already selected to deselect)
            if singleSelection?.wrappedValue == itemID {
                singleSelection?.wrappedValue = nil
            } else {
                singleSelection?.wrappedValue = itemID
            }

        case .multi:
            // Multi-selection: toggle this item in the set
            if var current = multiSelection?.wrappedValue {
                if current.contains(itemID) {
                    current.remove(itemID)
                } else {
                    current.insert(itemID)
                }
                multiSelection?.wrappedValue = current
            }
        }
    }

    /// Returns whether the item at the given index is selected.
    ///
    /// - Parameter index: The item index.
    /// - Returns: True if the item is selected.
    func isSelected(at index: Int) -> Bool {
        guard index >= 0 && index < itemIDs.count else { return false }

        let itemID = itemIDs[index]

        switch selectionMode {
        case .single:
            return singleSelection?.wrappedValue == itemID
        case .multi:
            return multiSelection?.wrappedValue.contains(itemID) ?? false
        }
    }

    /// Returns whether the item at the given index is focused.
    ///
    /// - Parameter index: The item index.
    /// - Returns: True if the item is focused.
    func isFocused(at index: Int) -> Bool {
        focusedIndex == index
    }
}

// MARK: - Scroll Indicator State

extension ItemListHandler {
    /// Whether there is content above the visible viewport.
    var hasContentAbove: Bool {
        scrollOffset > 0
    }

    /// Whether there is content below the visible viewport.
    var hasContentBelow: Bool {
        scrollOffset + viewportHeight < itemCount
    }

    /// The range of visible item indices.
    var visibleRange: Range<Int> {
        let start = scrollOffset
        let end = min(scrollOffset + viewportHeight, itemCount)
        return start..<end
    }
}
