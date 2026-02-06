# Palette Reference

A visual reference for all built-in color palettes with their exact color values.

## Overview

TUIkit ships with **6 palettes**: all generated from hand-tuned HSL parameters via ``SystemPalette``. Each palette defines semantic color tokens that the framework resolves at render time.

Users access palette colors via `Color.palette.*`:

```swift
Text("Hello")
    .foregroundColor(.palette.accent)
    .background(.palette.background)
```

Cycle through palettes at runtime by pressing `t` (default binding), or set a specific palette programmatically:

```swift
environment.paletteManager.setCurrent(SystemPalette(.amber))
```

## Palette Protocol

TUIkit uses a single palette protocol:

- **``Palette``**: 13 essential color tokens (8 required, 5 with defaults)

```
Palette (13 properties)
├── Required: background, foreground, accent, border,
│             success, warning, error, info
└── Defaults: statusBarBackground, appHeaderBackground, overlayBackground,
              foregroundSecondary, foregroundTertiary
```

All 6 built-in palettes are instances of ``SystemPalette``, which conforms to ``Palette``. Custom palettes can conform to ``Palette`` directly.

## Color Token Categories

| Category | Tokens | Purpose |
|----------|--------|---------|
| **Background** | `background`, `statusBarBackground`, `appHeaderBackground`, `overlayBackground` | App background, status bar, overlays |
| **Foreground** | `foreground`, `foregroundSecondary`, `foregroundTertiary` | Primary, secondary, and tertiary text |
| **Accent** | `accent` | Interactive elements, highlights |
| **Semantic** | `success`, `warning`, `error`, `info` | Status indicators |
| **UI Elements** | `border` | Borders |

Only 8 tokens are required: the remaining have sensible defaults. See <doc:ThemingGuide> for details on creating custom palettes.

## Green (Default)

Inspired by P1 phosphor CRT monitors (IBM 5151, Apple II). This is the default palette.

**Preset:** ``SystemPalette/Preset/green`` · **ID:** `"green"`

### Core Colors

| Token | Description |
|-------|-------------|
| `background` | Near-black with green tint |
| `foreground` | Classic phosphor green |
| `foregroundSecondary` | Dimmer green |
| `foregroundTertiary` | Subtle green |
| `accent` | Bright green highlight |

### Semantic Colors

| Token | Description |
|-------|-------------|
| `success` | Same hue as foreground |
| `warning` | Yellow-green shift |
| `error` | Orange-red contrast |
| `info` | Cyan-green tint |

### UI Elements

| Token | Description |
|-------|-------------|
| `border` | Dark green |
| `statusBarBackground` | Very dark green |

## Amber

Inspired by P3 phosphor CRT monitors (IBM 3278, Wyse 50). Warm amber tones reminiscent of 1980s terminals.

**Preset:** ``SystemPalette/Preset/amber`` · **ID:** `"amber"`

### Core Colors

| Token | Description |
|-------|-------------|
| `background` | Near-black with warm tint |
| `foreground` | Classic amber phosphor |
| `foregroundSecondary` | Dimmer amber |
| `foregroundTertiary` | Subtle amber |
| `accent` | Bright amber highlight |

### Semantic Colors

| Token | Description |
|-------|-------------|
| `success` | Bright gold |
| `warning` | Light amber |
| `error` | Orange-red contrast |
| `info` | Warm yellow |

## White

Inspired by P4 phosphor CRT monitors (DEC VT100, VT220). Clean monochrome with cool undertones.

**Preset:** ``SystemPalette/Preset/white`` · **ID:** `"white"`

### Core Colors

| Token | Description |
|-------|-------------|
| `background` | Near-black with blue tint |
| `foreground` | Off-white text |
| `foregroundSecondary` | Light gray |
| `foregroundTertiary` | Medium gray |
| `accent` | Pure white highlight |

### Semantic Colors

| Token | Description |
|-------|-------------|
| `success` | Pastel green |
| `warning` | Pastel amber |
| `error` | Pastel red |
| `info` | Pastel blue |

## Red

Inspired by military and night-vision-friendly displays. Preserves scotopic (night) vision.

**Preset:** ``SystemPalette/Preset/red`` · **ID:** `"red"`

### Core Colors

| Token | Description |
|-------|-------------|
| `background` | Near-black with red tint |
| `foreground` | Bright red text |
| `foregroundSecondary` | Dimmer red |
| `foregroundTertiary` | Subtle red |
| `accent` | Light red highlight |

### Semantic Colors

| Token | Description |
|-------|-------------|
| `success` | Light red (brighter = positive) |
| `warning` | Orange tint |
| `error` | Pure white (maximum contrast) |
| `info` | Soft pink |

## Violet

An algorithmically generated palette based on HSL color theory with a base hue of 270°. All colors are derived from this single hue using saturation and lightness variations.

**Preset:** ``SystemPalette/Preset/violet`` · **ID:** `"violet"`

### How the Violet Preset Works

The violet preset takes a base hue (270°) and derives all color tokens using HSL relationships:

- **Background**: Base hue at very low lightness (3%) with reduced saturation
- **Foregrounds**: Base hue at medium-high lightness (40–70%)
- **Accent**: Base hue at high lightness (78%) with high saturation
- **Semantic colors**: Derived from color theory offsets:
  - `success` = base + 120° (triadic)
  - `warning` = base + 60° (analogous warm)
  - `error` = base + 180° (complementary)
  - `info` = base − 60° (analogous cool)

### Violet Token Values

| Token | HSL | Description |
|-------|-----|-------------|
| `background` | hsl(270, 30%, 3%) | Near-black with violet tint |
| `foreground` | hsl(270, 80%, 70%) | Light violet text |
| `foregroundSecondary` | hsl(270, 70%, 55%) | Medium violet |
| `foregroundTertiary` | hsl(270, 60%, 40%) | Dim violet |
| `accent` | hsl(270, 85%, 78%) | Bright lavender |
| `success` | hsl(30, 70%, 65%) | Warm orange (270+120=30°) |
| `warning` | hsl(330, 80%, 70%) | Pink (270+60=330°) |
| `error` | hsl(90, 85%, 65%) | Lime green (270+180=90°) |
| `info` | hsl(210, 70%, 70%) | Sky blue (270−60=210°) |
| `border` | hsl(270, 40%, 25%) | Dark purple border |
| `statusBarBackground` | hsl(270, 35%, 8%) | Very dark violet |

## Blue

Inspired by vintage vacuum fluorescent displays (VFDs). The characteristic bright cyan-blue glow.

**Preset:** ``SystemPalette/Preset/blue`` · **ID:** `"blue"`

### Core Colors

| Token | Description |
|-------|-------------|
| `background` | Near-black with blue tint |
| `foreground` | Bright VFD blue |
| `foregroundSecondary` | Medium blue |
| `foregroundTertiary` | Dim blue |
| `accent` | Lighter blue highlight |

### Semantic Colors

| Token | Description |
|-------|-------------|
| `success` | Cyan-blue |
| `warning` | Light cyan |
| `error` | Orange-red contrast |
| `info` | Pale blue |

## Palette Cycling Order

When pressing `t` to cycle themes, palettes rotate in this order:

| # | Palette | Preset |
|---|---------|--------|
| 1 | Green (default) | `.green` |
| 2 | Amber | `.amber` |
| 3 | Red | `.red` |
| 4 | Violet | `.violet` |
| 5 | Blue | `.blue` |
| 6 | White | `.white` |

## Color Resolution Flow

When you write `.foregroundColor(.palette.accent)`, TUIkit resolves the actual color at render time:

1. **Declaration**: `Color.palette.accent` creates a `Color` with a semantic token (`.accent`)
2. **Render pass**: The current palette is read from `context.environment.palette`
3. **Resolution**: The semantic token maps to the palette's `accent` property
4. **ANSI output**: The resolved RGB color is converted to terminal escape codes

This means the same view code produces different colors depending on the active palette: no code changes needed when switching themes.

## Topics

### Protocols

- ``Palette``

### Palettes

- ``SystemPalette``

### Color System

- ``Color``
- ``TextStyle``

### Theme Management

- ``ThemeManager``
