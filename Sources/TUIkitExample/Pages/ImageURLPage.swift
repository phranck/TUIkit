//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageURLPage.swift
//
//  Created by LAYERED.work
//  License: MIT

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
        let charSet = ImageDemoHelpers.charSets[charSetIndex]
        let colorMode = ImageDemoHelpers.colorModes[colorModeIndex]
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
            DemoAppHeader("Image (URL)")
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
