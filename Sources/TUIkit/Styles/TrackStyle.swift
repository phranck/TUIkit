//  TUIKit - Terminal UI Kit for Swift
//  TrackStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Track Style

/// The visual style of a track-based control like ProgressView or Slider.
///
/// TUIKit provides five built-in styles using different Unicode characters:
///
/// ```
/// bar:       ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌────────────────
/// block:     ████████████████░░░░░░░░░░░░░░░░
/// blockFine: ████████████████▍░░░░░░░░░░░░░░░   (sub-character precision)
/// dot:       ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬●────────────────
/// shade:     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░
/// ```
public enum TrackStyle: Sendable, Equatable {
    /// Vertical bar characters with a horizontal line track.
    ///
    /// Uses `▌` for filled and `─` for empty.
    case bar

    /// Full block characters (default).
    ///
    /// Uses `█` for filled cells and `░` for empty cells.
    case block

    /// Full block characters with sub-character fractional precision.
    ///
    /// Uses `█` for filled cells, fractional blocks (`▉▊▋▌▍▎▏`) for the
    /// partial cell at the boundary, and `░` for empty cells. This gives
    /// 8x finer visual resolution than ``block``.
    case blockFine

    /// Rectangle track with a dot indicator at the progress position.
    ///
    /// Uses `▬` for filled, `●` as the progress head, and `─` for empty.
    /// The dot head renders in the accent color.
    case dot

    /// Shade characters for a softer, textured look.
    ///
    /// Uses `▓` (dark shade) for filled and `░` (light shade) for empty.
    case shade
}

// MARK: - Backwards Compatibility

/// Backwards-compatible type alias for `TrackStyle`.
///
/// Use `TrackStyle` in new code. This alias exists to maintain
/// compatibility with existing code using `ProgressBarStyle`.
@available(*, deprecated, renamed: "TrackStyle")
public typealias ProgressBarStyle = TrackStyle
