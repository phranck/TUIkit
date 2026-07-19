# Image Decoding

Load static PNG and JPEG images safely on macOS and Linux.

## Overview

``PlatformImageLoader`` uses vendored, namespaced pure Swift format decoders and always returns non-premultiplied 8-bit RGBA pixels in an
``RGBAImage``. Animated images and formats other than PNG and JPEG are not supported. JPEG input is limited to 8-bit grayscale and
three-component color images.

The format decoder is independent from file and URL lifecycle code. Decoding the same bytes with the same limits therefore produces the
same pixels without accessing the network.

## Loading Data or Files

```swift
let loader = PlatformImageLoader()
let fromData = try loader.loadImage(from: encodedData)
let fromFile = try loader.loadImage(from: "/absolute/path/image.png")
```

Both entry points apply the same validation and return ``ImageLoadError`` when the input cannot be read or decoded.

## Resource Limits

Configure ``ImageDecodingLimits`` when creating the loader:

```swift
let limits = ImageDecodingLimits(
    maxInputBytes: 8 * 1_024 * 1_024,
    maxDimension: 4_096,
    maxPixelCount: 12_000_000,
    maxFrameCount: 1,
    maxDecodedBytes: 48 * 1_024 * 1_024,
    maxDecompressedBytes: 48 * 1_024 * 1_024
)
let loader = PlatformImageLoader(limits: limits)
```

TUIkit inspects the image header and validates encoded bytes, dimensions, pixels, frames, decompressed source samples, and the final RGBA
allocation before invoking a format decoder. A per-call `maxPixelCount` can tighten the loader-wide pixel limit but cannot loosen it.
PNG ancillary metadata is discarded because ``RGBAImage`` has no metadata surface. This also prevents compressed text or color-profile
chunks from allocating outside the image decompression limit. PNG image-data chunks are fed to the decoder in bounded pieces, and
malformed trailing decompressed data is rejected.

URL loading streams encoded bytes and cancels the transfer as soon as `maxInputBytes` is exceeded. Cached images are revalidated against
the current loader's dimensions, pixels, frame, and final allocation limits before they are returned.

## Topics

### Loading

- ``PlatformImageLoader``
- ``ImageLoader``

### Data and Limits

- ``ImageDecodingLimits``
- ``RGBAImage``
- ``RGBA``
- ``ImageLoadError``
