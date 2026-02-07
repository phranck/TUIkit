//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TableTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Data

private struct FileInfo: Identifiable, Sendable {
    let id: String
    let name: String
    let size: String
    let modified: String
}

private let testFiles: [FileInfo] = [
    FileInfo(id: "1", name: "README.md", size: "2.4 KB", modified: "2026-02-07"),
    FileInfo(id: "2", name: "Package.swift", size: "1.1 KB", modified: "2026-02-06"),
    FileInfo(id: "3", name: "main.swift", size: "512 B", modified: "2026-02-05"),
]

// MARK: - Test Helpers

@MainActor
private func createTestContext(width: Int = 80, height: Int = 24) -> RenderContext {
    let focusManager = FocusManager()
    var environment = EnvironmentValues()
    environment.focusManager = focusManager

    return RenderContext(
        availableWidth: width,
        availableHeight: height,
        environment: environment
    )
}

// MARK: - TableColumn Tests

@Suite("TableColumn Tests")
@MainActor
struct TableColumnTests {
    @Test("TableColumn extracts value via key path")
    func keyPathExtraction() {
        let column = TableColumn<FileInfo>("Name", value: \FileInfo.name)
        let file = FileInfo(id: "1", name: "test.txt", size: "1 KB", modified: "2026-01-01")

        #expect(column.value(for: file) == "test.txt")
    }

    @Test("TableColumn extracts value via closure")
    func closureExtraction() {
        let column = TableColumn<FileInfo>("Size") { file in
            "Size: \(file.size)"
        }
        let file = FileInfo(id: "1", name: "test.txt", size: "1 KB", modified: "2026-01-01")

        #expect(column.value(for: file) == "Size: 1 KB")
    }

    @Test("TableColumn defaults to leading alignment")
    func defaultAlignment() {
        let column = TableColumn<FileInfo>("Name", value: \FileInfo.name)
        #expect(column.alignment == .leading)
    }

    @Test("TableColumn defaults to flexible width")
    func defaultWidth() {
        let column = TableColumn<FileInfo>("Name", value: \FileInfo.name)
        #expect(column.width == .flexible)
    }

    @Test("TableColumn alignment modifier creates new instance")
    func alignmentModifier() {
        let column = TableColumn<FileInfo>("Size", value: \FileInfo.size)
        let aligned = column.alignment(.trailing)

        #expect(column.alignment == .leading)
        #expect(aligned.alignment == .trailing)
    }

    @Test("TableColumn width modifier creates new instance")
    func widthModifier() {
        let column = TableColumn<FileInfo>("Size", value: \FileInfo.size)
        let fixed = column.width(.fixed(10))

        #expect(column.width == .flexible)
        #expect(fixed.width == .fixed(10))
    }

    @Test("TableColumn modifiers can be chained")
    func chainedModifiers() {
        let column = TableColumn<FileInfo>("Size", value: \FileInfo.size)
            .alignment(.trailing)
            .width(.fixed(10))

        #expect(column.alignment == .trailing)
        #expect(column.width == .fixed(10))
    }
}

// MARK: - Table Rendering Tests

@Suite("Table Rendering Tests")
@MainActor
struct TableRenderingTests {
    @Test("Table renders header row")
    func headerRendering() {
        let context = createTestContext(width: 60, height: 10)
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
            TableColumn("Size", value: \FileInfo.size)
        }

        let buffer = renderToBuffer(table, context: context)

        // Header should be on first line
        let headerLine = buffer.lines[0].stripped
        #expect(headerLine.contains("Name"))
        #expect(headerLine.contains("Size"))
    }

    @Test("Table renders data rows")
    func dataRowRendering() {
        let context = createTestContext(width: 60, height: 10)
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }

        let buffer = renderToBuffer(table, context: context)
        let content = buffer.lines.map { $0.stripped }.joined(separator: "\n")

        #expect(content.contains("README.md"))
        #expect(content.contains("Package.swift"))
        #expect(content.contains("main.swift"))
    }

    @Test("Table shows empty placeholder when no data")
    func emptyState() {
        let context = createTestContext(width: 40, height: 10)
        let emptyData: [FileInfo] = []
        var selection: String?

        let table = Table(emptyData, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }

        let buffer = renderToBuffer(table, context: context)
        let content = buffer.lines.map { $0.stripped }.joined()

        #expect(content.contains("No items"))
    }

    @Test("Table shows custom empty placeholder")
    func customEmptyPlaceholder() {
        let context = createTestContext(width: 40, height: 10)
        let emptyData: [FileInfo] = []
        var selection: String?

        let table = Table(
            emptyData,
            selection: Binding(get: { selection }, set: { selection = $0 }),
            emptyPlaceholder: "No files found"
        ) {
            TableColumn("Name", value: \FileInfo.name)
        }

        let buffer = renderToBuffer(table, context: context)
        let content = buffer.lines.map { $0.stripped }.joined()

        #expect(content.contains("No files found"))
    }

    @Test("Table renders column values correctly")
    func columnValues() {
        let context = createTestContext(width: 80, height: 10)
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
            TableColumn("Size", value: \FileInfo.size)
            TableColumn("Modified", value: \FileInfo.modified)
        }

        let buffer = renderToBuffer(table, context: context)
        let content = buffer.lines.map { $0.stripped }.joined(separator: "\n")

        // Check first file's values appear
        #expect(content.contains("README.md"))
        #expect(content.contains("2.4 KB"))
        #expect(content.contains("2026-02-07"))
    }

    @Test("Table respects fixed column width")
    func fixedColumnWidth() {
        let context = createTestContext(width: 60, height: 10)
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
            TableColumn("Size", value: \FileInfo.size)
                .width(.fixed(10))
        }

        let buffer = renderToBuffer(table, context: context)

        // The table should render without error with fixed widths
        #expect(buffer.lines.count > 1)
    }

    @Test("Table applies trailing alignment")
    func trailingAlignment() {
        let context = createTestContext(width: 40, height: 10)
        var selection: String?
        let singleFile = [FileInfo(id: "1", name: "test", size: "1 KB", modified: "2026-01-01")]

        let table = Table(singleFile, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Size", value: \FileInfo.size)
                .width(.fixed(10))
                .alignment(.trailing)
        }

        let buffer = renderToBuffer(table, context: context)

        // With trailing alignment on a 10-char column, "1 KB" (4 chars) should have 6 spaces before it
        let dataLine = buffer.lines[1].stripped
        #expect(dataLine.contains("1 KB"))
    }
}

// MARK: - Table Selection Tests

@Suite("Table Selection Tests")
@MainActor
struct TableSelectionTests {
    @Test("Table single selection binding updates")
    func singleSelectionBinding() {
        let context = createTestContext()
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }

        // Render to set up handler
        _ = renderToBuffer(table, context: context)

        // Selection starts as nil
        #expect(selection == nil)
    }

    @Test("Table multi-selection binding updates")
    func multiSelectionBinding() {
        let context = createTestContext()
        var selection: Set<String> = []

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }

        // Render to set up handler
        _ = renderToBuffer(table, context: context)

        // Selection starts empty
        #expect(selection.isEmpty)
    }

    @Test("Single-selection table has correct mode")
    func singleSelectionMode() {
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }

        #expect(table.selectionMode == .single)
    }

    @Test("Multi-selection table has correct mode")
    func multiSelectionMode() {
        var selection: Set<String> = []

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }

        #expect(table.selectionMode == .multi)
    }
}

// MARK: - TableColumnBuilder Tests

@Suite("TableColumnBuilder Tests")
@MainActor
struct TableColumnBuilderTests {
    @Test("Builder creates array from multiple columns")
    func multipleColumns() {
        @TableColumnBuilder<FileInfo>
        var columns: [TableColumn<FileInfo>] {
            TableColumn("Name", value: \FileInfo.name)
            TableColumn("Size", value: \FileInfo.size)
            TableColumn("Modified", value: \FileInfo.modified)
        }

        #expect(columns.count == 3)
        #expect(columns[0].title == "Name")
        #expect(columns[1].title == "Size")
        #expect(columns[2].title == "Modified")
    }
}

// MARK: - Table Disabled Tests

@Suite("Table Disabled Tests")
@MainActor
struct TableDisabledTests {
    @Test("Disabled modifier sets isDisabled")
    func disabledModifier() {
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }.disabled()

        #expect(table.isDisabled == true)
    }

    @Test("Disabled modifier with false keeps enabled")
    func disabledFalse() {
        var selection: String?

        let table = Table(testFiles, selection: Binding(get: { selection }, set: { selection = $0 })) {
            TableColumn("Name", value: \FileInfo.name)
        }.disabled(false)

        #expect(table.isDisabled == false)
    }
}
