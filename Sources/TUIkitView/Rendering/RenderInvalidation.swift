//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderInvalidation.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Render Invalidation

/// Describes the rendering work requested by a state producer.
public enum RenderInvalidation: Sendable {
    /// Requests another frame without invalidating memoized view output.
    case renderOnly

    /// Invalidates cached output associated with one view subtree.
    case subtree(ViewIdentity)

    /// Invalidates every cached subtree before the next frame.
    case all
}

// MARK: - Render Invalidation Sink

/// Lower-module boundary for routing changes to the owning render runtime.
///
/// State producers depend on this protocol instead of reaching upward to an
/// application runtime or global service. Implementations must be thread-safe
/// because async view work may request invalidation from a background task.
public protocol RenderInvalidationSink: AnyObject, Sendable {
    /// Requests a render operation from the owning runtime.
    func invalidate(_ invalidation: RenderInvalidation)
}
