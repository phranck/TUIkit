# Remove Block/Flat Appearances: Simplify to Border-Only Rendering

## Preface

Block and Flat appearances are both removed (36 files changed). The framework now offers four border-based appearances: line, rounded, doubleLine, heavy. Uall using standard Unicode box-drawing characters. Surface color tokens are consolidated into `Palette` directly (no more `BlockPalette` protocol). Simplified architecture, eliminated half-block complexity that broke on many terminals, and gained universal compatibility using only ANSI backgrounds and standard borders.

## Completed

**0: Both Block and Flat were removed entirely. The framework now has 4 standard border-based appearances only (line, rounded, doubleLine, heavy). BorderStyle.ascii was also removed. Surface color tokens consolidated into Palette. 36 files changed, +225 / −1140 lines. 526 tests passing.

## Checklist

- [x] Move surface colors from BlockPalette into Palette
- [x] Remove BlockPalette protocol entirely
- [x] Change SystemPalette: BlockPalette → SystemPalette: Palette
- [x] Remove Palette convenience accessors for block colors
- [x] Update SemanticColor to use Palette directly (no cast)
- [x] Rename Appearance.block → Appearance.flat
- [x] Remove BorderStyle.block, .blockBottomHorizontal, .blockFooterSeparator
- [x] Set Appearance.flat to use BorderStyle.none
- [x] Update AppearanceRegistry and cycling order
- [x] Remove BorderRenderer block methods
- [x] Add flatContentLine helper
- [x] Rewrite BorderModifier renderFlatStyle
- [x] Rewrite ContainerView renderFlatStyle
- [x] Rewrite StatusBar renderFlat
- [x] Rewrite AppHeader renderFlat
- [x] Rewrite Menu flat branch
- [x] Clean up DimmedModifier ornament set
- [x] Rename BlockThemePage → FlatThemePage
- [x] Update all tests and doc comments
- [x] Full swift build + swiftlint + swift test (536 tests passing)

## Original Goal

Replace the fragile Block Appearance (half-block Unicode characters `▄▀█` that break across terminals) with a simpler **Flat Appearance**: same colored background surfaces from the theme palette, but **no borders at all**. Pure ANSI background fills.

## Design

### What stays

- **Three surface color tokens**: `surfaceBackground`, `surfaceHeaderBackground`, `elevatedBackground`. Uthese define the visual hierarchy and are the core of the "flat" look.
- **Color hierarchy**: background (darkest) → surfaceHeaderBackground → surfaceBackground → elevatedBackground (brightest).
- **Per-view section coloring**: ContainerView header/footer use `surfaceHeaderBackground`, body uses `surfaceBackground`. Buttons use `elevatedBackground`.

### What changes

| Aspect | Block (old) | Flat (new) |
|--------|-------------|------------|
| Border characters | `▄▀█` half/full blocks | None: `BorderStyle.none` (spaces) |
| Section transitions | `blockSeparator` with FG/BG trick | No separator. Usections distinguished by background color only |
| Side borders | `█` full blocks | No side borders. Ucontent fills full width with background color |
| Top/bottom edges | `▄▄▄` / `▀▀▀` rows | No edge rows. Ubackground starts/ends with content |
| Terminal compat | Broken in many terminals | Universal. Uonly requires ANSI background color support |

### What gets removed

- `BlockPalette` protocol. Uthe 3 color properties move into `Palette` directly
- `BorderStyle.block` preset + `blockBottomHorizontal` + `blockFooterSeparator` statics
- `BorderRenderer` block methods: `blockTopBorder`, `blockBottomBorder`, `blockContentLine`, `blockSeparator`
- All `appearance.rawId == .block` branches in views. Ureplaced with `== .flat` branches
- `BlockThemePage.swift` example page. Ureplace with `FlatThemePage.swift` or integrate into existing demo

### Migration: `BlockPalette` → `Palette`

Move the 3 surface color properties from `BlockPalette` into `Palette`:

```swift
// Before: separate protocol
protocol BlockPalette: Palette {
    var surfaceBackground: Color { get }
    var surfaceHeaderBackground: Color { get }
    var elevatedBackground: Color { get }
}

// After: integrated into Palette with defaults
protocol Palette {
    // ... existing 13 properties ...
    var surfaceBackground: Color { get }       // default: background.lighter(by: 0.10)
    var surfaceHeaderBackground: Color { get }  // default: background.lighter(by: 0.07)
    var elevatedBackground: Color { get }       // default: surfaceHeaderBackground.lighter(by: 0.08)
}
```

This eliminates the `as? BlockPalette` casts and fallbacks throughout the codebase.

### Flat Rendering: Per Component

All flat-rendered sections use **1 character horizontal padding** (left and right) so content doesn't stick to the edges. This replaces the `█` side borders from block rendering with simple space padding inside the background fill.

**ContainerView:**
- Header lines: persistent background = `surfaceHeaderBackground`, 1-char padding left/right. No top border row.
- Body lines: persistent background = `surfaceBackground`, 1-char padding left/right. No side borders.
- Footer lines: persistent background = `surfaceHeaderBackground`, 1-char padding left/right. No bottom border row.
- No separator rows between sections. Ucolor change alone provides visual distinction.

**BorderModifier (Box, `.border()`):**
- All content lines: persistent background = `surfaceBackground`, 1-char padding left/right.
- No border rows or side characters.

**Button:**
- Padded label with persistent background = `elevatedBackground`.
- No `[` `]` brackets. Same as block, just without the block characters.

**StatusBar:**
- Full-width content with persistent background = `statusBarBackground`, 1-char padding left/right.
- No border rows.

**AppHeader:**
- Full-width content with persistent background = `appHeaderBackground`, 1-char padding left/right.
- Bottom divider: thin line using `─` (standard divider, not `▀`), or no divider at all: TBD.

**Menu:**
- Header lines: persistent background = `surfaceHeaderBackground`, 1-char padding left/right.
- Item lines: persistent background = `surfaceBackground`, 1-char padding left/right.
- No separator row.

## Steps

## Completed: 2026-02-05

### Phase 1: Palette Refactoring

- [x] Move `surfaceBackground`, `surfaceHeaderBackground`, `elevatedBackground` from `BlockPalette` into `Palette` with default implementations
- [x] Remove `BlockPalette` protocol entirely
- [x] Change `SystemPalette: BlockPalette` → `SystemPalette: Palette`
- [x] Remove `Palette` convenience accessors (`blockSurfaceBackground` etc.). Uuse direct property access
- [x] Update `SemanticColor`. Ukeep the 3 surface cases, simplify `resolve()` to use `Palette` directly (no cast)
- [x] Keep `Color.Semantic` accessors. Urenamed comments from "BlockPalette" to "Surface"
- [x] Update related tests

### Phase 2: Appearance & BorderStyle Cleanup

- [x] Rename `Appearance.block` → `Appearance.flat` (keep same registry slot)
- [x] Remove `BorderStyle.block`, `.blockBottomHorizontal`, `.blockFooterSeparator`
- [x] Set `Appearance.flat` to use `BorderStyle.none`
- [x] Update `AppearanceRegistry` and cycling order
- [x] Update `AppearanceTests`

### Phase 3: Rendering Simplification

- [x] Remove `BorderRenderer` block methods (4 methods)
- [x] Add `flatContentLine(content:innerWidth:backgroundColor:)`. Upersistent BG + 1-char padding
- [x] Rewrite `BorderModifier` → `renderFlatStyle` (background-only, no borders)
- [x] Rewrite `ContainerView` → `renderFlatStyle` (header/body/footer sections)
- [x] Rewrite `Button` flat branch (rename check only)
- [x] Rewrite `StatusBar` → `renderFlatBordered` (single background line)
- [x] Rewrite `AppHeader` → `renderFlat` (background + thin `─` divider)
- [x] Rewrite `Menu` flat branch (section-aware coloring, skip divider)
- [x] Clean up `DimmedModifier` ornament set (removed `▄▀█▌▐`)

### Phase 4: Example App & Tests

- [x] Rename `BlockThemePage` → `FlatThemePage`
- [x] Replace `BorderRendererBlockTests` with `BorderRendererFlatTests` (3 tests)
- [x] Update `PaletteDefaultTests` → `PaletteSurfaceDefaultTests`
- [x] Update `PredefinedPaletteTests`. Urenamed luminance order tests
- [x] Full `swift build` + `swiftlint` + `swift test`: 536 tests / 88 suites passing

### Phase 5: Cleanup

- [x] Grep for "block" references in Sources/ and Tests/. Uupdated 11 doc comments
- [x] PR (pending)

## Risk Assessment

- **Low risk**: The rendering is simpler than what it replaces. ANSI background colors work everywhere.
- **Migration**: Purely internal refactoring. No public API surface changes beyond renaming `.block` → `.flat`.
- **Visual difference**: Flat will look slightly different from Block. Uno smooth half-block transitions. But that's the point: simpler, universal, still visually distinct from bordered appearances.
