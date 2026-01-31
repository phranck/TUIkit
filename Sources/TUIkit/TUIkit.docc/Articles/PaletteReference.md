# Palette Reference

A visual reference for all built-in color palettes with their exact color values.

## Overview

TUIkit ships with **7 palettes** — 5 handcrafted phosphor themes, 1 classic ncurses theme, and 1 algorithmically generated theme. Each palette defines 24 semantic color tokens that the framework resolves at render time.

Users access palette colors via `Color.palette.*`:

```swift
Text("Hello")
    .foregroundColor(.palette.accent)
    .background(.palette.backgroundSecondary)
```

Cycle through palettes at runtime by pressing `t` (default binding), or set a specific palette programmatically:

```swift
environment.paletteManager.setCurrent(AmberPalette())
```

## Color Token Categories

Every palette must define colors for these 6 categories:

| Category | Tokens | Purpose |
|----------|--------|---------|
| **Background** | `background`, `backgroundSecondary`, `backgroundTertiary` | App background, containers, nested elements |
| **Foreground** | `foreground`, `foregroundSecondary`, `foregroundTertiary` | Primary, secondary, and tertiary text |
| **Accent** | `accent`, `accentSecondary` | Interactive elements, highlights |
| **Semantic** | `success`, `warning`, `error`, `info` | Status indicators |
| **UI Elements** | `border`, `borderFocused`, `separator`, `selection`, `selectionBackground`, `disabled` | Borders, dividers, selection states |
| **Component** | `statusBar*`, `container*`, `buttonBackground` | Status bar, container headers/bodies, buttons |

Only 8 tokens are required — the remaining 16 have sensible defaults derived from the required ones. See <doc:ThemingGuide> for details on creating custom palettes.

## Green (Default)

Inspired by P1 phosphor CRT monitors (IBM 5151, Apple II). This is the default palette.

**Palette type:** ``GreenPalette`` · **ID:** `"green"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#060A07` | (6, 10, 7) | Near-black with green tint |
| `backgroundSecondary` | `#0E271C` | (14, 39, 28) | Dark green for containers |
| `backgroundTertiary` | `#0A1B13` | (10, 27, 19) | Nested elements |
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
| `borderFocused` | `#33FF33` | (51, 255, 51) |
| `selection` | `#66FF66` | (102, 255, 102) |
| `selectionBackground` | `#1A4D1A` | (26, 77, 26) |
| `statusBarBackground` | `#0F2215` | (15, 34, 21) |
| `statusBarForeground` | `#2FDD2F` | (47, 221, 47) |
| `statusBarHighlight` | `#66FF66` | (102, 255, 102) |
| `buttonBackground` | `#145523` | (20, 85, 35) |

## Amber

Inspired by P3 phosphor CRT monitors (IBM 3278, Wyse 50). Warm amber tones reminiscent of 1980s terminals.

**Palette type:** ``AmberPalette`` · **ID:** `"amber"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#0A0706` | (10, 7, 6) | Near-black with warm tint |
| `backgroundSecondary` | `#251710` | (37, 23, 16) | Dark amber for containers |
| `backgroundTertiary` | `#1E110E` | (30, 17, 14) | Nested elements |
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
| `borderFocused` | `#FFAA00` | (255, 170, 0) |
| `selection` | `#FFCC33` | (255, 204, 51) |
| `selectionBackground` | `#4D3A1F` | (77, 58, 31) |
| `statusBarBackground` | `#191613` | (25, 22, 19) |
| `statusBarForeground` | `#FFAA00` | (255, 170, 0) |
| `statusBarHighlight` | `#FFCC33` | (255, 204, 51) |
| `buttonBackground` | `#3A2A1D` | (58, 42, 29) |

## White

Inspired by P4 phosphor CRT monitors (DEC VT100, VT220). Clean monochrome with cool undertones.

**Palette type:** ``WhitePalette`` · **ID:** `"white"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#06070A` | (6, 7, 10) | Near-black with blue tint |
| `backgroundSecondary` | `#111A2A` | (17, 26, 42) | Dark blue for containers |
| `backgroundTertiary` | `#0D131D` | (13, 19, 29) | Nested elements |
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
| `borderFocused` | `#E8E8E8` | (232, 232, 232) |
| `selection` | `#FFFFFF` | (255, 255, 255) |
| `selectionBackground` | `#3A3A3A` | (58, 58, 58) |
| `statusBarBackground` | `#131619` | (19, 22, 25) |
| `statusBarForeground` | `#DCDCDC` | (220, 220, 220) |
| `statusBarHighlight` | `#FFFFFF` | (255, 255, 255) |
| `buttonBackground` | `#1D2535` | (29, 37, 53) |

## Red

Inspired by military and night-vision-friendly displays. Preserves scotopic (night) vision.

**Palette type:** ``RedPalette`` · **ID:** `"red"`

### Core Colors

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| `background` | `#0A0606` | (10, 6, 6) | Near-black with red tint |
| `backgroundSecondary` | `#281112` | (40, 17, 18) | Dark red for containers |
| `backgroundTertiary` | `#1E0F10` | (30, 15, 16) | Nested elements |
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
| `borderFocused` | `#FF4444` | (255, 68, 68) |
| `selection` | `#FF6666` | (255, 102, 102) |
| `selectionBackground` | `#4D1F1F` | (77, 31, 31) |
| `statusBarBackground` | `#191313` | (25, 19, 19) |
| `statusBarForeground` | `#F23B3B` | (242, 59, 59) |
| `statusBarHighlight` | `#FF6666` | (255, 102, 102) |
| `buttonBackground` | `#3A1F22` | (58, 31, 34) |

## ncurses

Classic ncurses terminal colors (htop, Midnight Commander, vim). The only palette using standard ANSI colors instead of RGB — maximum compatibility with 16-color terminals.

**Palette type:** ``NCursesPalette`` · **ID:** `"ncurses"`

### Core Colors

| Token | ANSI Color | Code | Description |
|-------|-----------|------|-------------|
| `background` | Black | 30/40 | Terminal default black |
| `backgroundSecondary` | Blue | 34/44 | Classic ncurses panel blue |
| `backgroundTertiary` | Bright Black | 90/100 | Dark gray |
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
| `borderFocused` | Bright Cyan | 96/106 |
| `selection` | Bright Cyan | 96/106 |
| `selectionBackground` | Blue | 34/44 |
| `disabled` | Bright Black | 90/100 |
| `statusBarBackground` | Blue | 34/44 |
| `statusBarForeground` | White | 37/47 |
| `statusBarHighlight` | Yellow | 33/43 |
| `buttonBackground` | Bright Blue | 94/104 |

> Tip: Use the ncurses palette when targeting terminals with limited color support (SSH sessions, older terminal emulators, or 16-color environments).

## Violet (Generated)

An algorithmically generated palette based on HSL color theory. Demonstrates the ``GeneratedPalette`` system.

**Palette type:** ``GeneratedPalette`` · **Hue:** 270° · **ID:** `"generated-violet"`

### How Generated Palettes Work

``GeneratedPalette`` takes a base hue (0–360°) and derives all 24 color tokens using HSL relationships:

- **Backgrounds** — Base hue at very low lightness (3–10%) with reduced saturation
- **Foregrounds** — Base hue at medium-high lightness (40–70%)
- **Accents** — Base hue at high lightness (78%) with high saturation
- **Semantic colors** — Derived from color theory offsets:
  - `success` = base + 120° (triadic)
  - `warning` = base + 60° (analogous warm)
  - `error` = base + 180° (complementary)
  - `info` = base − 60° (analogous cool)

### Violet Token Values

All values shown at default saturation (100%):

| Token | HSL | Description |
|-------|-----|-------------|
| `background` | hsl(270, 30%, 3%) | Near-black with violet tint |
| `backgroundSecondary` | hsl(270, 40%, 10%) | Dark violet |
| `backgroundTertiary` | hsl(270, 35%, 7%) | Nested elements |
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
| `borderFocused` | hsl(270, 80%, 70%) | Bright violet |
| `selection` | hsl(270, 85%, 78%) | Lavender |
| `selectionBackground` | hsl(270, 50%, 18%) | Dark violet |
| `statusBarBackground` | hsl(270, 35%, 8%) | Very dark violet |
| `statusBarForeground` | hsl(270, 75%, 65%) | Medium-bright violet |
| `statusBarHighlight` | hsl(270, 85%, 78%) | Bright lavender |
| `buttonBackground` | hsl(270, 45%, 15%) | Dark purple |

### Creating Custom Generated Palettes

```swift
// Create a palette from any hue
let oceanPalette = GeneratedPalette(name: "Ocean", hue: 200)

// Reduce saturation for a more muted look
let mutedPalette = GeneratedPalette(name: "Muted", hue: 200, saturation: 60)
```

## Palette Cycling Order

When pressing `t` to cycle themes, palettes rotate in this order:

| # | Palette | Type |
|---|---------|------|
| 1 | Green (default) | Handcrafted |
| 2 | Generated Green | Generated (hue 120°) |
| 3 | Amber | Handcrafted |
| 4 | White | Handcrafted |
| 5 | Red | Handcrafted |
| 6 | ncurses | Handcrafted (ANSI) |
| 7 | Violet | Generated (hue 270°) |

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
- ``WhitePalette``
- ``RedPalette``
- ``NCursesPalette``
- ``GeneratedPalette``

### Color System

- ``Color``
- ``TextStyle``

### Theme Management

- ``ThemeManager``
