//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarItemComposition.swift
//
//  Created by LAYERED.work
//  License: MIT

/// Defines how a focus section's StatusBar items compose with parent items.
///
/// StatusBar items are **declarative** — each focus section declares its items
/// once, and the framework resolves which items to display based on the active
/// section's composition strategy.
///
/// ## Strategies
///
/// - **`.merge`** (default): Section's items are combined with parent items.
///   If both declare the same shortcut, the child's item wins.
/// - **`.replace`**: Section's items are the only items shown. Parent items
///   are invisible. Acts as a cascade barrier.
///
/// ## Examples
///
/// ```swift
/// // Default: merge with parent items
/// PlaylistView()
///     .focusSection("playlist")
///     .statusBarItems {
///         StatusBarItem(shortcut: Shortcut.enter, label: "play")
///     }
///
/// // Modal: replace all parent items
/// SettingsView()
///     .focusSection("settings")
///     .statusBarItems(.replace) {
///         StatusBarItem(shortcut: Shortcut.escape, label: "close")
///     }
/// ```
public enum StatusBarItemComposition: Sendable {
    /// Merges with parent items.
    ///
    /// The section's items are combined with items from ancestor views.
    /// If a child declares the same shortcut as a parent, the child's item
    /// takes priority (child wins on conflict).
    ///
    /// This is the default behavior and the most common case.
    case merge

    /// Replaces all parent items.
    ///
    /// Acts as a cascade barrier — no items from parent views leak through.
    /// Only this section's items and system items are shown.
    ///
    /// Use this for modals, dialogs, and other views that need a clean slate.
    case replace
}
