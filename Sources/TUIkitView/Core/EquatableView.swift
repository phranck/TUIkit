//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EquatableView.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore
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
/// - **Views containing focused interactive elements** (Button, Toggle, Slider,
///   etc.) whose focus indicator animates via pulse phase. The cached buffer
///   would show a frozen pulse animation.
///
/// ## Cache Invalidation
///
/// The render cache is selectively cleared when `@State` values change:
/// only cache entries in the ancestor/descendant path of the changed state
/// are invalidated. Sibling subtrees retain their cached buffers.
/// Pulse animation changes do **not** invalidate the cache, which is why
/// subtrees containing focused interactive views should not be wrapped.
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
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let cache = context.environment.renderCache!
        let identity = context.identity

        // Cache liveness is a lifetime effect: collected per pass, applied
        // from the FINAL pass at frame commit; the live path marks directly.
        if let pendingEffects = context.environment.pendingFrameEffects {
            pendingEffects.markActive(identity)
        } else {
            cache.markActive(identity)
        }

        // Cache hit: view unchanged and context size matches
        if let cached = cache.lookup(
            identity: identity,
            view: content,
            contextWidth: context.availableWidth,
            contextHeight: context.availableHeight
        ) {
            // Still need to keep runtime records inside the cached subtree
            // active even though its body is not evaluated.
            // But we skip the actual rendering work.
            markSubtreeActive(context: context)
            return cached
        }

        // Cache miss: render normally and store result
        let buffer = TUIkitView.renderToBuffer(content, context: context)

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
    /// Marks the content's runtime records as active for end-of-pass cleanup.
    ///
    /// When returning a cached buffer, the subtree's views aren't visited.
    /// Their state and Observation identities must still be marked active —
    /// per pass inside a RenderLoop frame, directly on the live path.
    func markSubtreeActive(context: RenderContext) {
        if let pendingEffects = context.environment.pendingFrameEffects {
            pendingEffects.markSubtreeActive(context.identity)
        } else {
            context.environment.stateStorage!.markSubtreeActive(context.identity)
            context.environment.observationRegistry?.markSubtreeActive(context.identity)
        }
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
