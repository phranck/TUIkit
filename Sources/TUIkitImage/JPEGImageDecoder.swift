//  🖥️ TUIKit — Terminal UI Kit for Swift
//  JPEGImageDecoder.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitVendorJPEG

enum JPEGImageDecoder {
    static func inspect(_ bytes: [UInt8]) throws -> DecodedImageMetadata {
        var offset = 2
        while offset < bytes.count {
            guard bytes[offset] == 0xFF else {
                throw ImageLoadError.decodingFailed("invalid JPEG marker sequence")
            }
            while offset < bytes.count, bytes[offset] == 0xFF {
                offset += 1
            }
            guard offset < bytes.count else {
                throw ImageLoadError.decodingFailed("truncated JPEG marker")
            }

            let marker = bytes[offset]
            offset += 1
            guard marker != 0x00 else {
                throw ImageLoadError.decodingFailed("invalid JPEG marker")
            }
            if standaloneMarkers.contains(marker) {
                guard marker != 0xD9 else {
                    throw ImageLoadError.decodingFailed("JPEG contains no frame header")
                }
                continue
            }

            guard offset <= bytes.count - 2 else {
                throw ImageLoadError.decodingFailed("truncated JPEG segment length")
            }
            let segmentLength = Int(readUInt16(bytes, at: offset))
            guard segmentLength >= 2, segmentLength <= bytes.count - offset else {
                throw ImageLoadError.decodingFailed("invalid JPEG segment length")
            }

            if frameMarkers.contains(marker) {
                return try inspectFrame(
                    bytes,
                    marker: marker,
                    segmentOffset: offset,
                    segmentLength: segmentLength
                )
            }
            if marker == 0xDA {
                throw ImageLoadError.decodingFailed("JPEG scan precedes its frame header")
            }
            offset += segmentLength
        }

        throw ImageLoadError.decodingFailed("JPEG contains no frame header")
    }

    static func decode(_ bytes: [UInt8]) throws -> RGBAImage {
        do {
            var source = ImageByteStream(bytes: bytes)
            let image: JPEG.Data.Rectangular<JPEG.Common> = try .decompress(stream: &source)
            let decodedPixels: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
            let pixels = decodedPixels.map { pixel in
                RGBA(r: pixel.r, g: pixel.g, b: pixel.b)
            }
            let (expectedPixelCount, overflow) = image.size.x.multipliedReportingOverflow(by: image.size.y)
            guard !overflow, pixels.count == expectedPixelCount else {
                throw ImageLoadError.decodingFailed("inconsistent JPEG pixel count")
            }
            return RGBAImage(width: image.size.x, height: image.size.y, pixels: pixels)
        } catch {
            throw ImageLoadError.decodingFailed("invalid JPEG data")
        }
    }
}

extension ImageByteStream: JPEG.Bytestream.Source {}

private extension JPEGImageDecoder {
    static let standaloneMarkers: Set<UInt8> = [
        0x01,
        0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7,
        0xD8, 0xD9,
    ]
    static let frameMarkers: Set<UInt8> = [
        0xC0, 0xC1, 0xC2, 0xC3,
        0xC5, 0xC6, 0xC7,
        0xC9, 0xCA, 0xCB,
        0xCD, 0xCE, 0xCF,
    ]
    static let supportedFrameMarkers: Set<UInt8> = [0xC0, 0xC1, 0xC2]

    struct ComponentSampling {
        let horizontal: Int
        let vertical: Int
    }

    static func inspectFrame(
        _ bytes: [UInt8],
        marker: UInt8,
        segmentOffset: Int,
        segmentLength: Int
    ) throws -> DecodedImageMetadata {
        guard supportedFrameMarkers.contains(marker) else {
            throw ImageLoadError.unsupportedFormat("JPEG process \(marker)")
        }
        guard segmentLength >= 8 else {
            throw ImageLoadError.decodingFailed("truncated JPEG frame header")
        }

        let dataOffset = segmentOffset + 2
        let precision = bytes[dataOffset]
        let height = Int(readUInt16(bytes, at: dataOffset + 1))
        let width = Int(readUInt16(bytes, at: dataOffset + 3))
        let componentCount = Int(bytes[dataOffset + 5])

        guard precision == 8 else {
            throw ImageLoadError.unsupportedFormat("JPEG precision \(precision)")
        }
        guard componentCount > 0, segmentLength == 8 + componentCount * 3 else {
            throw ImageLoadError.decodingFailed("invalid JPEG component layout")
        }
        guard [1, 3].contains(componentCount) else {
            throw ImageLoadError.unsupportedFormat("JPEG component count \(componentCount)")
        }

        var componentIdentifiers = Set<UInt8>()
        var sampling: [ComponentSampling] = []
        for componentIndex in 0..<componentCount {
            let componentOffset = dataOffset + 6 + componentIndex * 3
            let identifier = bytes[componentOffset]
            let factors = bytes[componentOffset + 1]
            let horizontal = Int(factors >> 4)
            let vertical = Int(factors & 0x0F)
            let quantizationTable = bytes[componentOffset + 2]
            guard componentIdentifiers.insert(identifier).inserted,
                  (1...4).contains(horizontal),
                  (1...4).contains(vertical),
                  quantizationTable <= 3
            else {
                throw ImageLoadError.decodingFailed("invalid JPEG component layout")
            }
            sampling.append(ComponentSampling(horizontal: horizontal, vertical: vertical))
        }

        let decompressedByteCount = try decompressedByteCount(
            width: width,
            height: height,
            sampling: sampling
        )
        return DecodedImageMetadata(
            width: width,
            height: height,
            frameCount: 1,
            decompressedByteCount: decompressedByteCount
        )
    }

    static func decompressedByteCount(
        width: Int,
        height: Int,
        sampling: [ComponentSampling]
    ) throws -> Int {
        guard let maximumHorizontal = sampling.map(\.horizontal).max(),
              let maximumVertical = sampling.map(\.vertical).max()
        else {
            throw ImageLoadError.decodingFailed("invalid JPEG component layout")
        }

        let horizontalMCUCount = ceilingDivision(width, by: 8 * maximumHorizontal)
        let verticalMCUCount = ceilingDivision(height, by: 8 * maximumVertical)
        var blockSampleCount = 0
        for component in sampling {
            let horizontalBlockCount = try checkedProduct(
                horizontalMCUCount,
                component.horizontal,
                width: width,
                height: height
            )
            let verticalBlockCount = try checkedProduct(
                verticalMCUCount,
                component.vertical,
                width: width,
                height: height
            )
            let blockCount = try checkedProduct(
                horizontalBlockCount,
                verticalBlockCount,
                width: width,
                height: height
            )
            let sampleCount = try checkedProduct(blockCount, 64, width: width, height: height)
            let (newSampleCount, overflow) = blockSampleCount.addingReportingOverflow(sampleCount)
            guard !overflow else {
                throw ImageLoadError.sizeOverflow(width: width, height: height)
            }
            blockSampleCount = newSampleCount
        }

        let spectralByteCount = try checkedProduct(
            blockSampleCount,
            MemoryLayout<UInt16>.stride,
            width: width,
            height: height
        )
        let pixelCount = try checkedProduct(width, height, width: width, height: height)
        let rectangularSampleCount = try checkedProduct(
            pixelCount,
            sampling.count,
            width: width,
            height: height
        )
        let rectangularByteCount = try checkedProduct(
            rectangularSampleCount,
            MemoryLayout<UInt16>.stride,
            width: width,
            height: height
        )
        return max(spectralByteCount, rectangularByteCount)
    }

    static func checkedProduct(_ lhs: Int, _ rhs: Int, width: Int, height: Int) throws -> Int {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        guard !overflow else {
            throw ImageLoadError.sizeOverflow(width: width, height: height)
        }
        return result
    }

    static func ceilingDivision(_ value: Int, by divisor: Int) -> Int {
        guard value > 0 else { return 0 }
        return (value + divisor - 1) / divisor
    }

    static func readUInt16(_ bytes: [UInt8], at offset: Int) -> UInt16 {
        UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }
}
