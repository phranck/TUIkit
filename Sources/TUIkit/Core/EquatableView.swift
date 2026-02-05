//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EquatableView.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - EquatableView

/// A wrapper that enables subtree memoization for views conforming to `Equatable`.
///
/// When TUIKit renders an `EquatableView`, it compares the current content with
/// the previously cached value. If the content is unchanged **and** the available
/// size hasn't changed, the cached ``FrameBuffer`` is returned immediately —
/// skipping the entire subtree rendering.
///
/// ## Usage
///
/// Apply `.equatable()` to any `Equatable` view:
///
/// ```swift
/// struct ScoreDisplay: View, Equatable {
///     let name: String
///     let score: Int
///
///     var body: some View {
///         VStack {
///             Text(name)
///             Text("Score: \(score)")
///         }
///     }
/// }
///
/// // In a parent view:
/// ScoreDisplay(name: "Player 1", score: 42).equatable()
/// ```
///
/// When `name` and `score` are unchanged between frames, the `VStack` and both
/// `Text` views are never re-rendered — the cached buffer is returned directly.
///
/// ## When to Use
///
/// - **Large static subtrees** — views with many children that rarely change
/// - **Expensive rendering** — views whose `body` or `renderToBuffer` is costly
/// - **Animation siblings** — static views next to animated ones
///
/// ## When NOT to Use
///
/// - Views that read `@State` directly (state lives in a reference-type box,
///   so the view struct compares as equal even when state changed)
/// - Views that change every frame (the cache overhead adds no value)
/// - Views that depend on environment values that change frequently
///
/// ## Cache Invalidation
///
/// The render cache is **fully cleared** on every `@State` change. Between
/// state changes (animation ticks, pulse frames), the cache is fully active.
///
/// - SeeAlso: ``View/equatable()``
public struct EquatableView<Content: View & Equatable>: View {
    /// The wrapped view content.
    let content: Content

    /// Creates an equatable view wrapping the given content.
    ///
    /// - Parameter content: The equatable view to memoize.
    public init(content: Content) {
        self.content = content
    }

    public var body: Never {
        fatalError("EquatableView is a primitive view")
    }
}

// MARK: - Rendering

extension EquatableView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let cache = context.tuiContext.renderCache
        let identity = context.identity

        cache.markActive(identity)

        // Cache hit: view unchanged and context size matches
        if let cached = cache.lookup(
            identity: identity,
            view: content,
            contextWidth: context.availableWidth,
            contextHeight: context.availableHeight
        ) {
            // Still need to run hydration for @State properties inside
            // the cached subtree, so they stay active for GC.
            // But we skip the actual rendering work.
            markSubtreeActive(context: context)
            return cached
        }

        // Cache miss: render normally and store result
        let buffer = TUIkit.renderToBuffer(content, context: context)

        cache.store(
            identity: identity,
            view: content,
            buffer: buffer,
            contextWidth: context.availableWidth,
            contextHeight: context.availableHeight
        )

        return buffer
    }
}

// MARK: - Private Helpers

private extension EquatableView {
    /// Marks the content's identity as active in StateStorage for GC.
    ///
    /// When returning a cached buffer, the subtree's views aren't visited.
    /// Their state identities must still be marked active to prevent
    /// StateStorage from garbage-collecting them.
    func markSubtreeActive(context: RenderContext) {
        context.tuiContext.stateStorage.markActive(context.identity)
    }
}

// MARK: - View Extension

public extension View where Self: Equatable {
    /// Wraps this view in an ``EquatableView`` for subtree memoization.
    ///
    /// When the view's properties are unchanged between frames, the entire
    /// subtree is skipped and the cached rendering result is reused.
    ///
    /// ```swift
    /// struct MyView: View, Equatable {
    ///     let title: String
    ///     var body: some View { Text(title) }
    /// }
    ///
    /// MyView(title: "Hello").equatable()
    /// ```
    ///
    /// - Returns: An ``EquatableView`` wrapping this view.
    func equatable() -> EquatableView<Self> {
        EquatableView(content: self)
    }
}
