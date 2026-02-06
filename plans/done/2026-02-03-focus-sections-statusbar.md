# Focus Sections with StatusBar Cascading

## Preface

Focus Sections enable multi-panel TUIs where Tab switches between named focusable areas and the StatusBar displays context-sensitive shortcuts for each. StatusBar items cascade from the active section up to parents (merge) or stop cleanly (replace for modals). A breathing ● dot in the section border pulses via a dedicated PulseTimer, providing clear visual feedback on which section is active. Cascading composition and per-section shortcuts make complex layouts intuitive.

## Completed

**2026-02-03** — All framework steps implemented and tested. 482 tests passing. Example App update deferred to separate redesign effort.

---

## Problem

Currently, the StatusBar is a flat global state — one set of items for the entire screen. There is no concept of focus-aware StatusBar items that change based on which UI area is active.

Real-world TUI apps (e.g. a Spotify-like player with playlist + tracklist) need:
- **Tab/arrow navigation** between focusable areas on one screen
- **Context-dependent StatusBar** — each focused area shows its own shortcuts
- **Cascading inheritance** — if a focused area doesn't define StatusBar items, it inherits from its parent
- **Visual focus indicator** — the user must immediately see which section is active

## Key Design Principle: Declarative, Not Imperative

StatusBar items are **not added and removed at runtime**. They are **declared** as part of the view tree, just like everything else in a SwiftUI-style framework.

Each Focus Section declares its items once via `.statusBarItems()`. These declarations exist as long as the section exists. When the active section changes (e.g. via Tab), the StatusBar **resolves** which items to display by reading the active section's declaration and walking up the tree.

There is no push/pop, no add/remove at runtime. The `activeSectionID` pointer moves — the next render frame picks up the new section's items automatically.

This replaces the current imperative `userContextStack` (push/pop) in `StatusBarState`.

## Design

### Core Concept: Focus Sections

A **Focus Section** is a named, focusable area of the UI. Each section:
- Has a unique identity
- Can contain interactive children (buttons, menus, etc.)
- Can optionally declare its own StatusBar items with a composition strategy
- Inherits parent StatusBar items when it doesn't declare its own
- Displays a **breathing focus indicator** (●) in its border when active

### Active Section Indicator: Breathing Dot

In macOS, the active window is obvious via title bar highlighting and drop shadow. In the terminal, there is no such built-in affordance. TUIKit solves this with a **breathing dot indicator** (●) rendered inside the section's border.

#### Visual Design

- The ● character is rendered **one position right of the top-left border corner**: `╭●──────╮`
- It replaces the first horizontal border character after the corner
- Only the **active** section shows the indicator; inactive sections show a normal border
- The indicator is rendered in `palette.accent` color

#### Breathing Animation

- The dot **pulses** (fades in and out) using smooth RGB color interpolation — not ANSI dim/bold steps, but true 16M color fading via `38;2;r;g;b`
- The fade interpolates between a dimmed version (~20% brightness) and the full `palette.accent` color using a sine curve
- Cycle duration: ~3 seconds (slow, calm breathing — like the MacBook sleep LED or the Landing Page theme buttons)
- ~8-10 discrete brightness steps per cycle, ~300ms per step

#### Timer Architecture

- A **dedicated framework-level pulse timer** (`DispatchSourceTimer`), completely independent from:
  - The Spinner RunLoop (which drives spinner animations)
  - The RenderLoop (which drives frame rendering)
- The pulse timer only updates a **phase counter** (0.0 → 1.0 → 0.0, sine-based) and calls `setNeedsRender()` to trigger a re-render
- The `BorderRenderer` reads the current phase during rendering and interpolates the RGB color for the ● character

#### Color Interpolation

```
let phase = sin(pulseStep * .pi)  // 0.0 → 1.0 → 0.0 (smooth)
let dimColor = accentColor.scaled(to: 0.20)  // 20% brightness
let color = lerp(dimColor, accentColor, phase)  // Interpolated RGB
```

### StatusBar Item Composition

```swift
public enum StatusBarItemComposition {
    /// Merges with parent items. Child items override parent items on shortcut conflict.
    case merge
    /// Replaces all parent items. Acts as a cascade barrier — nothing above leaks through.
    case replace
}
```

- **`.merge`** (default) — Section's items are combined with parent items. If a child declares the same shortcut as a parent, the child wins.
- **`.replace`** — Section's items are the only items shown. Parent items are invisible. Use case: Modals that need a clean slate (ESC→close, not ESC→back).

### API

```swift
// Two panels — each merges its items with the parent's (default behavior)
HStack {
    PlaylistView()
        .focusSection("playlist")
        .statusBarItems {
            StatusBarItem(shortcut: Shortcut.enter, label: "play")
            StatusBarItem(shortcut: "d", label: "delete")
        }

    TrackListView()
        .focusSection("tracklist")
        .statusBarItems {
            StatusBarItem(shortcut: Shortcut.enter, label: "select")
            StatusBarItem(shortcut: "i", label: "info")
        }
}
.statusBarItems {
    // Parent items — visible as long as child uses .merge (default)
    StatusBarItem(shortcut: Shortcut.escape, label: "back")
    StatusBarItem(shortcut: Shortcut.tab, label: "switch panel")
}
```

```swift
// Modal — replaces all parent items (clean slate)
.modal(isPresented: $showSettings) {
    SettingsView()
        .focusSection("settings")
        .statusBarItems(.replace) {
            StatusBarItem(shortcut: Shortcut.escape, label: "close")
            StatusBarItem(shortcut: Shortcut.enter, label: "confirm")
        }
}
```

```swift
// Panel without own StatusBar items — inherits everything from parent
HStack {
    SidebarView()
        .focusSection("sidebar")  // No items → inherits parent's StatusBar

    ContentView()
        .focusSection("content")
        .statusBarItems {
            StatusBarItem(shortcut: "n", label: "new")  // Merged with parent's items
        }
}
```

### Navigation

- **Tab / Shift+Tab**: Cycle focus between sibling focus sections
- **Arrow Up/Down**: Reserved for navigation within a section (e.g. list items, menu)
- **Enter/Space**: Activate current focused element within the active section

### Architecture Changes

#### 1. FocusSection Modifier

New `ViewModifier` that:
- Registers a section with the FocusManager during rendering
- Provides the section identity to child views via RenderContext

```swift
struct FocusSectionModifier<Content: View>: View {
    let content: Content
    let sectionID: String
}
```

StatusBar items are declared separately via `.statusBarItems(.merge/.replace) { ... }`. The FocusSectionModifier only handles section identity and registration. The StatusBarItemsModifier stores composition mode + items, and the cascading resolution reads them from the active section.

#### 2. StatusBarItemComposition in StatusBarItemsModifier

The existing `StatusBarItemsModifier` gets an additional `composition` parameter:

```swift
struct StatusBarItemsModifier<Content: View>: View {
    let content: Content
    let items: [any StatusBarItemProtocol]
    let composition: StatusBarItemComposition  // NEW: .merge (default) or .replace
}
```

The `context: String?` parameter is removed — context is now determined by the focus section, not by a manual string.

#### 3. FocusManager Extensions

The FocusManager needs:
- A list of registered **sections** (ordered by render sequence)
- The currently **active section** ID
- Methods to cycle between sections (`nextSection()`, `previousSection()`)
- Each section contains its own ordered list of focusable elements
- Tab cycles between sections; within a section, up/down arrows navigate elements

```
FocusManager
  ├── sections: [FocusSection]
  │     ├── FocusSection(id: "playlist", items: [...], composition: .merge)
  │     │     ├── focusables: [MenuItem, MenuItem, ...]
  │     │     └── isActive: true
  │     └── FocusSection(id: "tracklist", items: [...], composition: .merge)
  │           ├── focusables: [MenuItem, MenuItem, ...]
  │           └── isActive: false
  └── activeSectionID: "playlist"
```

#### 4. Breathing Dot Indicator

New framework-level components:

- **`PulseTimer`** — Dedicated `DispatchSourceTimer` that drives the breathing animation independently from Spinner and RenderLoop. Maintains a phase counter (0.0–1.0, sine-based). Calls `setNeedsRender()` on each step change.
- **`Color.lerp(_:_:phase:)`** — RGB linear interpolation between two colors. Used to compute the current breathing color from dimmed (20%) to full accent.
- **`BorderRenderer` changes** — When rendering a border for a view inside an active focus section, the top-left corner is followed by a ● character in the interpolated pulse color instead of the normal horizontal border character.
- **`RenderContext` changes** — Carries the current pulse phase so `BorderRenderer` can read it during rendering without accessing global state.

#### 5. StatusBar Cascading Resolution

When the active focus section changes, the StatusBar resolves items declaratively:

1. Start at the active section.
2. Read the section's declared items and composition mode.
3. If `.replace` → use these items only. Done.
4. If `.merge` → take these items, then walk to parent section.
5. Repeat until root. At each level, merge items (child overrides on shortcut conflict).
6. Final fallback: Global `.statusBarItems()` from the page level.

`.replace` = cascade barrier. `.merge` = transparent, composable.

#### 6. InputHandler Changes

The 4-layer dispatch becomes focus-section-aware:

```
Layer 1: StatusBar (items from ACTIVE focus section, cascaded)
Layer 2: KeyEventDispatcher (handlers from ACTIVE section only)
Layer 3: FocusManager (Tab → switch section, arrows → navigate within)
Layer 4: Default bindings (q, t, a)
```

#### 7. Modal Integration

Modals are natural focus sections. When a modal is presented:
- It creates a focus section that becomes the active section
- Its StatusBar items use `.replace` (ESC→close, not parent's ESC→back)
- Base content sections are inactive (already handled by context isolation)
- When modal closes, previous section regains focus

This eliminates the need for special modal ESC handling — it's just a focus section with `.replace` composition.

## Implementation Steps

- [x] **Step 1: FocusSection registration** — `FocusSection` type, FocusManager tracks sections, `.focusSection()` modifier registers them during rendering
- [x] **Step 2: Section-aware navigation** — Tab cycles sections, Up/Down within active section
- [x] **Step 3: Breathing dot indicator** — `PulseTimer`, `Color.lerp()`, `BorderRenderer` integration, `●` in active section border
- [x] **Step 4: StatusBar cascading** — `StatusBarItemComposition` enum, `.statusBarItems(.merge/.replace)` API, cascading resolution from active section to root
- [x] **Step 5: Modal as FocusSection** — ModalPresentationModifier/AlertPresentationModifier auto-create focus sections with dedicated section IDs
- [x] **Step 6: Example app** — Deferred. Example App will be redesigned as multiple small focused apps (separate effort).
- [x] **Step 7: Tests** — 26 new tests: focus section cycling, StatusBar cascading, Color.lerp, PulseTimer, border indicator

## Decisions Made

- **2026-02-03**: API naming — `addStatusBarItems()` / `setStatusBarItems()` renamed to `.statusBarItems(.merge)` / `.statusBarItems(.replace)` with `StatusBarItemComposition` enum. Reason: The old names were imperative and suggested runtime add/remove behavior. The new API is declarative — it describes composition strategy, not an action.
- **2026-02-03**: Default composition is `.merge` — the common case (section adds items to parent's). `.replace` is the explicit opt-in for modals/clean-slate scenarios.
- **2026-02-03**: `.statusBarItems { ... }` without composition parameter defaults to `.merge`.
- **2026-02-03**: Active section indicator is a **breathing ● dot** rendered inside the section's top border, one position right of the corner. Uses true 16M RGB color interpolation (sine-based fade between 20% and 100% of `palette.accent`). Driven by a dedicated framework-level `PulseTimer`, independent from Spinner and RenderLoop timers.

## Open Questions (for future iterations)

- Should sections support a `defaultFocus` parameter to specify which child gets focus when the section activates?
- How to handle nested focus sections (section within a section)? The cascade model already supports nesting — `.replace` blocks the cascade, `.merge` is transparent.
- Should Tab always cycle sections, or should it be configurable per section?
- When using `.merge` with a shortcut conflict, should the child silently override, or should there be a warning in debug builds?
- ~~Should `focusSection()` visually indicate which section is active?~~ → **Yes. Breathing ● dot in border.**

## Dependencies

- ~~PR #67 (overlays-demo-redesign) should be merged first~~ ✅ Merged 2026-02-03
- FocusManager.dispatchKeyEvent() wiring ✅ Done in PR #67
- Context isolation for modals ✅ Done in PR #67
