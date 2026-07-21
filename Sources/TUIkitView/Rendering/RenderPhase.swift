//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderPhase.swift
//
//  Created by LAYERED.work
//  License: MIT

/// The evaluation phase of the current render pass.
///
/// A single frame may traverse the view tree several times before anything
/// reaches the terminal:
///
/// 1. **Layout measurement** — containers call `sizeThatFits` (or render to
///    measure) arbitrarily often to negotiate sizes, and `RenderLoop`
///    performs a full sizing pass on the first frame to discover the app
///    header height. None of these traversals produce the frame's output.
/// 2. **Candidate-tree evaluation** — the pass whose buffer becomes (or may
///    become) the frame's terminal output. A frame can evaluate more than
///    one candidate: when the header height turns out different from the
///    estimate, a correction pass re-evaluates the tree and the earlier
///    candidate is discarded.
///
/// `RenderPhase` makes this distinction explicit on ``RenderContext/phase``
/// so that effect sites can tell sizing work apart from output work.
///
/// ## Invariants
///
/// - In ``measure``, **no effect may reach live runtime state**: no lifecycle
///   or task mounting, no focus or handler registration, no state, cache,
///   preference, header, status-bar, or terminal mutation. Bodies must be
///   evaluable arbitrarily often without observable consequences.
/// - In ``render``, effects belong to a *candidate* tree. They must not be
///   applied to live runtime state during traversal either, because the
///   candidate may still be discarded by a correction pass. Instead they are
///   recorded and applied exactly once when the frame commits (see the
///   classification rule below).
/// - Committing is **not** a phase of this enum: no view body is ever
///   evaluated while the frame commits. The commit is an explicit step in
///   `RenderLoop.render()` after the final candidate is known.
///
/// ## Classifying an effect
///
/// When writing or reviewing an effect site, ask one question:
/// **"Does the effect outlive the frame?"**
///
/// - **No** (key handlers, preference values, status-bar items, header
///   buffer, focus registrations): write it into the current pass's scratch
///   collector. The final pass's collector replaces the live state wholesale;
///   discarded passes are simply dropped.
/// - **Yes** (`onAppear`/`onDisappear` actions, `.task` mounts, `onChange`
///   and `onPreferenceChange` actions, GC liveness): record it. The frame
///   commit diffs the final records against persistent runtime state and
///   applies the difference exactly once.
///
/// This mirrors SwiftUI's model, where per-update values are recomputed and
/// replaced with each committed tree, while lifetime effects derive from the
/// identity diff between committed trees.
///
/// - SeeAlso: ``RenderContext/phase``, and the frame choreography comment on
///   `RenderLoop` for where each phase begins and ends.
public enum RenderPhase: Sendable {
    /// Layout sizing. Bodies may be evaluated arbitrarily often; no effect
    /// may reach live runtime state.
    case measure

    /// Candidate-tree evaluation for the frame's output. Effects are
    /// recorded for the frame commit, never applied directly.
    case render
}
