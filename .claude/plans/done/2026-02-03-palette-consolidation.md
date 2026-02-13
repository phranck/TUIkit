# Palette Consolidation: Replace 6 Palette Structs with SystemPalette.Preset Enum

## Preface

Six palette files are consolidated into one: a `SystemPalette.Preset` enum with `.green`, `.amber`, `.red`, `.violet`, `.blue`, `.white` cases, backed by hand-tuned HSL parameters. All boilerplate (init, color generation, helpers) is shared; only the tuning data differs. Six files → one file, 545 LOC → 150 LOC. Convenience accessors like `BlockPalette.amber` still work, user-defined custom palettes still conform to `Palette` normally.

## Completed

**0: PR #70 merged. Six palette files consolidated into single `SystemPalette.Preset` enum with shared implementation.

## Problem

Six separate palette files (`GreenPalette`, `AmberPalette`, `RedPalette`, `VioletPalette`, `BluePalette`, `WhitePalette`) contain ~85% identical boilerplate:
- Same 13 stored properties
- Same init structure
- Same `wrapHue()` helper (5 of 6 files)
- Same convenience accessor pattern
- Only actual difference: HSL tuning values per preset

Total: ~545 LOC across 6 files. Estimated after: ~150 LOC in 1 file.

## Solution

### New: `SystemPalette.Preset` enum + `SystemPalette` struct

```swift
/// Built-in palette presets inspired by classic terminal phosphors.
public enum SystemPalette.Preset: String, CaseIterable, Sendable {
    case green, amber, red, violet, blue, white
}
```

A single `SystemPalette: BlockPalette` struct that takes a `SystemPalette.Preset` and produces all colors from an internal `Tuning` struct containing the hand-tuned HSL parameters.

### What stays the same

- `Palette` protocol. Uunchanged
- `BlockPalette` protocol. Uunchanged
- `Cyclable` protocol. Uunchanged
- `ThemeManager`. Uunchanged (works with `any Cyclable`)
- `SemanticColor`. Uunchanged (resolves against `any Palette`)
- Custom user palettes. Ustill conform to `Palette` or `BlockPalette` directly

### What changes

1. **Delete**: 6 palette files in `Sources/TUIkit/Styling/Palettes/`
2. **New**: `PalettePreset.swift` in `Sources/TUIkit/Styling/Palettes/`. Uenum + SystemPalette + tuning data
3. **Update**: `PaletteRegistry` in `Theme.swift`. Ubuild from `SystemPalette.Preset.allCases`
4. **Update**: `PaletteKey` default. Uuse `SystemPalette(.green)`
5. **Update**: Doc comments referencing `GreenPalette()` etc. → `SystemPalette(.green)`
6. **Update**: Convenience accessors on `BlockPalette`: `.green`, `.amber`, `.default` etc.
7. **Update**: Tests. Ureplace concrete palette types with `SystemPalette(.xxx)`

### Convenience API

```swift
// Before
let palette = GreenPalette()
paletteManager.setCurrent(AmberPalette())

// After
let palette = SystemPalette(.green)
paletteManager.setCurrent(SystemPalette(.amber))

// Convenience accessors still work
BlockPalette.default  // → SystemPalette(.green)
BlockPalette.amber    // → SystemPalette(.amber)
```

## Checklist

- [x] Create feature branch `refactor/palette-consolidation`
- [x] Implement `SystemPalette.Preset` enum and `SystemPalette` struct
- [x] Update `PaletteRegistry` to use `SystemPalette.Preset.allCases`
- [x] Update `PaletteKey` default value
- [x] Migrate convenience accessors
- [x] Update doc comments in Theme.swift, ThemeManager.swift, View+Environment.swift
- [x] Delete 6 individual palette files
- [x] Migrate tests (4 test files)
- [x] `swift build` + `swiftlint` + `swift test`
- [x] Create PR
