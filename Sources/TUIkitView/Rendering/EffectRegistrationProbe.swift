//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EffectRegistrationProbe.swift
//
//  License: MIT

import TUIkitCore

// MARK: - Effect Registration Probe

/// Environment key for the per-pass effect-registration probe.
private struct EffectRegistrationProbeKey: EnvironmentKey {
    static let defaultValue: (@Sendable () -> Int)? = nil
}

extension EnvironmentValues {
    /// Counts the effect registrations collected by the current render pass.
    ///
    /// Installed per pass by the render loop, the closure sums every
    /// per-pass effect sink: key handlers, preference writes, status-bar
    /// declarations, staged focus registrations, and deferred
    /// lifetime-effect records. The absolute value is meaningless; callers
    /// snapshot it around a subtree rendering and compare — any delta means
    /// the subtree registered at least one effect during that rendering.
    ///
    /// ``EquatableView`` uses this to classify content on a cache miss:
    /// only subtrees that render without a delta are provably effect-free
    /// and safe to memoize.
    ///
    /// `nil` outside `RenderLoop` frames (standalone `ViewRenderer`, test
    /// harnesses), where caching keeps its historical live-path semantics.
    package var effectRegistrationProbe: (@Sendable () -> Int)? {
        get { self[EffectRegistrationProbeKey.self] }
        set { self[EffectRegistrationProbeKey.self] = newValue }
    }
}
