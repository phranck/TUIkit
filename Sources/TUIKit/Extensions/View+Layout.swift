//
//  View+Layout.swift
//  TUIKit
//
//  Layout and styling view modifiers: border, dimmed, background, frame, overlay, padding.
//

// MARK: - Border

extension View {
    /// Adds a border around this view.
    ///
    /// The border reserves 2 characters of width (left and right),
    /// so the content is rendered with reduced available width.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .border()  // Uses appearance.borderStyle
    ///
    /// Text("Rounded")
    ///     .border(.rounded, color: .cyan)
    ///
    /// Text("Double")
    ///     .border(.doubleLine, color: .yellow)
    /// ```
    ///
    /// - Parameters:
    ///   - style: The border style (default: appearance borderStyle).
    ///   - color: The border color (default: theme border color).
    /// - Returns: A view with a border.
    public func border(
        _ style: BorderStyle? = nil,
        color: Color? = nil
    ) -> some View {
        BorderedView(content: self, style: style, color: color)
    }
}

// MARK: - Dimmed

extension View {
    /// Applies a dimming effect to the view content.
    ///
    /// This reduces the visual intensity of the content using the ANSI dim
    /// escape code. Useful for background content when displaying overlays.
    ///
    /// # Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("This content will be dimmed")
    ///     Text("All text is affected")
    /// }
    /// .dimmed()
    /// ```
    ///
    /// - Returns: A view with the dimming effect applied.
    public func dimmed() -> some View {
        DimmedModifier(content: self)
    }
}

// MARK: - Background

extension View {
    /// Adds a background color to this view.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Warning!")
    ///     .foregroundColor(.black)
    ///     .background(.yellow)
    ///
    /// VStack {
    ///     Text("Header")
    /// }
    /// .background(.blue)
    /// ```
    ///
    /// - Parameter color: The background color.
    /// - Returns: A view with the background color applied.
    public func background(_ color: Color) -> ModifiedView<Self, BackgroundModifier> {
        modifier(BackgroundModifier(color: color))
    }
}

// MARK: - Frame

extension View {
    /// Sets an explicit frame size for this view.
    ///
    /// The content is aligned within the frame according to the specified alignment.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .frame(width: 20, alignment: .center)
    /// ```
    ///
    /// - Parameters:
    ///   - width: The desired width in characters (nil preserves intrinsic width).
    ///   - height: The desired height in lines (nil preserves intrinsic height).
    ///   - alignment: The alignment within the frame (default: .topLeading).
    /// - Returns: A view constrained to the specified frame.
    public func frame(
        width: Int? = nil,
        height: Int? = nil,
        alignment: Alignment = .topLeading
    ) -> some View {
        FlexibleFrameView(
            content: self,
            minWidth: width,
            idealWidth: width,
            maxWidth: width.map { .fixed($0) },
            minHeight: height,
            idealHeight: height,
            maxHeight: height.map { .fixed($0) },
            alignment: alignment
        )
    }

    /// Sets flexible frame constraints for this view.
    ///
    /// Use `.infinity` for maxWidth/maxHeight to expand to fill available space.
    ///
    /// # Examples
    ///
    /// ```swift
    /// // Expand to full width
    /// Text("Hello")
    ///     .frame(maxWidth: .infinity)
    ///
    /// // Expand to full size
    /// Color.blue
    ///     .frame(maxWidth: .infinity, maxHeight: .infinity)
    ///
    /// // Minimum size with expansion
    /// Text("Button")
    ///     .frame(minWidth: 10, maxWidth: .infinity)
    /// ```
    ///
    /// - Parameters:
    ///   - minWidth: Minimum width in characters.
    ///   - idealWidth: Preferred width (used when no max is set).
    ///   - maxWidth: Maximum width, or `.infinity` to fill available space.
    ///   - minHeight: Minimum height in lines.
    ///   - idealHeight: Preferred height (used when no max is set).
    ///   - maxHeight: Maximum height, or `.infinity` to fill available space.
    ///   - alignment: The alignment within the frame (default: .center).
    /// - Returns: A view with flexible frame constraints.
    public func frame(
        minWidth: Int? = nil,
        idealWidth: Int? = nil,
        maxWidth: FrameDimension? = nil,
        minHeight: Int? = nil,
        idealHeight: Int? = nil,
        maxHeight: FrameDimension? = nil,
        alignment: Alignment = .center
    ) -> some View {
        FlexibleFrameView(
            content: self,
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            idealHeight: idealHeight,
            maxHeight: maxHeight,
            alignment: alignment
        )
    }
}

// MARK: - Overlay

extension View {
    /// Layers the specified view on top of this view.
    ///
    /// The overlay is positioned according to the specified alignment
    /// within the bounds of the base view.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Background content here")
    ///     .overlay(alignment: .center) {
    ///         Text("Centered overlay")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the overlay (default: .center).
    ///   - content: The overlay content.
    /// - Returns: A view with the overlay applied.
    public func overlay<Overlay: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Overlay
    ) -> some View {
        OverlayModifier(base: self, overlay: content(), alignment: alignment)
    }
}

// MARK: - Padding

extension View {
    /// Adds padding on all sides.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding(2)
    /// ```
    ///
    /// - Parameter amount: The padding amount on all sides (default: 1).
    /// - Returns: A padded view.
    public func padding(_ amount: Int = 1) -> ModifiedView<Self, PaddingModifier> {
        modifier(PaddingModifier(insets: EdgeInsets(all: amount)))
    }

    /// Adds padding on specific edges.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding(.horizontal, 4)
    /// ```
    ///
    /// - Parameters:
    ///   - edges: The edges to pad.
    ///   - amount: The padding amount (default: 1).
    /// - Returns: A padded view.
    public func padding(_ edges: Edge, _ amount: Int = 1) -> ModifiedView<Self, PaddingModifier> {
        let insets = EdgeInsets(
            top: edges.contains(.top) ? amount : 0,
            leading: edges.contains(.leading) ? amount : 0,
            bottom: edges.contains(.bottom) ? amount : 0,
            trailing: edges.contains(.trailing) ? amount : 0
        )
        return modifier(PaddingModifier(insets: insets))
    }

    /// Adds padding with explicit edge insets.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
    /// ```
    ///
    /// - Parameter insets: The edge insets.
    /// - Returns: A padded view.
    public func padding(_ insets: EdgeInsets) -> ModifiedView<Self, PaddingModifier> {
        modifier(PaddingModifier(insets: insets))
    }
}
