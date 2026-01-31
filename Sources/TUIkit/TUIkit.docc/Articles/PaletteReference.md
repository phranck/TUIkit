# Palette Reference

A visual reference for all built-in color palettes with their exact color values.

## Overview

TUIkit ships with **7 palettes** — 5 handcrafted phosphor themes, 1 classic ncurses theme, and 1 violet theme generated from a single base hue. Each palette defines semantic color tokens that the framework resolves at render time.

Users access palette colors via `Color.palette.*`:

```swift
Text("Hello")
    .foregroundColor(.palette.accent)
    .background(.palette.containerBodyBackground)
```

Cycle through palettes at runtime by pressing `t` (default binding), or set a specific palette programmatically:

```swift
environment.paletteManager.setCurrent(AmberPalette())
```

## Color Token Categories

Every palette must define colors for these 6 categories:

| Category | Tokens | Purpose |
|----------|--------|---------|
| **Background** | `background`, `containerBodyBackground`, `containerCapBackground`, `buttonBackground`, `statusBarBackground`, `appHeaderBackground`, `overlayBackground` | App background, container body/cap, buttons, status bar, overlays |
| **Foreground** | `foreground`, `foregroundSecondary`, `foregroundTertiary` | Primary, secondary, and tertiary text |
| **Accent** | `accent`, `accentSecondary` | Interactive elements, highlights |
| **Semantic** | `success`, `warning`, `error`, `info` | Status indicators |
| **UI Elements** | `border` | Borders |

Only 10 tokens are required — the remaining 8 have sensible defaults derived from the required ones. See <doc:ThemingGuide> for details on creating custom palettes.

## Green (Default)

Inspired by P1 phosphor CRT monitors (IBM 5151, Apple II). This is the default palette.

**Palette type:** ``GreenPalette`` · **ID:** `"green"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#060A07` | (6, 10, 7) | Near-black with green tint |
| `containerBodyBackground` | `#0E271C` | (14, 39, 28) | Container content area |
| `containerCapBackground` | `#0A1B13` | (10, 27, 19) | Container header/footer |
| `foreground` | `#33FF33` | (51, 255, 51) | Classic phosphor green |
| `foregroundSecondary` | `#27C227` | (39, 194, 39) | Dimmer green |
| `foregroundTertiary` | `#1F8F1F` | (31, 143, 31) | Subtle green |
| `accent` | `#66FF66` | (102, 255, 102) | Bright green highlight |
| `accentSecondary` | `#00CC00` | (0, 204, 0) | Medium green |

### Semantic Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `success` | `#33FF33` | (51, 255, 51) | Same as foreground |
| `warning` | `#CCFF33` | (204, 255, 51) | Yellow-green shift |
| `error` | `#FF6633` | (255, 102, 51) | Orange-red contrast |
| `info` | `#33FFCC` | (51, 255, 204) | Cyan-green tint |

### UI Elements

| Token | Hex | RGB |
|-------|-----|-----|
| `border` | `#2D5A2D` | (45, 90, 45) |
| `statusBarBackground` | `#0F2215` | (15, 34, 21) |
| `buttonBackground` | `#145523` | (20, 85, 35) |

## Amber

Inspired by P3 phosphor CRT monitors (IBM 3278, Wyse 50). Warm amber tones reminiscent of 1980s terminals.

**Palette type:** ``AmberPalette`` · **ID:** `"amber"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#0A0706` | (10, 7, 6) | Near-black with warm tint |
| `containerBodyBackground` | `#251710` | (37, 23, 16) | Container content area |
| `containerCapBackground` | `#1E110E` | (30, 17, 14) | Container header/footer |
| `foreground` | `#FFAA00` | (255, 170, 0) | Classic amber phosphor |
| `foregroundSecondary` | `#CC8800` | (204, 136, 0) | Dimmer amber |
| `foregroundTertiary` | `#8F6600` | (143, 102, 0) | Subtle amber |
| `accent` | `#FFCC33` | (255, 204, 51) | Bright amber highlight |
| `accentSecondary` | `#CC9900` | (204, 153, 0) | Medium amber |

### Semantic Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `success` | `#FFCC00` | (255, 204, 0) | Bright gold |
| `warning` | `#FFE066` | (255, 224, 102) | Light amber |
| `error` | `#FF6633` | (255, 102, 51) | Orange-red contrast |
| `info` | `#FFD966` | (255, 217, 102) | Warm yellow |

### UI Elements

| Token | Hex | RGB |
|-------|-----|-----|
| `border` | `#5A4A2D` | (90, 74, 45) |
| `statusBarBackground` | `#191613` | (25, 22, 19) |
| `buttonBackground` | `#3A2A1D` | (58, 42, 29) |

## White

Inspired by P4 phosphor CRT monitors (DEC VT100, VT220). Clean monochrome with cool undertones.

**Palette type:** ``WhitePalette`` · **ID:** `"white"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#06070A` | (6, 7, 10) | Near-black with blue tint |
| `containerBodyBackground` | `#111A2A` | (17, 26, 42) | Container content area |
| `containerCapBackground` | `#0D131D` | (13, 19, 29) | Container header/footer |
| `foreground` | `#E8E8E8` | (232, 232, 232) | Off-white text |
| `foregroundSecondary` | `#B0B0B0` | (176, 176, 176) | Light gray |
| `foregroundTertiary` | `#787878` | (120, 120, 120) | Medium gray |
| `accent` | `#FFFFFF` | (255, 255, 255) | Pure white highlight |
| `accentSecondary` | `#C0C0C0` | (192, 192, 192) | Silver |

### Semantic Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `success` | `#C0FFC0` | (192, 255, 192) | Pastel green |
| `warning` | `#FFE0A0` | (255, 224, 160) | Pastel amber |
| `error` | `#FFA0A0` | (255, 160, 160) | Pastel red |
| `info` | `#A0D0FF` | (160, 208, 255) | Pastel blue |

### UI Elements

| Token | Hex | RGB |
|-------|-----|-----|
| `border` | `#484848` | (72, 72, 72) |
| `statusBarBackground` | `#131619` | (19, 22, 25) |
| `buttonBackground` | `#1D2535` | (29, 37, 53) |

## Red

Inspired by military and night-vision-friendly displays. Preserves scotopic (night) vision.

**Palette type:** ``RedPalette`` · **ID:** `"red"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#0A0606` | (10, 6, 6) | Near-black with red tint |
| `containerBodyBackground` | `#281112` | (40, 17, 18) | Container content area |
| `containerCapBackground` | `#1E0F10` | (30, 15, 16) | Container header/footer |
| `foreground` | `#FF4444` | (255, 68, 68) | Bright red text |
| `foregroundSecondary` | `#CC3333` | (204, 51, 51) | Dimmer red |
| `foregroundTertiary` | `#8F2222` | (143, 34, 34) | Subtle red |
| `accent` | `#FF6666` | (255, 102, 102) | Light red highlight |
| `accentSecondary` | `#CC4444` | (204, 68, 68) | Medium red |

### Semantic Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `success` | `#FF8080` | (255, 128, 128) | Light red (brighter = positive) |
| `warning` | `#FFAA66` | (255, 170, 102) | Orange tint |
| `error` | `#FFFFFF` | (255, 255, 255) | Pure white (maximum contrast) |
| `info` | `#FF9999` | (255, 153, 153) | Soft pink |

### UI Elements

| Token | Hex | RGB |
|-------|-----|-----|
| `border` | `#5A2D2D` | (90, 45, 45) |
| `statusBarBackground` | `#191313` | (25, 19, 19) |
| `buttonBackground` | `#3A1F22` | (58, 31, 34) |

## ncurses

Classic ncurses terminal colors (htop, Midnight Commander, vim). The only palette using standard ANSI colors instead of RGB — maximum compatibility with 16-color terminals.

**Palette type:** ``NCursesPalette`` · **ID:** `"ncurses"`

### Core Colors

| Token | ANSI Color | Code | Description |
|-------|-----------|------|-------------|
| `background` | Black | 30/40 | Terminal default black |
| `containerBodyBackground` | Blue | 34/44 | Classic ncurses panel blue |
| `containerCapBackground` | Bright Black | 90/100 | Dark gray |
| `foreground` | White | 37/47 | Standard white |
| `foregroundSecondary` | Bright White | 97/107 | Brighter white |
| `foregroundTertiary` | Bright Black | 90/100 | Gray (dimmed) |
| `accent` | Cyan | 36/46 | Primary interactive color |
| `accentSecondary` | Bright Cyan | 96/106 | Highlighted interactive |

### Semantic Colors

| Token | ANSI Color | Code | Description |
|-------|-----------|------|-------------|
| `success` | Green | 32/42 | Standard green |
| `warning` | Yellow | 33/43 | Standard yellow |
| `error` | Red | 31/41 | Standard red |
| `info` | Cyan | 36/46 | Same as accent |

### UI Elements

| Token | ANSI Color | Code |
|-------|-----------|------|
| `border` | White | 37/47 |
| `statusBarBackground` | Blue | 34/44 |
| `buttonBackground` | Bright Blue | 94/104 |

> Tip: Use the ncurses palette when targeting terminals with limited color support (SSH sessions, older terminal emulators, or 16-color environments).

## Violet

An algorithmically generated palette based on HSL color theory with a base hue of 270°. All colors are derived from this single hue using saturation and lightness variations.

**Palette type:** ``VioletPalette`` · **ID:** `"violet"`

### How VioletPalette Works

``VioletPalette`` takes a base hue (270°) and derives all color tokens using HSL relationships:

- **Backgrounds** — Base hue at very low lightness (3–10%) with reduced saturation
- **Foregrounds** — Base hue at medium-high lightness (40–70%)
- **Accents** — Base hue at high lightness (78%) with high saturation
- **Semantic colors** — Derived from color theory offsets:
  - `success` = base + 120° (triadic)
  - `warning` = base + 60° (analogous warm)
  - `error` = base + 180° (complementary)
  - `info` = base − 60° (analogous cool)

### Violet Token Values

| Token | HSL | Description |
|-------|-----|-------------|
| `background` | hsl(270, 30%, 3%) | Near-black with violet tint |
| `containerBodyBackground` | hsl(270, 40%, 10%) | Container content area |
| `containerCapBackground` | hsl(270, 35%, 7%) | Container header/footer |
| `foreground` | hsl(270, 80%, 70%) | Light violet text |
| `foregroundSecondary` | hsl(270, 70%, 55%) | Medium violet |
| `foregroundTertiary` | hsl(270, 60%, 40%) | Dim violet |
| `accent` | hsl(270, 85%, 78%) | Bright lavender |
| `accentSecondary` | hsl(270, 75%, 50%) | Medium purple |
| `success` | hsl(30, 70%, 65%) | Warm orange (270+120=30°) |
| `warning` | hsl(330, 80%, 70%) | Pink (270+60=330°) |
| `error` | hsl(90, 85%, 65%) | Lime green (270+180=90°) |
| `info` | hsl(210, 70%, 70%) | Sky blue (270−60=210°) |
| `border` | hsl(270, 40%, 25%) | Dark purple border |
| `statusBarBackground` | hsl(270, 35%, 8%) | Very dark violet |
| `buttonBackground` | hsl(270, 45%, 15%) | Dark purple |

## Palette Cycling Order

When pressing `t` to cycle themes, palettes rotate in this order:

| # | Palette | Type |
|---|---------|------|
| 1 | Green (default) | Handcrafted |
| 2 | Amber | Handcrafted |
| 3 | Red | Handcrafted |
| 4 | Violet | HSL-generated (hue 270°) |
| 5 | Blue | Handcrafted (VFD) |
| 6 | White | Handcrafted |
| 7 | ncurses | Handcrafted (ANSI) |

## Color Resolution Flow

When you write `.foregroundColor(.palette.accent)`, TUIkit resolves the actual color at render time:

1. **Declaration** — `Color.palette.accent` creates a `Color` with a semantic token (`.accent`)
2. **Render pass** — The current palette is read from `context.environment.palette`
3. **Resolution** — The semantic token maps to the palette's `accent` property
4. **ANSI output** — The resolved RGB/ANSI color is converted to terminal escape codes

This means the same view code produces different colors depending on the active palette — no code changes needed when switching themes.

## Topics

### Palettes

- ``Palette``
- ``GreenPalette``
- ``AmberPalette``
- ``RedPalette``
- ``VioletPalette``
- ``BluePalette``
- ``WhitePalette``
- ``NCursesPalette``

### Color System

- ``Color``
- ``TextStyle``

### Theme Management

- ``ThemeManager``
