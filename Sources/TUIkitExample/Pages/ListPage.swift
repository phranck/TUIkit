//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

// MARK: - Demo Item

/// A simple item for list demos.
private struct FileItem: Identifiable {
    let id: String
    let name: String
    let size: String
    let icon: String

    static let sampleFiles: [Self] = [
        Self(id: "1", name: "README.md", size: "4.2 KB", icon: "📄"),
        Self(id: "2", name: "Package.swift", size: "1.8 KB", icon: "📦"),
        Self(id: "3", name: "Sources", size: "128 KB", icon: "📁"),
        Self(id: "4", name: "Tests", size: "64 KB", icon: "📁"),
        Self(id: "5", name: ".gitignore", size: "0.5 KB", icon: "📄"),
        Self(id: "6", name: "LICENSE", size: "1.1 KB", icon: "📄"),
        Self(id: "7", name: "docs", size: "256 KB", icon: "📁"),
        Self(id: "8", name: "plans", size: "32 KB", icon: "📁"),
        Self(id: "9", name: ".swiftlint.yml", size: "1.2 KB", icon: "⚙️"),
        Self(id: "10", name: ".github", size: "8 KB", icon: "📁"),
        Self(id: "11", name: "Makefile", size: "0.8 KB", icon: "📄"),
        Self(id: "12", name: ".claude", size: "16 KB", icon: "📁"),
    ]
}

// MARK: - List Page

/// List component demo page.
///
/// Shows interactive list features including:
/// - Single selection with binding
/// - Multi-selection with binding
/// - Keyboard navigation (Up/Down/Home/End/PageUp/PageDown)
/// - Scroll indicators
/// - Empty state placeholder
struct ListPage: View {
    @State var singleSelection: String?
    @State var multiSelection: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            HStack(spacing: 2) {
                List(
                    "Single Selection",
                    selection: $singleSelection
                ) {
                    ForEach(FileItem.sampleFiles) { file in
                        HStack(spacing: 1) {
                            Text(file.icon)
                            Text(file.name)
                        }
                    }
                }

                List(
                    "Multi Selection",
                    selection: $multiSelection
                ) {
                    ForEach(FileItem.sampleFiles) { file in
                        HStack(spacing: 1) {
                            Text(file.icon)
                            Text(file.name)
                        }
                    }
                }
            }

            DemoSection("Current Selections") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Single:").foregroundStyle(.palette.foregroundSecondary)
                        Text(singleSelection ?? "(none)")
                            .bold()
                            .foregroundStyle(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Multi:").foregroundStyle(.palette.foregroundSecondary)
                        Text(multiSelection.isEmpty ? "(none)" : multiSelection.sorted().joined(separator: ", "))
                            .bold()
                            .foregroundStyle(.palette.accent)
                    }
                }
            }

            List("Empty List", selection: Binding<String?>(get: { nil }, set: { _ in })) {
                EmptyView()
            }

            DemoSection("Navigation") {
                VStack {
                    Text("Use [↑/↓] to navigate items").dim()
                    Text("Use [Home/End] to jump to first/last").dim()
                    Text("Use [PageUp/PageDown] for fast scrolling").dim()
                    Text("Use [Enter/Space] to select/deselect").dim()
                    Text("Use [Tab] to switch between lists").dim()
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("List Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}
