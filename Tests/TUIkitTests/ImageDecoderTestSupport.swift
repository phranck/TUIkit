//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageDecoderTestSupport.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TUIkitImage

final class OversizedImageURLProtocol: URLProtocol {

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client else { return }

        let response = URLResponse(
            url: request.url!,
            mimeType: "application/octet-stream",
            expectedContentLength: -1,
            textEncodingName: nil
        )
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: Data(repeating: 0, count: 8))
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension ImageDecoderTests {

    var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    var pngFixturePath: String {
        packageRoot
            .appendingPathComponent("Sources/TUIkit/TUIkit.docc/Resources/tuikit-logo-blank.png")
            .path
    }

    var jpegFixturePath: String {
        packageRoot
            .appendingPathComponent("Sources/TUIkitExample/Resources/demo-image.jpg")
            .path
    }

    func fixtureData(at path: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func tinyPNGFixture() -> Data {
        decodedBase64(
            """
            iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6
            UTwAAAAGYktHRAD/AP8A/6C9p5MAAAAHdElNRQfqBxMKGTbSqg9yAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTA3LTE5VDEw
            OjI1OjU0KzAwOjAw8WvLIAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0wNy0xOVQxMDoyNTo1NCswMDowMIA2c5wAAAAodEVY
            dGRhdGU6dGltZXN0YW1wADIwMjYtMDctMTlUMTA6MjU6NTQrMDA6MDDXI1JDAAAAFklEQVQI1wXBAQEAAACAEP9PFyIJBQM/0gX7
            fbpsCQAAAABJRU5ErkJggg==
            """
        )
    }

    func pngWithReservedScanlineFilter() -> Data {
        decodedBase64(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNlYGD4DwABHQEFBQ92bwAAAABJRU5ErkJggg=="
        )
    }

    func pngWithExtraneousImageData() -> Data {
        decodedBase64(
            """
            iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAEEUlEQVR42u3BMQEAAAzDoPg3vYnoC1RdAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AACjB/EEAQDxCNCQAAAAAElFTkSuQmCC
            """
        )
    }

    func tinyJPEGFixture() -> Data {
        decodedBase64(
            """
            /9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
            AQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
            AQEBAQEBAQEBAQEBAQH/wAARCAACAAIDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACP/EABQQAQAAAAAAAAAAAAAAAAAA
            AAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AI5qBDv/Z
            """
        )
    }

    func jpegWithExtraneousMCURowFixture() -> Data {
        decodedBase64(
            """
            /9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQ
            ERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgED
            AwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RF
            RkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJ
            ytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oACAEBAAA/APyqr+qiv//Z
            """
        )
    }

    func decodedBase64(_ encodedData: String) -> Data {
        guard let data = Data(base64Encoded: encodedData, options: .ignoreUnknownCharacters) else {
            Issue.record("Invalid embedded image fixture")
            return Data()
        }
        return data
    }

    func expectDecodingFailure(
        from data: Data,
        using loader: PlatformImageLoader,
        description: String
    ) {
        do {
            _ = try loader.loadImage(from: data)
            Issue.record("Expected invalid image data to be rejected")
        } catch let error as ImageLoadError {
            guard case .decodingFailed = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(error.description == description)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    func pngHeader(width: UInt32, height: UInt32, bitDepth: UInt8 = 8, colorType: UInt8 = 6) -> Data {
        var bytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52,
        ]
        bytes.append(contentsOf: bigEndianBytes(width))
        bytes.append(contentsOf: bigEndianBytes(height))
        bytes.append(contentsOf: [bitDepth, colorType, 0, 0, 0])
        return Data(bytes)
    }

    func jpegHeader(width: UInt16, height: UInt16, componentCount: UInt8 = 3) -> Data {
        let segmentLength = UInt16(8 + Int(componentCount) * 3)
        var bytes: [UInt8] = [
            0xFF, 0xD8,
            0xFF, 0xC0,
            UInt8(truncatingIfNeeded: segmentLength >> 8),
            UInt8(truncatingIfNeeded: segmentLength),
            0x08,
            UInt8(truncatingIfNeeded: height >> 8), UInt8(truncatingIfNeeded: height),
            UInt8(truncatingIfNeeded: width >> 8), UInt8(truncatingIfNeeded: width),
            componentCount,
        ]
        for componentIndex in 0..<componentCount {
            bytes.append(contentsOf: [componentIndex + 1, 0x11, 0x00])
        }
        bytes.append(contentsOf: [0xFF, 0xD9])
        return Data(bytes)
    }

    func animatedPNGHeader(frameCount: UInt32) -> Data {
        var data = pngHeader(width: 1, height: 1)
        data.append(contentsOf: [0, 0, 0, 0])
        data.append(contentsOf: [0, 0, 0, 8])
        data.append(contentsOf: [0x61, 0x63, 0x54, 0x4C])
        data.append(contentsOf: bigEndianBytes(frameCount))
        data.append(contentsOf: [0, 0, 0, 0])
        data.append(contentsOf: [0, 0, 0, 0])
        return data
    }

    func jpegAddingDNL(to jpeg: Data, height: UInt16) -> Data {
        var bytes = [UInt8](jpeg)
        bytes.insert(
            contentsOf: [
                0xFF, 0xDC, 0x00, 0x04,
                UInt8(truncatingIfNeeded: height >> 8),
                UInt8(truncatingIfNeeded: height),
            ],
            at: bytes.count - 2
        )
        return Data(bytes)
    }

    func bigEndianBytes(_ value: UInt32) -> [UInt8] {
        [
            UInt8(truncatingIfNeeded: value >> 24),
            UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 8),
            UInt8(truncatingIfNeeded: value),
        ]
    }

    func pngAddingChunk(to png: Data, type: [UInt8], data: [UInt8]) -> Data {
        var result = Data(png.dropLast(12))
        result.append(contentsOf: pngChunk(type: type, data: data))
        result.append(png.suffix(12))
        return result
    }

    func pngWithNonContiguousImageData() -> Data {
        let bytes = [UInt8](tinyPNGFixture())
        var chunkOffset = 8

        while chunkOffset <= bytes.count - 12 {
            let dataLength = Int(
                UInt32(bytes[chunkOffset]) << 24
                    | UInt32(bytes[chunkOffset + 1]) << 16
                    | UInt32(bytes[chunkOffset + 2]) << 8
                    | UInt32(bytes[chunkOffset + 3])
            )
            let dataOffset = chunkOffset + 8
            let chunkEndOffset = dataOffset + dataLength + 4
            guard chunkEndOffset <= bytes.count else { break }

            let type = Array(bytes[(chunkOffset + 4)..<(chunkOffset + 8)])
            if type == Array("IDAT".utf8), dataLength > 1 {
                let splitOffset = dataOffset + dataLength / 2
                var result = Data(bytes[..<chunkOffset])
                result.append(
                    contentsOf: pngChunk(
                        type: type,
                        data: Array(bytes[dataOffset..<splitOffset])
                    )
                )
                result.append(
                    contentsOf: pngChunk(
                        type: Array("tEXt".utf8),
                        data: Array("key\0value".utf8)
                    )
                )
                result.append(
                    contentsOf: pngChunk(
                        type: type,
                        data: Array(bytes[splitOffset..<(dataOffset + dataLength)])
                    )
                )
                result.append(contentsOf: bytes[chunkEndOffset...])
                return result
            }
            chunkOffset = chunkEndOffset
        }

        Issue.record("Embedded PNG fixture contains no splittable IDAT chunk")
        return Data()
    }

    func pngChunk(type: [UInt8], data: [UInt8]) -> [UInt8] {
        let chunkPayload = type + data
        var chunk = bigEndianBytes(UInt32(data.count))
        chunk.append(contentsOf: chunkPayload)
        chunk.append(contentsOf: bigEndianBytes(crc32(chunkPayload)))
        return chunk
    }

    func crc32(_ bytes: [UInt8]) -> UInt32 {
        let polynomial: UInt32 = 0xEDB8_8320
        var checksum = UInt32.max

        for byte in bytes {
            checksum ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = UInt32(bitPattern: -Int32(checksum & 1))
                checksum = (checksum >> 1) ^ (polynomial & mask)
            }
        }
        return ~checksum
    }
}
