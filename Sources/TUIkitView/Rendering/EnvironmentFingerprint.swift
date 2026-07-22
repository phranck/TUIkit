//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentFingerprint.swift
//
//  License: MIT

import TUIkitCore

// MARK: - Environment Fingerprint

/// A type-erased, equatable snapshot of render-affecting environment values
/// at an ``EquatableView``'s tree position.
///
/// The render loop knows which environment keys change a subtree's visual
/// output without changing the `Equatable` view value (foreground style,
/// focus indicator color, …). It snapshots them into this opaque value via
/// ``TUIkitCore/EnvironmentValues/environmentFingerprintProbe``, and
/// ``RenderCache`` includes the fingerprint in its lookup: a mismatch
/// misses, so a style change above a cache boundary can never serve a
/// stale buffer.
///
/// Two fingerprints are equal when they wrap equal snapshots of the same
/// underlying type. The concrete snapshot type stays private to the layer
/// that installed the probe.
package struct EnvironmentFingerprint: Equatable {
    /// The type-erased snapshot value.
    private let value: Any

    /// Compares another erased snapshot against this one's typed value.
    private let equals: @Sendable (Any) -> Bool

    /// Wraps a typed environment snapshot.
    ///
    /// - Parameter value: The snapshot to erase; equality of fingerprints
    ///   is the equality of these snapshots.
    package init<Value: Equatable & Sendable>(_ value: Value) {
        self.value = value
        self.equals = { ($0 as? Value) == value }
    }

    package static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.equals(rhs.value)
    }
}

// MARK: - Environment Key

/// Environment key for the per-pass fingerprint probe.
private struct EnvironmentFingerprintProbeKey: EnvironmentKey {
    static let defaultValue: (@Sendable (EnvironmentValues) -> EnvironmentFingerprint)? = nil
}

extension EnvironmentValues {
    /// Snapshots the render-affecting environment values at a cache
    /// boundary.
    ///
    /// Installed per pass by the render loop. ``EquatableView`` passes its
    /// own environment in and hands the resulting fingerprint to
    /// ``RenderCache`` as part of the cache key, so environment-driven
    /// output changes invalidate the affected entry.
    ///
    /// `nil` outside `RenderLoop` frames (live path), where cache lookups
    /// keep their historical key of identity, view value, and size.
    package var environmentFingerprintProbe: (@Sendable (EnvironmentValues) -> EnvironmentFingerprint)? {
        get { self[EnvironmentFingerprintProbeKey.self] }
        set { self[EnvironmentFingerprintProbeKey.self] = newValue }
    }
}
