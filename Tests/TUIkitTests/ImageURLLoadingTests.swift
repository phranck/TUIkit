//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageURLLoadingTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TUIkitImage

@Suite("Image URL Loading Tests")
struct ImageURLLoadingTests {

    @Test("URL cache hits enforce the current loader pixel limit")
    func cachedImagePixelLimit() {
        let urlString = "https://cache.test/issue-16-limit.png"
        let cachedImage = RGBAImage(
            width: 2,
            height: 2,
            pixels: [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: 4)
        )
        let cache = URLImageCache()
        cache.set(urlString, image: cachedImage)
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxPixelCount: 3)
        )

        do {
            _ = try loader.loadImage(from: urlString, cache: cache)
            Issue.record("Expected the current loader limit to reject the cached image")
        } catch let error as ImageLoadError {
            guard case .imageTooLarge(pixelCount: 4, limit: 3) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("URL loading stops at the encoded input byte limit")
    func urlInputByteLimit() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OversizedImageURLProtocol.self]
        let request = URLRequest(url: URL(string: "https://stream.test/oversized-image")!)

        do {
            _ = try BoundedURLImageDataLoader.load(
                request: request,
                maxByteCount: 4,
                configuration: configuration
            )
            Issue.record("Expected the URL input byte limit to stop the download")
        } catch let error as ImageLoadError {
            guard case .inputTooLarge(let byteCount, limit: 4) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(byteCount == 5)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
