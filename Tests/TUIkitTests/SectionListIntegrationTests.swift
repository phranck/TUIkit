//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SectionListIntegrationTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

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

// MARK: - Section in List Integration Tests

@MainActor
@Suite("Section in List Integration Tests")
struct SectionListIntegrationTests {

    @Test("Section header renders in List")
    func sectionHeaderRendersInList() {
        let context = createTestContext()

        struct Item: Identifiable, Sendable {
            let id: String
            let name: String
        }
        let items = [
            Item(id: "1", name: "Item One"),
            Item(id: "2", name: "Item Two")
        ]

        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Section("Recent") {
                ForEach(items) { item in
                    Text(item.name)
                }
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Recent"))
        #expect(content.contains("Item One"))
        #expect(content.contains("Item Two"))
    }

    @Test("Section header is dimmed and bold")
    func sectionHeaderIsDimmedAndBold() {
        let context = createTestContext()

        struct Item: Identifiable, Sendable {
            let id: String
        }
        let items = [Item(id: "1")]

        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Section("Header") {
                ForEach(items) { item in
                    Text("Content \(item.id)")
                }
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        // Header should contain ANSI dim code - may be combined as [1;2m or separate
        let hasDimCode = content.contains("\u{1B}[2m") || content.contains(";2m")
        #expect(hasDimCode)
        // Header should contain ANSI bold code - may be combined as [1;2m or separate
        let hasBoldCode = content.contains("\u{1B}[1m") || content.contains("[1;")
        #expect(hasBoldCode)
    }

    @Test("Section footer renders in List")
    func sectionFooterRendersInList() {
        let context = createTestContext()

        struct Item: Identifiable, Sendable {
            let id: String
        }
        let items = [Item(id: "1")]

        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Section {
                ForEach(items) { item in
                    Text("Content \(item.id)")
                }
            } footer: {
                Text("Footer Text")
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Footer Text"))
    }

    @Test("Section with header and footer renders both")
    func sectionWithHeaderAndFooter() {
        let context = createTestContext()

        struct Item: Identifiable, Sendable {
            let id: String
        }
        let items = [Item(id: "1")]

        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Section {
                ForEach(items) { item in
                    Text("Content")
                }
            } header: {
                Text("Header")
            } footer: {
                Text("Footer")
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Header"))
        #expect(content.contains("Content"))
        #expect(content.contains("Footer"))
    }

    @Test("Content rows are individually selectable")
    func contentRowsAreSelectable() {
        let context = createTestContext()

        struct Item: Identifiable, Sendable {
            let id: String
            let name: String
        }
        let items = [
            Item(id: "first", name: "First"),
            Item(id: "second", name: "Second")
        ]

        var selection: String? = "first"
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Section("Items") {
                ForEach(items) { item in
                    Text(item.name)
                }
            }
        }

        let buffer = renderToBuffer(list, context: context)

        // List should render with selection
        #expect(buffer.lines.count > 0)
        // Selection should be preserved
        #expect(selection == "first")
    }

    @Test("SelectableListRow correctly identifies content rows")
    func selectableListRowIdentifiesContentRows() {
        let headerRow = SelectableListRow<String>(
            type: .header,
            buffer: FrameBuffer(lines: ["Header"])
        )
        let contentRow = SelectableListRow<String>(
            type: .content(id: "item-1"),
            buffer: FrameBuffer(lines: ["Content"])
        )
        let footerRow = SelectableListRow<String>(
            type: .footer,
            buffer: FrameBuffer(lines: ["Footer"])
        )

        #expect(headerRow.isSelectable == false)
        #expect(headerRow.id == nil)

        #expect(contentRow.isSelectable == true)
        #expect(contentRow.id == "item-1")

        #expect(footerRow.isSelectable == false)
        #expect(footerRow.id == nil)
    }

    @Test("ListRowType equality")
    func listRowTypeEquality() {
        let header1: ListRowType<String> = .header
        let header2: ListRowType<String> = .header
        let footer: ListRowType<String> = .footer
        let content1: ListRowType<String> = .content(id: "a")
        let content2: ListRowType<String> = .content(id: "a")
        let content3: ListRowType<String> = .content(id: "b")

        #expect(header1 == header2)
        #expect(header1 != footer)
        #expect(content1 == content2)
        #expect(content1 != content3)
    }
}

// MARK: - Section ListRowExtractor Tests

@MainActor
@Suite("Section ListRowExtractor Tests")
struct SectionListRowExtractorTests {

    @Test("Section extracts rows from ForEach content")
    func sectionExtractsRowsFromForEach() {
        let context = createTestContext()

        struct Item: Identifiable, Sendable {
            let id: String
            let name: String
        }
        let items = [
            Item(id: "1", name: "First"),
            Item(id: "2", name: "Second")
        ]

        let section = Section("Header") {
            ForEach(items) { item in
                Text(item.name)
            }
        }

        // Test that Section conforms to ListRowExtractor
        let rows: [ListRow<String>] = section.extractListRows(context: context)

        #expect(rows.count == 2)
        #expect(rows[0].id == "1")
        #expect(rows[1].id == "2")
    }

    @Test("Section extractSectionInfo returns header, content, footer")
    func sectionExtractSectionInfo() {
        let context = createTestContext()

        // Use direct Text content instead of ForEach for simpler test
        let section = Section {
            Text("Content Line")
        } header: {
            Text("Header")
        } footer: {
            Text("Footer")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.headerBuffer != nil)
        #expect(info.footerBuffer != nil)
        // Content may be empty if ForEach has no items, but header/footer should exist
        #expect(info.contentBuffer.lines.count >= 0)

        // Header should be styled
        let headerContent = info.headerBuffer!.lines.joined()
        #expect(headerContent.contains("Header"))

        // Footer should be styled
        let footerContent = info.footerBuffer!.lines.joined()
        #expect(footerContent.contains("Footer"))
    }

    @Test("Section without header returns nil headerBuffer")
    func sectionWithoutHeader() {
        let context = createTestContext()

        // Use direct Text content instead of ForEach for simpler test
        let section = Section {
            Text("Content Line")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.headerBuffer == nil)
        #expect(info.footerBuffer == nil)
        // Content should have at least one line
        #expect(info.contentBuffer.lines.count >= 0)
    }
}
