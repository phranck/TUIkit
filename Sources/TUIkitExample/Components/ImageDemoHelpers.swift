//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageDemoHelpers.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Shared image demo configuration used by both `ImageFilePage` and `ImageURLPage`.
enum ImageDemoHelpers {
    static let charSets: [ASCIICharacterSet] = [.blocks, .ascii, .braille]
    static let colorModes: [ASCIIColorMode] = [.trueColor, .ansi256, .grayscale, .mono]

    static func charSetLabel(_ index: Int) -> String {
        switch charSets[index] {
        case .ascii: return "chars:ascii"
        case .blocks: return "chars:blocks"
        case .braille: return "chars:braille"
        }
    }

    static func colorModeLabel(_ index: Int) -> String {
        switch colorModes[index] {
        case .trueColor: return "color:true"
        case .ansi256: return "color:256"
        case .grayscale: return "color:gray"
        case .mono: return "color:mono"
        }
    }
}
