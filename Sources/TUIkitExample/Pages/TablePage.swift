//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TablePage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

// MARK: - Demo Data

/// A file entry for the table demo.
private struct FileEntry: Identifiable, Sendable {
    let id: String
    let name: String
    let size: String
    let modified: String
    let type: String

    static let sampleFiles: [Self] = [
        Self(id: "1", name: "README.md", size: "4.2 KB", modified: "2026-02-07", type: "Markdown"),
        Self(id: "2", name: "Package.swift", size: "1.8 KB", modified: "2026-02-06", type: "Swift"),
        Self(id: "3", name: "Sources/", size: "128 KB", modified: "2026-02-07", type: "Directory"),
        Self(id: "4", name: "Tests/", size: "64 KB", modified: "2026-02-05", type: "Directory"),
        Self(id: "5", name: ".gitignore", size: "0.5 KB", modified: "2026-01-15", type: "Config"),
        Self(id: "6", name: "LICENSE", size: "1.1 KB", modified: "2026-01-01", type: "Text"),
        Self(id: "7", name: "docs/", size: "256 KB", modified: "2026-02-04", type: "Directory"),
        Self(id: "8", name: "plans/", size: "32 KB", modified: "2026-02-07", type: "Directory"),
        Self(id: "9", name: ".swiftlint.yml", size: "1.2 KB", modified: "2026-02-02", type: "YAML"),
        Self(id: "10", name: ".github/", size: "8 KB", modified: "2026-01-20", type: "Directory"),
        Self(id: "11", name: "Makefile", size: "0.8 KB", modified: "2026-02-01", type: "Makefile"),
        Self(id: "12", name: ".claude/", size: "16 KB", modified: "2026-02-07", type: "Directory"),
    ]
}

// MARK: - Table Page

/// Table component demo page.
///
/// Shows interactive table features including:
/// - Column definitions with key paths
/// - Column alignment (leading, center, trailing)
/// - Column width modes (fixed, flexible, ratio)
/// - Single and multi-selection
/// - Keyboard navigation
/// - Scroll indicators
struct TablePage: View {
    @State var singleSelection: String?
    @State var multiSelection: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            Text("File Browser (Single Selection)")
                .foregroundStyle(.palette.foregroundSecondary)
            Table(
                FileEntry.sampleFiles,
                selection: $singleSelection,
                maxVisibleRows: 6
            ) {
                TableColumn("Name", value: \FileEntry.name)
                TableColumn("Size", value: \FileEntry.size)
                    .width(.fixed(10))
                    .alignment(.trailing)
                TableColumn("Modified", value: \FileEntry.modified)
                    .width(.fixed(12))
                TableColumn("Type", value: \FileEntry.type)
                    .width(.fixed(10))
            }

            Text("Multi-Selection Table")
                .foregroundStyle(.palette.foregroundSecondary)
            Table(
                FileEntry.sampleFiles,
                selection: $multiSelection,
                maxVisibleRows: 4
            ) {
                TableColumn("Name", value: \FileEntry.name)
                TableColumn("Type", value: \FileEntry.type)
                    .width(.fixed(12))
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

            DemoSection("Navigation") {
                VStack {
                    Text("Use [Up/Down] to navigate rows").dim()
                    Text("Use [Home/End] to jump to first/last").dim()
                    Text("Use [PageUp/PageDown] for fast scrolling").dim()
                    Text("Use [Enter/Space] to select/deselect").dim()
                    Text("Use [Tab] to switch between tables").dim()
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Table Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}
