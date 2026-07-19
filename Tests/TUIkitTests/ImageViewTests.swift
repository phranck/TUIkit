//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@Suite("Image View Tests")
@MainActor
struct ImageViewTests {

    @Test("Image initializes with file source")
    func imageFileInit() {
        let image = Image(.file("/path/to/image.png"))
        #expect(image.source == .file("/path/to/image.png"))
    }

    @Test("Image initializes with URL source")
    func imageURLInit() {
        let image = Image(.url("https://example.com/image.png"))
        #expect(image.source == .url("https://example.com/image.png"))
    }

    @Test("ImageSource equality works")
    func imageSourceEquality() {
        let source = ImageSource.file("/path/a.png")
        let matchingSource = ImageSource.file("/path/a.png")
        let differentSource = ImageSource.url("https://example.com")
        #expect(source == matchingSource)
        #expect(source != differentSource)
    }
}
