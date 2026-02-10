# Image View with ASCII Art Rendering

## Preface

This plan introduces SwiftUI-conformant Image view support for TUIkit using ASCII art rendering with full 24-bit true color support. The implementation converts raster images (PNG, JPEG) to colored ASCII/Unicode characters, enabling rich visual content in terminal UIs. The system uses platform-specific image decoding (CoreGraphics on macOS, swift-png on Linux) and sophisticated algorithms including brightness mapping, color quantization, Floyd-Steinberg dithering, and aspect ratio correction. The public API mirrors SwiftUI's Image API with terminal-specific modifiers for character set selection and color modes. Performance is optimized through caching, downsampling, and lazy rendering.

## Context/Problem

TUIkit currently lacks image support, limiting visual richness in terminal UIs. Users cannot display logos, icons, charts, or decorative graphics. While terminals don't support raster images natively, ASCII art rendering converts images to colored characters, providing a visually compelling alternative that works across all terminal types.

**Key Requirements:**
- SwiftUI API parity (`Image(systemName:)`, `Image(_:bundle:)`)
- Full 24-bit true color support (where available)
- Cross-platform (macOS + Linux)
- Zero external dependencies (beyond Swift)
- Multiple character sets (ASCII, blocks, braille)
- Graceful degradation for limited terminals

**Research Findings:**
- **Best algorithm**: 4x8 pixel cells mapped to Unicode block characters (from Go's ascii-image-converter)
- **Color modes**: 24-bit RGB > ANSI 256-color > grayscale > mono
- **Dithering**: Floyd-Steinberg for smooth gradients
- **Image decoding**: CoreGraphics (macOS) + swift-png (Linux)
- **Aspect ratio**: Terminal chars are ~2:1 (height:width), requires correction

## Specification/Goal

Implement `Image` view with ASCII art rendering:

```swift
// SwiftUI-conformant API
Image("logo", bundle: .module)
    .resizable()
    .frame(width: 60, height: 30)
    .foregroundStyle(.blue)

// Terminal-specific modifiers
Image("photo")
    .characterSet(.braille)      // .ascii, .blocks, .braille
    .colorMode(.trueColor)       // .trueColor, .ansi256, .grayscale, .mono
    .dithering(.floydSteinberg)  // .floydSteinberg, .atkinson, .none
```

**Supported Formats:**
- PNG (via swift-png on all platforms + CoreGraphics on macOS)
- JPEG, GIF, TIFF, BMP (via CoreGraphics on macOS only)

**Character Sets:**
- `.ascii`: `" .:;+=xX$@"` (10 levels, universal compatibility)
- `.blocks`: `" ░▒▓█"` (4 levels, modern terminals)
- `.braille`: Unicode U+2800-U+28FF (256 patterns, 2x4 pixel cells, highest quality)

**Color Modes:**
- `.trueColor`: 24-bit RGB ANSI codes (best quality)
- `.ansi256`: 256-color palette (good compatibility)
- `.grayscale`: 24 shades of gray
- `.mono`: Black and white only

**SF Symbols:**
- `Image(systemName:)` API provided but returns Unicode fallback (❤️→♥, ⭐→★)
- Runtime warning: "SF Symbols not supported in terminals, showing Unicode fallback"

## Design

### Architecture

```
┌─────────────────────────────────────────────┐
│ Public API Layer                            │
│ ┌─────────────────────────────────────────┐ │
│ │ Image (View)                            │ │
│ │  - init(_:bundle:)                      │ │
│ │  - init(systemName:)                    │ │
│ │  - var body: some View                  │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│ Image Loading Layer (Platform-specific)     │
│ ┌─────────────────────────────────────────┐ │
│ │ ImageLoader Protocol                    │ │
│ │  - loadImage(path:) -> RGBAImage        │ │
│ └─────────────────────────────────────────┘ │
│   ↓                          ↓              │
│ CoreGraphicsLoader    SwiftPNGLoader        │
│ (macOS)                (Linux)              │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│ Processing Pipeline                         │
│ ┌─────────────────────────────────────────┐ │
│ │ ASCIIConverter                          │ │
│ │  1. Downsample (Lanczos/Bilinear)       │ │
│ │  2. Aspect ratio correction (2:1)       │ │
│ │  3. Brightness mapping (luminance)      │ │
│ │  4. Character selection (char sets)     │ │
│ │  5. Color quantization (RGB→ANSI)       │ │
│ │  6. Dithering (Floyd-Steinberg)         │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│ Rendering Layer                             │
│ ┌─────────────────────────────────────────┐ │
│ │ _ImageCore (Renderable + Layoutable)    │ │
│ │  - renderToBuffer() -> FrameBuffer      │ │
│ │  - sizeThatFits() -> ViewSize           │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Key Types

```swift
// Public API
public struct Image: View {
    let source: ImageSource
    let characterSet: CharacterSet
    let colorMode: ColorMode
    let dithering: DitheringMode?
    
    public var body: some View {
        _ImageCore(
            source: source,
            characterSet: characterSet,
            colorMode: colorMode,
            dithering: dithering
        )
    }
}

public enum ImageSource {
    case named(String, bundle: Bundle?)
    case systemName(String)
}

public enum CharacterSet {
    case ascii      // " .:;+=xX$@"
    case blocks     // " ░▒▓█"
    case braille    // U+2800-U+28FF
}

public enum ColorMode {
    case trueColor  // 24-bit RGB
    case ansi256    // 256-color palette
    case grayscale  // 24 shades
    case mono       // Black/white
}

public enum DitheringMode {
    case floydSteinberg
    case atkinson
    case none
}

// Internal
struct RGBAImage {
    let width: Int
    let height: Int
    let pixels: [RGBA]  // Row-major order
}

struct RGBA {
    var r, g, b, a: UInt8
    
    var luminance: Double {
        // ITU-R BT.601
        Double(r) * 0.299 + Double(g) * 0.587 + Double(b) * 0.114
    }
}

protocol ImageLoader {
    func loadImage(from path: String) throws -> RGBAImage
}
```

### Terminal Capability Detection

```swift
struct TerminalCapabilities {
    let supports24BitColor: Bool
    let supportsUnicode: Bool
    let supportsBraille: Bool
    
    static func detect() -> TerminalCapabilities {
        let colorterm = ProcessInfo.processInfo.environment["COLORTERM"]
        let term = ProcessInfo.processInfo.environment["TERM"] ?? ""
        
        return TerminalCapabilities(
            supports24BitColor: colorterm?.contains("truecolor") ?? false ||
                                colorterm?.contains("24bit") ?? false,
            supportsUnicode: !term.contains("vt100"),
            supportsBraille: term.contains("xterm-256color") ||
                             term.contains("kitty") ||
                             term.contains("iterm")
        )
    }
}
```

### Algorithms

**1. Brightness Mapping**
```swift
func mapToCharacter(_ luminance: Double, characterSet: CharacterSet) -> Character {
    let chars: String
    switch characterSet {
    case .ascii:   chars = " .:;+=xX$@"
    case .blocks:  chars = " ░▒▓█"
    case .braille: return mapToBraille(luminance)  // Special handling
    }
    
    let index = Int((luminance / 255.0) * Double(chars.count - 1))
    return chars[chars.index(chars.startIndex, offsetBy: index)]
}
```

**2. Color Quantization (RGB → ANSI 256)**
```swift
func quantizeToANSI256(_ color: RGBA) -> UInt8 {
    // Grayscale ramp (232-255) for near-grayscale colors
    if abs(Int(color.r) - Int(color.g)) < 10 &&
       abs(Int(color.g) - Int(color.b)) < 10 {
        let gray = Int(color.r)
        if gray < 8 { return 16 }
        if gray > 248 { return 231 }
        return UInt8(232 + (gray - 8) / 10)
    }
    
    // 6x6x6 color cube (16-231)
    let r = Int((Double(color.r) / 255.0 * 5.0).rounded())
    let g = Int((Double(color.g) / 255.0 * 5.0).rounded())
    let b = Int((Double(color.b) / 255.0 * 5.0).rounded())
    return UInt8(16 + 36 * r + 6 * g + b)
}
```

**3. Floyd-Steinberg Dithering**
```swift
func floydSteinbergDither(_ image: RGBAImage) -> RGBAImage {
    var result = image
    
    for y in 0..<image.height {
        for x in 0..<image.width {
            let oldPixel = result.pixel(at: x, y)
            let newPixel = quantizePixel(oldPixel)
            result.setPixel(at: x, y, value: newPixel)
            
            let error = oldPixel - newPixel
            
            // Distribute error to neighbors
            if x + 1 < image.width {
                result.addError(at: x + 1, y, error: error * (7.0/16.0))
            }
            if y + 1 < image.height {
                if x > 0 {
                    result.addError(at: x - 1, y + 1, error: error * (3.0/16.0))
                }
                result.addError(at: x, y + 1, error: error * (5.0/16.0))
                if x + 1 < image.width {
                    result.addError(at: x + 1, y + 1, error: error * (1.0/16.0))
                }
            }
        }
    }
    
    return result
}
```

**4. Aspect Ratio Correction**
```swift
func correctAspectRatio(
    imageSize: (width: Int, height: Int),
    targetWidth: Int
) -> (width: Int, height: Int) {
    let aspectRatio = 2.0  // Terminal chars are ~2x taller than wide
    let scaledHeight = Double(imageSize.height) / aspectRatio
    let scale = Double(targetWidth) / Double(imageSize.width)
    
    return (
        width: targetWidth,
        height: Int((scaledHeight * scale).rounded())
    )
}
```

### Caching Strategy

```swift
struct ImageCache {
    private var cache: [CacheKey: String] = [:]
    
    struct CacheKey: Hashable {
        let path: String
        let width: Int
        let height: Int
        let characterSet: CharacterSet
        let colorMode: ColorMode
        let dithering: DitheringMode?
    }
    
    func get(key: CacheKey) -> String? {
        cache[key]
    }
    
    mutating func set(key: CacheKey, value: String) {
        // Limit cache size (LRU eviction)
        if cache.count > 100 {
            cache.removeValue(forKey: cache.keys.first!)
        }
        cache[key] = value
    }
}
```

## Implementation Plan

### Phase 1: Foundation (Image Loading)

**1.1 Add swift-png dependency**
- Update `Package.swift`
- Add `.package(url: "https://github.com/tayloraswift/swift-png", from: "4.4.0")`

**1.2 Create ImageLoader protocol + implementations**
- `Sources/TUIkit/Image/ImageLoader.swift`
- Protocol: `loadImage(from:) throws -> RGBAImage`
- `CoreGraphicsImageLoader` (macOS): Uses `CGImageSource`
- `SwiftPNGImageLoader` (Linux): Uses `PNG.decompress()`
- Platform detection: `#if canImport(CoreGraphics)`

**1.3 RGBAImage data structure**
- `Sources/TUIkit/Image/RGBAImage.swift`
- Struct with `width`, `height`, `pixels: [RGBA]`
- Helper: `pixel(at:)`, `setPixel(at:)`, `addError(at:)`
- RGBA struct with `luminance` computed property

**Tests:**
- Load PNG on macOS (CoreGraphics)
- Load PNG on Linux (swift-png)
- Verify pixel data correctness
- Test invalid paths/formats

### Phase 2: ASCII Conversion Algorithms

**2.1 Brightness mapping**
- `Sources/TUIkit/Image/ASCIIConverter.swift`
- Function: `mapToCharacter(_:characterSet:) -> Character`
- Character sets: `.ascii`, `.blocks`, `.braille`

**2.2 Color quantization**
- Function: `quantizeToANSI256(_:) -> UInt8`
- Function: `rgbToANSI(_:) -> String` (24-bit ANSI codes)
- Function: `rgbToGrayscale(_:) -> UInt8`

**2.3 Dithering**
- Function: `floydSteinbergDither(_:) -> RGBAImage`
- Function: `atkinsonDither(_:) -> RGBAImage`
- Error diffusion with proper boundary checks

**2.4 Image processing**
- Function: `downsample(_:targetSize:) -> RGBAImage` (Lanczos filter)
- Function: `correctAspectRatio(_:targetWidth:) -> (Int, Int)`

**Tests:**
- Brightness mapping for each character set
- Color quantization accuracy (known RGB → ANSI values)
- Dithering produces expected patterns
- Aspect ratio calculation

### Phase 3: Public API

**3.1 Image view**
- `Sources/TUIkit/Views/Image.swift`
- `init(_:bundle:)`
- `init(systemName:)` (with Unicode fallback warning)
- `var body: some View` returns `_ImageCore`

**3.2 Modifiers**
- `.characterSet(_:)` → `CharacterSetModifier`
- `.colorMode(_:)` → `ColorModeModifier`
- `.dithering(_:)` → `DitheringModifier`
- Reuse existing `.resizable()`, `.frame()`, `.foregroundStyle()`

**3.3 Environment keys**
- `ImageCharacterSetKey` (default: `.blocks`)
- `ImageColorModeKey` (default: `.trueColor` if supported, else `.ansi256`)
- `ImageDitheringKey` (default: `.none`)

**Tests:**
- Image initializers
- Modifier application
- Environment propagation
- SF Symbols fallback warning

### Phase 4: Rendering

**4.1 _ImageCore (Renderable + Layoutable)**
- `Sources/TUIkit/Views/Internal/_ImageCore.swift`
- Implements `Renderable`, `Layoutable`
- `sizeThatFits()`: Return image dimensions (fixed size)
- `renderToBuffer()`: Call `ASCIIConverter`, return colored ASCII

**4.2 Terminal capability detection**
- `Sources/TUIkit/Image/TerminalCapabilities.swift`
- Detect 24-bit color support (`COLORTERM` env var)
- Detect Unicode/Braille support (`TERM` env var)
- Auto-select best color mode

**4.3 Caching**
- `Sources/TUIkit/Image/ImageCache.swift`
- Cache converted ASCII art (not raw images)
- Cache key: path + size + character set + color mode + dithering
- LRU eviction (max 100 entries)

**Tests:**
- Rendering with all character sets
- Rendering with all color modes
- Size calculation
- Cache hit/miss
- Terminal capability detection

### Phase 5: Performance & Polish

**5.1 Optimization**
- Benchmark conversion time for various image sizes
- Profile memory usage
- Optimize hot paths (brightness mapping, color quantization)
- Consider SIMD for pixel operations

**5.2 Documentation**
- Doc comments on all public APIs
- Usage examples
- Performance considerations
- Terminal compatibility notes

**5.3 Example app integration**
- Add image examples to TUIkitExample
- Showcase different character sets
- Compare color modes side-by-side
- Demonstrate .resizable() behavior

**Tests:**
- Performance tests (conversion time < 100ms for 80x40 image)
- Memory tests (no leaks)
- Edge cases (1x1 image, 1000x1000 image, corrupt file)

### Phase 6: Advanced Features (Optional)

**6.1 Braille rendering**
- Map 2x4 pixel blocks to Braille characters (U+2800-U+28FF)
- Highest resolution (256 patterns per character)
- Requires font support detection

**6.2 Animation support**
- Support GIF loading
- Frame-by-frame ASCII conversion
- `.animated()` modifier for playback

**6.3 SVG support**
- Rasterize SVG to bitmap first
- Requires additional dependency (resvg or similar)
- Cross-platform challenge

## Checklist

### Phase 1: Foundation
- [ ] Add swift-png dependency to Package.swift
- [ ] Create ImageLoader protocol
- [ ] Implement CoreGraphicsImageLoader (macOS)
- [ ] Implement SwiftPNGImageLoader (Linux)
- [ ] Create RGBAImage struct with RGBA type
- [ ] Write tests for image loading on both platforms

### Phase 2: ASCII Conversion
- [ ] Implement brightness mapping with character sets
- [ ] Implement ANSI 256-color quantization
- [ ] Implement 24-bit RGB ANSI codes
- [ ] Implement grayscale conversion
- [ ] Implement Floyd-Steinberg dithering
- [ ] Implement Atkinson dithering
- [ ] Implement Lanczos downsampling
- [ ] Implement aspect ratio correction
- [ ] Write tests for all algorithms

### Phase 3: Public API
- [ ] Create Image view with init(_:bundle:)
- [ ] Add init(systemName:) with Unicode fallback
- [ ] Implement .characterSet() modifier
- [ ] Implement .colorMode() modifier
- [ ] Implement .dithering() modifier
- [ ] Create environment keys for image settings
- [ ] Write tests for API and modifiers

### Phase 4: Rendering
- [ ] Create _ImageCore (Renderable + Layoutable)
- [ ] Implement sizeThatFits() for layout
- [ ] Implement renderToBuffer() with ASCIIConverter
- [ ] Create TerminalCapabilities detection
- [ ] Implement ImageCache with LRU eviction
- [ ] Write tests for rendering and caching

### Phase 5: Performance & Polish
- [ ] Benchmark and optimize conversion pipeline
- [ ] Profile memory usage
- [ ] Add comprehensive doc comments
- [ ] Create usage examples
- [ ] Integrate into TUIkitExample app
- [ ] Write performance tests
- [ ] Test edge cases (1x1, large images, corrupt files)

### Phase 6: Advanced (Optional)
- [ ] Implement Braille rendering (2x4 pixel blocks)
- [ ] Add GIF animation support
- [ ] Consider SVG support

## Open Questions

1. **Default character set**: Should default be `.blocks` (better quality) or `.ascii` (better compatibility)?
   - Recommendation: `.blocks` with auto-fallback to `.ascii` if Unicode not supported

2. **Caching location**: Memory-only or disk cache for converted images?
   - Recommendation: Memory-only for now (simpler), disk cache in future if needed

3. **Resizable behavior**: Should `.resizable()` make image expand to fill available space (like SwiftUI)?
   - Recommendation: Yes, match SwiftUI behavior (expand to proposal, respect aspect ratio)

4. **SF Symbols strategy**: Hard error, silent fallback, or warning?
   - Recommendation: Warning + Unicode fallback (matches SwiftUI philosophy of graceful degradation)

5. **Maximum image size**: Should we enforce limits to prevent performance issues?
   - Recommendation: Warn if source image > 4000x4000, auto-downsample if terminal target > 200x100

## Dependencies

**External:**
- `swift-png` (v4.4.0+): Cross-platform PNG decoding
- `CoreGraphics` (Apple platforms): Multi-format image loading

**Internal:**
- `ANSIRenderer`: Reuse existing color output (24-bit RGB codes)
- `FrameBuffer`: Store rendered ASCII art
- `RenderContext`: Access terminal size, capabilities
- `EnvironmentValues`: Store image settings (.characterSet, .colorMode)

## Files

**New:**
- `Sources/TUIkit/Views/Image.swift`
- `Sources/TUIkit/Views/Internal/_ImageCore.swift`
- `Sources/TUIkit/Image/ImageLoader.swift`
- `Sources/TUIkit/Image/CoreGraphicsImageLoader.swift`
- `Sources/TUIkit/Image/SwiftPNGImageLoader.swift`
- `Sources/TUIkit/Image/RGBAImage.swift`
- `Sources/TUIkit/Image/ASCIIConverter.swift`
- `Sources/TUIkit/Image/TerminalCapabilities.swift`
- `Sources/TUIkit/Image/ImageCache.swift`
- `Sources/TUIkit/Modifiers/ImageModifiers.swift`
- `Tests/TUIkitTests/Image/ImageTests.swift`
- `Tests/TUIkitTests/Image/ASCIIConverterTests.swift`
- `Tests/TUIkitTests/Image/ImageLoaderTests.swift`

**Modified:**
- `Package.swift` (add swift-png dependency)
- `Sources/TUIkit/TUIkit.swift` (export Image)
- `Sources/TUIkitExample/ExampleApp.swift` (add image examples)
