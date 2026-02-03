//
//  ChildInfo.swift
//  TUIkit
//
//  Layout metadata for child views within stack containers.
//

// MARK: - Child Info

/// Describes a child view within a stack for layout purposes.
struct ChildInfo {
    /// The rendered buffer of this child (nil for spacers, computed later).
    let buffer: FrameBuffer?

    /// Whether this child is a Spacer.
    let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    let spacerMinLength: Int?
}

// MARK: - Child Info Provider

/// Internal protocol that allows stack containers to extract individual
/// child info from their content (which is typically a TupleView).
protocol ChildInfoProvider {
    /// Returns an array of ChildInfo, one per child view.
    func childInfos(context: RenderContext) -> [ChildInfo]
}

/// Creates a ChildInfo for a single view.
///
/// If the view is a ``Spacer``, the returned info marks it as such
/// with its minimum length. Otherwise the view is rendered into a
/// ``FrameBuffer`` via ``renderToBuffer(_:context:)``.
///
/// - Parameters:
///   - view: The child view.
///   - context: The rendering context.
/// - Returns: A ``ChildInfo`` describing the view.
func makeChildInfo<V: View>(for view: V, context: RenderContext) -> ChildInfo {
    if let spacer = view as? Spacer {
        return ChildInfo(buffer: nil, isSpacer: true, spacerMinLength: spacer.minLength)
    }
    return ChildInfo(
        buffer: renderToBuffer(view, context: context),
        isSpacer: false,
        spacerMinLength: nil
    )
}

// MARK: - Child Info Resolution

/// Resolves child infos from a view's content.
///
/// If the content conforms to ``ChildInfoProvider`` (e.g. TupleViews),
/// it returns individual child infos. Otherwise it returns the content
/// as a single-element array.
///
/// - Parameters:
///   - content: The content view.
///   - context: The rendering context.
/// - Returns: An array of ``ChildInfo``.
func resolveChildInfos<V: View>(from content: V, context: RenderContext) -> [ChildInfo] {
    if let provider = content as? ChildInfoProvider {
        return provider.childInfos(context: context)
    }
    return [makeChildInfo(for: content, context: context)]
}
