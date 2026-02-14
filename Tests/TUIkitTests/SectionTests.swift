//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SectionTests.swift
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
        environment: environment,
        tuiContext: TUIContext()
    )
}

// MARK: - Section Rendering Tests

@MainActor
@Suite("Section Rendering Tests")
struct SectionRenderingTests {

    @Test("Section renders header text")
    func sectionRendersHeader() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("My Header")
        }

        let buffer = renderToBuffer(section, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("My Header"))
        #expect(content.contains("Content"))
    }

    @Test("Section renders footer text")
    func sectionRendersFooter() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } footer: {
            Text("My Footer")
        }

        let buffer = renderToBuffer(section, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("My Footer"))
        #expect(content.contains("Content"))
    }

    @Test("Section renders header and footer")
    func sectionRendersHeaderAndFooter() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        } footer: {
            Text("Footer")
        }

        let buffer = renderToBuffer(section, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Header"))
        #expect(content.contains("Content"))
        #expect(content.contains("Footer"))
    }

    @Test("Section with string title convenience initializer")
    func sectionWithStringTitle() {
        let context = createTestContext()

        let section = Section("Settings") {
            Text("Content")
        }

        let buffer = renderToBuffer(section, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Settings"))
        #expect(content.contains("Content"))
    }

    @Test("Section header is styled with dim")
    func sectionHeaderIsDim() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        }

        let buffer = renderToBuffer(section, context: context)
        let headerLine = buffer.lines.first ?? ""

        // Dim ANSI code is SGR 2
        #expect(headerLine.contains("\u{1B}["))
        #expect(headerLine.contains("2"))
    }

    @Test("Section content only (no header/footer)")
    func sectionContentOnly() {
        let context = createTestContext()

        let section = Section {
            Text("Just content")
        }

        let buffer = renderToBuffer(section, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Just content"))
        // Should have minimal output (just the content)
        #expect(buffer.height == 1)
    }
}

// MARK: - Section Structure Tests

@MainActor
@Suite("Section Structure Tests")
struct SectionStructureTests {

    @Test("Header appears before content")
    func headerAppearsBeforeContent() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        }

        let buffer = renderToBuffer(section, context: context)

        // Find positions
        let headerIndex = buffer.lines.firstIndex { $0.stripped.contains("Header") } ?? -1
        let contentIndex = buffer.lines.firstIndex { $0.stripped.contains("Content") } ?? -1

        #expect(headerIndex < contentIndex, "Header should appear before content")
    }

    @Test("Footer appears after content")
    func footerAppearsAfterContent() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } footer: {
            Text("Footer")
        }

        let buffer = renderToBuffer(section, context: context)

        // Find positions
        let contentIndex = buffer.lines.firstIndex { $0.stripped.contains("Content") } ?? -1
        let footerIndex = buffer.lines.firstIndex { $0.stripped.contains("Footer") } ?? -1

        #expect(contentIndex < footerIndex, "Content should appear before footer")
    }

    @Test("Order is header, content, footer")
    func correctOrderHeaderContentFooter() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        } footer: {
            Text("Footer")
        }

        let buffer = renderToBuffer(section, context: context)

        let headerIndex = buffer.lines.firstIndex { $0.stripped.contains("Header") } ?? -1
        let contentIndex = buffer.lines.firstIndex { $0.stripped.contains("Content") } ?? -1
        let footerIndex = buffer.lines.firstIndex { $0.stripped.contains("Footer") } ?? -1

        #expect(headerIndex < contentIndex, "Header should be first")
        #expect(contentIndex < footerIndex, "Footer should be last")
    }
}

// MARK: - Section Info Extraction Tests

@MainActor
@Suite("Section Info Extraction Tests")
struct SectionInfoExtractionTests {

    @Test("extractSectionInfo returns header buffer")
    func extractSectionInfoHeader() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.headerBuffer != nil)
        #expect(info.headerBuffer?.lines.joined().stripped.contains("Header") == true)
    }

    @Test("extractSectionInfo returns footer buffer")
    func extractSectionInfoFooter() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } footer: {
            Text("Footer")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.footerBuffer != nil)
        #expect(info.footerBuffer?.lines.joined().stripped.contains("Footer") == true)
    }

    @Test("extractSectionInfo returns nil for empty header")
    func extractSectionInfoEmptyHeader() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.headerBuffer == nil)
    }

    @Test("extractSectionInfo returns nil for empty footer")
    func extractSectionInfoEmptyFooter() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.footerBuffer == nil)
    }

    @Test("extractSectionInfo content buffer contains content")
    func extractSectionInfoContent() {
        let context = createTestContext()

        let section = Section("Title") {
            Text("My Content Here")
        }

        let info = section.extractSectionInfo(context: context)

        #expect(info.contentBuffer.lines.joined().contains("My Content Here"))
    }
}

// MARK: - Section as ChildInfoProvider Tests

@MainActor
@Suite("Section ChildInfoProvider Tests")
struct SectionChildInfoProviderTests {

    @Test("Section provides single ChildInfo")
    func sectionProvidesChildInfo() {
        let context = createTestContext()

        let section = Section("Title") {
            Text("Content")
        }

        let infos = section.childInfos(context: context)

        #expect(infos.count == 1)
        #expect(infos[0].isSpacer == false)
        #expect(infos[0].buffer != nil)
    }

    @Test("Section ChildInfo buffer contains all parts")
    func sectionChildInfoContainsAllParts() {
        let context = createTestContext()

        let section = Section {
            Text("Content")
        } header: {
            Text("Header")
        } footer: {
            Text("Footer")
        }

        let infos = section.childInfos(context: context)
        let content = infos[0].buffer?.lines.joined() ?? ""

        #expect(content.contains("Header"))
        #expect(content.contains("Content"))
        #expect(content.contains("Footer"))
    }
}
