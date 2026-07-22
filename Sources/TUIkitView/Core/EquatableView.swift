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
///
/// ## Effect Bypass
///
/// Content that registers per-pass effects while rendering — key handlers,
/// focus registrations (Button, Toggle, …), status-bar declarations,
/// preference writes, or lifetime-effect records (`onAppear`, `.task`, …) —
/// must reach the frame's collectors on EVERY frame; serving it from a
/// cache would silently drop those registrations at the frame commit.
///
/// Inside `RenderLoop` frames the wrapper therefore classifies its content
/// on every cache miss: it snapshots the pass's effect-registration probe
/// around the rendering, and any delta flags the identity as effect-bearing
/// in the ``RenderCache``. Flagged identities never produce hits, so the
/// subtree renders each frame and behaves exactly as if it were unwrapped
/// (including pulse-animated focus indicators). Only provably effect-free
/// output is ever served from the cache, making `.equatable()` safe to
/// apply anywhere — on effect-bearing subtrees it simply has no effect.
///
/// Measurement passes (`RenderPhase.measure`) stay out of the cache
/// entirely: effect sites are inert there, so a buffer stored during
/// sizing would let the same frame's output pass hit a subtree whose
/// effects were never recorded, and any classification would measure an
/// inert traversal.
///
/// On the live path (no `RenderLoop`, e.g. `ViewRenderer` or test
/// harnesses) caching keeps its historical semantics without
/// classification.
///
/// ## Cache Invalidation
///
/// The render cache is selectively cleared when `@State` values change:
/// only cache entries in the ancestor/descendant path of the changed state
/// are invalidated. Sibling subtrees retain their cached buffers.
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

        // Measurement passes stay out of the cache entirely: effect sites
        // are inert in `.measure`, so a buffer stored here would let the
        // same frame's output pass hit a subtree whose effects were never
        // recorded, and the delta classification below would measure an
        // inert traversal.
        if context.phase == .measure {
            return TUIkitView.renderToBuffer(content, context: context)
        }

        // Fingerprint of the render-affecting environment at this position
        // (foreground style, focus indicator, …). Part of the cache key so
        // an environment change above the wrapper can never serve a stale
        // buffer. `nil` on the live path.
        let environmentFingerprint = context.environment.environmentFingerprintProbe?(context.environment)

        // Cache hit: view unchanged, size and environment match, and the
        // identity is classified effect-free (effect-bearing identities
        // never hit).
        if let cached = cache.lookup(
            identity: identity,
            view: content,
            contextWidth: context.availableWidth,
            contextHeight: context.availableHeight,
            environmentFingerprint: environmentFingerprint
        ) {
            // Still need to keep runtime records inside the cached subtree
            // active even though its body is not evaluated.
            // But we skip the actual rendering work.
            markSubtreeActive(context: context)
            return cached
        }

        // Cache miss: render and classify. Any effect registration during
        // this rendering flags the identity — an effect-bearing subtree
        // must render every frame so its registrations reach the frame's
        // collectors. Only provably effect-free output is stored. Without
        // a probe (live path) the historical semantics apply: always store.
        let probe = context.environment.effectRegistrationProbe
        let registrationsBeforeRender = probe?() ?? 0
        let buffer = TUIkitView.renderToBuffer(content, context: context)
        let carriesEffects = probe.map { $0() != registrationsBeforeRender } ?? false

        cache.setCarriesEffects(carriesEffects, for: identity)
        if !carriesEffects {
            cache.store(
                identity: identity,
                view: content,
                buffer: buffer,
                contextWidth: context.availableWidth,
                contextHeight: context.availableHeight,
                environmentFingerprint: environmentFingerprint
            )
        }

        return buffer
    }
}

// MARK: - Private Helpers

private extension EquatableView {
    /// Marks the content's runtime records as active for end-of-pass cleanup.
    ///
    /// When returning a cached buffer, the subtree's views aren't visited.
    /// Their state, Observation, and nested cache identities must still be
    /// marked active — per pass inside a RenderLoop frame, directly on the
    /// live path.
    func markSubtreeActive(context: RenderContext) {
        if let pendingEffects = context.environment.pendingFrameEffects {
            pendingEffects.markSubtreeActive(context.identity)
        } else {
            context.environment.stateStorage!.markSubtreeActive(context.identity)
            context.environment.observationRegistry?.markSubtreeActive(context.identity)
            context.environment.renderCache!.markSubtreeActive(context.identity)
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
