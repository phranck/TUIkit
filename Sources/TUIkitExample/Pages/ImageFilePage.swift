//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageFilePage.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import TUIkit

/// Image demo page for loading an image from the local filesystem.
///
/// Displays a bundled demo image and provides status bar items to
/// cycle through character set, color mode, and dithering settings.
struct ImageFilePage: View {
    @State var charSetIndex: Int = 0
    @State var colorModeIndex: Int = 0
    @State var ditheringOn: Bool = false

    var body: some View {
        let charSet = Self.charSets[charSetIndex]
        let colorMode = Self.colorModes[colorModeIndex]
        let dithering: DitheringMode = ditheringOn ? .floydSteinberg : .none

        VStack(alignment: .leading) {
            HStack {
                Spacer()
                if let path = Bundle.module.path(forResource: "demo-image", ofType: "jpg", inDirectory: "Resources") {
                    Image(.file(path))
                        .imagePlaceholder("Loading image...")
                        .imagePlaceholderSpinner(true)
                } else {
                    Text("Resource not found: demo-image.jpg")
                        .foregroundStyle(.error)
                }
                Spacer()
            }
            .padding(.bottom, 1)
            Spacer()
        }
        .imageCharacterSet(charSet)
        .imageColorMode(colorMode)
        .imageDithering(dithering)
        .statusBarItems(statusBarItems)
        .appHeader {
            HStack {
                Text("Image (File)").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }

    private var statusBarItems: [any StatusBarItemProtocol] {
        [
            StatusBarItem(shortcut: Shortcut.escape, label: "back"),
            StatusBarItem(shortcut: "c", label: Self.charSetLabel(charSetIndex)) {
                charSetIndex = (charSetIndex + 1) % Self.charSets.count
            },
            StatusBarItem(shortcut: "m", label: Self.colorModeLabel(colorModeIndex)) {
                colorModeIndex = (colorModeIndex + 1) % Self.colorModes.count
            },
            StatusBarItem(shortcut: "d", label: ditheringOn ? "dither:on" : "dither:off") {
                ditheringOn.toggle()
            },
            StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "scroll"),
        ]
    }
}

// MARK: - Modifier Options

extension ImageFilePage {

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
