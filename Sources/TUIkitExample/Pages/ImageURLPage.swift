//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageURLPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import TUIkit

/// Image demo page for loading an image from a URL.
///
/// Provides a text field for entering an image URL. After pressing
/// Enter the image is downloaded and rendered. Status bar items allow
/// cycling through character set, color mode, and dithering settings.
struct ImageURLPage: View {
    @State var imageURL: String = ""
    @State var activeURL: String = ""

    @State var charSetIndex: Int = 0
    @State var colorModeIndex: Int = 0
    @State var ditheringOn: Bool = false

    var body: some View {
        let charSet = Self.charSets[charSetIndex]
        let colorMode = Self.colorModes[colorModeIndex]
        let dithering: DitheringMode = ditheringOn ? .floydSteinberg : .none

        VStack(alignment: .leading) {
            HStack(spacing: 1) {
                Text("URL:")
                    .foregroundStyle(.palette.foregroundSecondary)
                TextField("Enter image URL...", text: $imageURL)
                    .onSubmit {
                        activeURL = imageURL
                    }
                    .textContentType(.url)
            }
            .padding(.bottom, 1)

            if !activeURL.isEmpty {
                HStack {
                    Spacer()
                    Image(.url(activeURL))
                        .imagePlaceholder("Downloading...")
                        .imagePlaceholderSpinner(true)
                        .border(color: .palette.border)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Text("Press Enter to load the image")
                        .foregroundStyle(.palette.foregroundTertiary)
                        .italic()
                    Spacer()
                }
                Spacer()
            }
            Spacer()
        }
        .imageCharacterSet(charSet)
        .imageColorMode(colorMode)
        .imageDithering(dithering)
        .statusBarItems(statusBarItems)
        .appHeader {
            HStack {
                Text("Image (URL)").bold().foregroundStyle(.palette.accent)
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

extension ImageURLPage {

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
