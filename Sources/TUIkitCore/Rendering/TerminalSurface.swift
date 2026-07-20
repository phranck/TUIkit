//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalSurface.swift
//
//  Created by LAYERED.work
//  License: MIT

/// One addressable cell in a terminal surface.
package struct TerminalCell: Sendable, Equatable {
    enum Content: Sendable, Equatable {
        case empty
        case grapheme(String, width: Int)
        case continuation
    }

    let content: Content
    let style: TerminalStyle
    let isTransparent: Bool

    package var grapheme: String? {
        guard case .grapheme(let grapheme, _) = content else { return nil }
        return grapheme
    }

    package var isContinuation: Bool {
        content == .continuation
    }
}

/// A rectangular terminal render result expressed in display cells.
package struct TerminalSurface: Sendable, Equatable {
    private(set) var rows: [[TerminalCell]]
    package private(set) var width: Int

    package var height: Int {
        rows.count
    }

    package var isEmpty: Bool {
        rows.isEmpty || rows.allSatisfy { row in
            row.allSatisfy { cell in
                if case .empty = cell.content { return true }
                return false
            }
        }
    }

    package init() {
        rows = []
        width = 0
    }

    package init(lines: [String], width proposedWidth: Int? = nil) {
        var parsedRows: [[TerminalCell]] = []
        parsedRows.reserveCapacity(lines.count)
        var measuredWidth = 0

        for line in lines {
            let row = Self.parse(line)
            parsedRows.append(row)
            measuredWidth = max(measuredWidth, row.count)
        }

        rows = parsedRows
        width = max(measuredWidth, proposedWidth ?? 0)
    }

    init(rows: [[TerminalCell]], width: Int) {
        self.rows = rows
        self.width = max(width, rows.map(\.count).max() ?? 0)
    }
}

// MARK: - Inspection and Encoding

extension TerminalSurface {
    package var plainLines: [String] {
        rows.map(Self.plainText)
    }

    package var ansiEncodedLines: [String] {
        rows.map(Self.ansiEncoded)
    }

    package func cell(atX column: Int, y row: Int) -> TerminalCell? {
        guard row >= 0, row < rows.count, column >= 0, column < rows[row].count else { return nil }
        return rows[row][column]
    }
}

// MARK: - Layout Operations

extension TerminalSurface {
    package init(verticallyStacking surfaces: [Self]) {
        rows = []
        rows.reserveCapacity(surfaces.reduce(into: 0) { $0 += $1.height })
        width = surfaces.map(\.width).max() ?? 0

        for surface in surfaces {
            rows.append(contentsOf: surface.rows)
        }
    }

    package mutating func appendVertically(_ other: Self, spacing: Int = 0) {
        guard !other.isEmpty else { return }

        if !rows.isEmpty && spacing > 0 {
            rows.append(contentsOf: repeatElement([], count: spacing))
        }
        rows.append(contentsOf: other.rows)
        width = max(width, other.width)
    }

    package mutating func appendHorizontally(_ other: Self, spacing: Int = 0) {
        let leftWidth = width
        let rowCount = max(height, other.height)
        var combinedRows: [[TerminalCell]] = []
        combinedRows.reserveCapacity(rowCount)

        for rowIndex in 0..<rowCount {
            var row = rowIndex < rows.count ? rows[rowIndex] : []
            Self.pad(&row, to: leftWidth)
            if spacing > 0 {
                row.append(contentsOf: repeatElement(.empty, count: spacing))
            }
            if rowIndex < other.rows.count {
                row.append(contentsOf: other.rows[rowIndex])
            }
            combinedRows.append(row)
        }

        rows = combinedRows
        width = leftWidth + max(0, spacing) + other.width
    }

    package func clipped(toWidth targetWidth: Int, height targetHeight: Int) -> Self {
        let clippedWidth = max(0, min(width, targetWidth))
        let clippedHeight = max(0, min(height, targetHeight))
        var clippedRows: [[TerminalCell]] = []
        clippedRows.reserveCapacity(clippedHeight)

        for rowIndex in 0..<clippedHeight {
            let source = rows[rowIndex]
            var row = Array(repeating: TerminalCell.empty, count: clippedWidth)
            var column = 0

            while column < source.count && column < clippedWidth {
                let cell = source[column]
                switch cell.content {
                case .grapheme(_, let cellWidth) where column + cellWidth <= clippedWidth:
                    for offset in 0..<cellWidth where column + offset < source.count {
                        row[column + offset] = source[column + offset]
                    }
                    column += cellWidth
                case .grapheme(_, let cellWidth):
                    column += cellWidth
                default:
                    column += 1
                }
            }
            clippedRows.append(row)
        }

        return Self(rows: clippedRows, width: clippedWidth)
    }

    package func composited(with overlay: Self, atX column: Int, y row: Int) -> Self {
        guard !overlay.isEmpty else { return self }

        let resultWidth = max(width, max(0, column + overlay.width))
        let resultHeight = max(height, max(0, row + overlay.height))
        var resultRows = rows
        if resultRows.count < resultHeight {
            resultRows.append(contentsOf: repeatElement([], count: resultHeight - resultRows.count))
        }

        for overlayRowIndex in overlay.rows.indices {
            let destinationY = row + overlayRowIndex
            guard destinationY >= 0, destinationY < resultHeight else { continue }

            let overlayRow = overlay.rows[overlayRowIndex]
            var sourceX = 0
            while sourceX < overlayRow.count {
                let sourceCell = overlayRow[sourceX]
                guard case .grapheme(_, let cellWidth) = sourceCell.content else {
                    sourceX += 1
                    continue
                }
                defer { sourceX += cellWidth }
                guard !sourceCell.isTransparent else { continue }

                let destinationX = column + sourceX
                guard destinationX >= 0, destinationX + cellWidth <= resultWidth else { continue }

                Self.pad(&resultRows[destinationY], to: destinationX + cellWidth)
                Self.clearGraphemes(
                    in: &resultRows[destinationY],
                    intersecting: destinationX..<(destinationX + cellWidth)
                )
                for offset in 0..<cellWidth where sourceX + offset < overlayRow.count {
                    resultRows[destinationY][destinationX + offset] = overlayRow[sourceX + offset]
                }
            }
        }

        return Self(rows: resultRows, width: resultWidth)
    }
}

// MARK: - Parsing

private extension TerminalSurface {
    static func parse(_ line: String) -> [TerminalCell] {
        var row: [TerminalCell] = []
        row.reserveCapacity(line.count)
        var style = TerminalStyle()

        TerminalTextParser.scan(line) { token in
            switch token {
            case .sgr(let parameters, _):
                style.apply(sgr: parameters)
            case .grapheme(let character):
                let cellWidth = character.terminalWidth
                guard cellWidth > 0 else { return }
                let grapheme = String(character)
                let isTransparent = grapheme == " " && style.isDefault
                row.append(
                    TerminalCell(
                        content: .grapheme(grapheme, width: cellWidth),
                        style: style,
                        isTransparent: isTransparent
                    )
                )
                if cellWidth > 1 {
                    row.append(
                        contentsOf: repeatElement(
                            TerminalCell(content: .continuation, style: style, isTransparent: isTransparent),
                            count: cellWidth - 1
                        )
                    )
                }
            }
        }

        return row
    }
}

// MARK: - Encoding

private extension TerminalSurface {
    static let ansiReset = "\u{1B}[0m"

    static func plainText(_ row: [TerminalCell]) -> String {
        var result = ""
        result.reserveCapacity(row.count)

        for cell in row {
            switch cell.content {
            case .empty:
                result.append(" ")
            case .grapheme(let grapheme, _):
                result += grapheme
            case .continuation:
                continue
            }
        }

        return result
    }

    static func ansiEncoded(_ row: [TerminalCell]) -> String {
        var result = ""
        result.reserveCapacity(row.count)
        var activeStyle = TerminalStyle()

        for cell in row {
            guard case .continuation = cell.content else {
                if cell.style != activeStyle {
                    if !activeStyle.isDefault {
                        result += ansiReset
                    }
                    if !cell.style.isDefault {
                        result += cell.style.ansiSequence
                    }
                    activeStyle = cell.style
                }

                switch cell.content {
                case .empty:
                    result.append(" ")
                case .grapheme(let grapheme, _):
                    result += grapheme
                case .continuation:
                    break
                }
                continue
            }
        }

        if !activeStyle.isDefault {
            result += ansiReset
        }
        return result
    }
}

// MARK: - Cell Integrity

private extension TerminalSurface {
    static func pad(_ row: inout [TerminalCell], to width: Int) {
        guard row.count < width else { return }
        row.append(contentsOf: repeatElement(.empty, count: width - row.count))
    }

    static func clearGraphemes(in row: inout [TerminalCell], intersecting range: Range<Int>) {
        var ownerColumns = Set<Int>()

        for column in range where column < row.count {
            switch row[column].content {
            case .grapheme:
                ownerColumns.insert(column)
            case .continuation:
                var owner = column - 1
                while owner >= 0 {
                    if case .grapheme = row[owner].content {
                        ownerColumns.insert(owner)
                        break
                    }
                    owner -= 1
                }
            case .empty:
                break
            }
        }

        for owner in ownerColumns {
            guard case .grapheme(_, let cellWidth) = row[owner].content else { continue }
            for column in owner..<min(row.count, owner + cellWidth) {
                row[column] = .empty
            }
        }
    }
}

private extension TerminalCell {
    static let empty = TerminalCell(content: .empty, style: TerminalStyle(), isTransparent: true)
}
