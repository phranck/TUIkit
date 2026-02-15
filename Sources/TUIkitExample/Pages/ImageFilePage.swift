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
        let charSet = ImageDemoHelpers.charSets[charSetIndex]
        let colorMode = ImageDemoHelpers.colorModes[colorModeIndex]
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
            DemoAppHeader("Image (File)")
        }
    }

    private var statusBarItems: [any StatusBarItemProtocol] {
        [
            StatusBarItem(shortcut: Shortcut.escape, label: "back"),
            StatusBarItem(shortcut: "c", label: ImageDemoHelpers.charSetLabel(charSetIndex)) {
                charSetIndex = (charSetIndex + 1) % ImageDemoHelpers.charSets.count
            },
            StatusBarItem(shortcut: "m", label: ImageDemoHelpers.colorModeLabel(colorModeIndex)) {
                colorModeIndex = (colorModeIndex + 1) % ImageDemoHelpers.colorModes.count
            },
            StatusBarItem(shortcut: "d", label: ditheringOn ? "dither:on" : "dither:off") {
                ditheringOn.toggle()
            },
            StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "scroll"),
        ]
    }
}
