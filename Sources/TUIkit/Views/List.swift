//  🖥️ TUIKit — Terminal UI Kit for Swift
//  List.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - List View

/// A scrollable list component that displays arbitrary views in a vertical container.
///
/// The List supports optional selection binding, keyboard navigation, and auto-scrolling.
/// Each row in the list is focusable and can be selected via Enter/Space if tagged with a value.
///
/// # Basic Example
///
/// ```swift
/// List {
///     Text("Item 1")
///     Text("Item 2")
///     Text("Item 3")
/// }
/// ```
///
/// # With Selection
///
/// ```swift
/// @State var selectedID: String?
///
/// List(selection: $selectedID) {
///     Text("Item 1").tag("id-1")
///     Text("Item 2").tag("id-2")
/// }
/// ```
///
/// # Dynamic Content
///
/// ```swift
/// List {
///     ForEach(items, id: \.id) { item in
///         Text(item.name).tag(item.id)
///     }
/// }
/// ```
///
/// # Keyboard Navigation
///
/// - **↑/↓**: Navigate between rows (wraps at boundaries)
/// - **Page Up/Down**: Scroll 5 rows at a time
/// - **Home/End**: Jump to first/last row
/// - **Enter/Space**: Select focused row (if `.tag()` is present)
/// - **Tab**: Exit list, focus next element
public struct List<SelectionValue: Hashable, Content: View>: View {
    /// The binding to the selected value (optional).
    let selection: Binding<SelectionValue>?
    
    /// The content builder that provides rows.
    let content: Content
    
    /// Fixed height of the list container (optional).
    /// If nil, uses available height from context.
    let height: Int?
    
    /// Whether the list is disabled.
    var isDisabled: Bool
    
    /// The unique focus identifier for the list.
    let focusID: String?
    
    /// Creates a scrollable list with selection and content.
    ///
    /// - Parameters:
    ///   - selection: Optional binding to track selected value.
    ///   - height: Fixed height in lines (optional, defaults to available height).
    ///   - focusID: Unique focus identifier (optional, auto-generated if not provided).
    ///   - builder: A builder closure that provides the list content (rows).
    public init(
        selection: Binding<SelectionValue>?,
        height: Int? = nil,
        focusID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.selection = selection
        self.content = content()
        self.height = height
        self.focusID = focusID
        self.isDisabled = false
    }
    
    /// Creates a scrollable list without selection.
    ///
    /// - Parameters:
    ///   - height: Fixed height in lines (optional, defaults to available height).
    ///   - focusID: Unique focus identifier (optional, auto-generated if not provided).
    ///   - builder: A builder closure that provides the list content (rows).
    public init(
        height: Int? = nil,
        focusID: String? = nil,
        @ViewBuilder content: () -> Content
    ) where SelectionValue == Never {
        self.selection = nil
        self.content = content()
        self.height = height
        self.focusID = focusID
        self.isDisabled = false
    }
    
    public var body: Never {
        fatalError("List renders via Renderable")
    }
}

// MARK: - List Handler

/// Internal handler class for list focus, navigation, and selection management.
///
/// Persisted across renders via StateStorage to maintain:
/// - `focusedIndex`: Current keyboard navigation position
/// - `scrollOffset`: Top row index of visible viewport
final class ListHandler: Focusable {
    let focusID: String
    var selection: Binding<AnyHashable>?
    var rowCount: Int
    var canBeFocused: Bool
    
    /// The currently focused row index (0-based).
    /// Persisted to maintain focus position across renders.
    var focusedIndex: Int = 0
    
    /// The top row index of the visible viewport (0-based).
    /// Persisted to maintain scroll position across renders.
    var scrollOffset: Int = 0
    
    /// Viewport height in lines.
    /// Set during rendering based on available space or fixed height.
    var viewportHeight: Int = 5
    
    init(
        focusID: String,
        selection: Binding<AnyHashable>?,
        rowCount: Int,
        canBeFocused: Bool
    ) {
        self.focusID = focusID
        self.selection = selection
        self.rowCount = rowCount
        self.canBeFocused = canBeFocused
        
        // Auto-focus first row if not empty
        self.focusedIndex = rowCount > 0 ? 0 : -1
    }
}

// MARK: - Focus Lifecycle

extension ListHandler {
    func onFocusLost() {
        // Keep focusedIndex as-is, will be restored on focus received
    }
}

// MARK: - Keyboard Navigation

extension ListHandler {
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        guard rowCount > 0, focusedIndex >= 0 else { return false }
        
        switch event.key {
        case .up:
            focusUp()
            return true
            
        case .down:
            focusDown()
            return true
            
        case .pageUp:
            focusPageUp()
            return true
            
        case .pageDown:
            focusPageDown()
            return true
            
        case .home:
            focusHome()
            return true
            
        case .end:
            focusEnd()
            return true
            
        case .enter, .character(" "):
            // Select focused item by index
            selectFocused()
            return true
            
        default:
            return false
        }
    }
    
    private func selectFocused() {
        guard let selection = selection, focusedIndex >= 0 else { return }
        // Set selection to row index for now
        // TODO: Support proper tag-based selection
        selection.wrappedValue = AnyHashable(focusedIndex)
    }
    
    private func focusUp() {
        if focusedIndex > 0 {
            focusedIndex -= 1
        } else {
            focusedIndex = rowCount - 1  // Wrap to end
        }
        ensureFocusedInView()
    }
    
    private func focusDown() {
        if focusedIndex < rowCount - 1 {
            focusedIndex += 1
        } else {
            focusedIndex = 0  // Wrap to start
        }
        ensureFocusedInView()
    }
    
    private func focusPageUp() {
        focusedIndex = max(0, focusedIndex - viewportHeight)
        ensureFocusedInView()
    }
    
    private func focusPageDown() {
        focusedIndex = min(rowCount - 1, focusedIndex + viewportHeight)
        ensureFocusedInView()
    }
    
    private func focusHome() {
        focusedIndex = 0
        ensureFocusedInView()
    }
    
    private func focusEnd() {
        focusedIndex = rowCount - 1
        ensureFocusedInView()
    }
    
    /// Ensures the focused row is visible in the current viewport.
    /// Adjusts scrollOffset if necessary.
    private func ensureFocusedInView() {
        if focusedIndex < scrollOffset {
            scrollOffset = focusedIndex
        } else if focusedIndex >= scrollOffset + viewportHeight {
            scrollOffset = focusedIndex - viewportHeight + 1
        }
    }
}

// MARK: - List Rendering

extension List: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let palette = context.environment.palette
        let stateStorage = context.tuiContext.stateStorage
        
        // Render content and extract rows from the buffer
        let contentBuffer = TUIkit.renderToBuffer(content, context: context)
        let rows = contentBuffer.lines
        let rowCount = rows.count
        
        // Early exit for empty list
        guard rowCount > 0 else {
            return FrameBuffer(lines: ["(empty)"])
        }
        
        // Create type-erased selection binding
        let erasedSelection = selection.map { sel in
            Binding<AnyHashable>(
                get: { AnyHashable(sel.wrappedValue) },
                set: { newValue in
                    if let typedValue = newValue.base as? SelectionValue {
                        sel.wrappedValue = typedValue
                    }
                }
            )
        }
        
        // Get or create persistent focusID
        let focusIDKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 1)
        let focusIDBox: StateBox<String> = stateStorage.storage(
            for: focusIDKey,
            default: focusID ?? "list-\(context.identity.path)"
        )
        let persistedFocusID = focusIDBox.value
        
        // Get or create persistent handler
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let handlerBox: StateBox<ListHandler> = stateStorage.storage(
            for: handlerKey,
            default: ListHandler(
                focusID: persistedFocusID,
                selection: erasedSelection,
                rowCount: rowCount,
                canBeFocused: !isDisabled
            )
        )
        let handler = handlerBox.value
        
        // Keep handler in sync with current values
        handler.selection = erasedSelection
        handler.rowCount = rowCount
        handler.canBeFocused = !isDisabled
        
        // Calculate viewport height
        let viewportHeight = height ?? context.availableHeight
        handler.viewportHeight = viewportHeight
        
        focusManager.register(handler, inSection: context.activeFocusSectionID)
        stateStorage.markActive(context.identity)
        
        // Check if list has focus
        let listHasFocus = focusManager.isFocused(id: persistedFocusID)
        
        // Render visible rows
        let visibleRange = handler.scrollOffset..<min(
            handler.scrollOffset + viewportHeight,
            rowCount
        )
        
        var lines: [String] = []
        
        for index in visibleRange {
            guard index < rows.count else { break }
            let rowText = rows[index]
            let isFocused = index == handler.focusedIndex && listHasFocus
            
            // Check if this row is selected (by index)
            let isSelected = (erasedSelection?.wrappedValue ?? AnyHashable("")) == AnyHashable(index)
            
            // Render row with selection background bar
            let rowLine = renderRow(
                rowText: rowText,
                isFocused: isFocused,
                isSelected: isSelected,
                context: context,
                palette: palette
            )
            lines.append(rowLine)
        }
        
        // Add scroll indicators if needed
        if handler.scrollOffset > 0 {
            if !lines.isEmpty {
                lines[0] = "↑ " + lines[0]
            }
        }
        
        if handler.scrollOffset + viewportHeight < rowCount {
            if !lines.isEmpty {
                lines[lines.count - 1] = "↓ " + lines[lines.count - 1]
            }
        }
        
        return FrameBuffer(lines: lines)
    }
    
    private func renderRow(
        rowText: String,
        isFocused: Bool,
        isSelected: Bool,
        context: RenderContext,
        palette: Palette
    ) -> String {
        // Selection: background bar (full width)
        if isSelected {
            let selectedBg = ANSIRenderer.colorize(
                rowText,
                foreground: palette.background,
                background: palette.accent
            )
            return selectedBg
        }
        
        // Focused but not selected: simple text with pulsing dot prefix
        if isFocused {
            let dimAccent = palette.accent.opacity(0.35)
            let dotColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
            let styledDot = ANSIRenderer.colorize("●", foreground: dotColor)
            return styledDot + " " + rowText
        }
        
        // Unfocused and not selected: just text
        return "  " + rowText
    }
}

// MARK: - List Modifiers

extension List {
    /// Creates a disabled version of this list.
    ///
    /// - Parameter disabled: Whether the list is disabled.
    /// - Returns: A new list with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Self {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }
}
