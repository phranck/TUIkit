//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextFieldHandler+Clipboard.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Clipboard Operations

extension TextFieldHandler {
    /// Selects all text in the field.
    func selectAll() {
        guard !text.wrappedValue.isEmpty else { return }
        selectionAnchor = 0
        cursorPosition = text.wrappedValue.count
    }

    /// Copies the selected text to the system clipboard.
    ///
    /// Uses `pbcopy` on macOS. Does nothing if no text is selected.
    func copySelection() {
        guard let range = selectionRange else { return }

        let current = text.wrappedValue
        let startIndex = current.index(current.startIndex, offsetBy: range.lowerBound)
        let endIndex = current.index(current.startIndex, offsetBy: range.upperBound)
        let selectedText = String(current[startIndex..<endIndex])

        copyToClipboard(selectedText)
    }

    /// Cuts the selected text to the system clipboard.
    ///
    /// Uses `pbcopy` on macOS. Does nothing if no text is selected.
    func cutSelection() {
        guard let range = selectionRange else { return }

        let current = text.wrappedValue
        let startIndex = current.index(current.startIndex, offsetBy: range.lowerBound)
        let endIndex = current.index(current.startIndex, offsetBy: range.upperBound)
        let selectedText = String(current[startIndex..<endIndex])

        copyToClipboard(selectedText)
        pushUndoState()
        deleteRangeWithoutUndo(range)
        clearSelection()
    }

    /// Pastes text from the system clipboard at the cursor position.
    ///
    /// Uses `pbpaste` on macOS. Replaces selection if any.
    func paste() {
        guard let pastedText = pasteFromClipboard() else { return }
        insertText(pastedText)
    }

    /// Inserts a string at the cursor position in a single operation.
    ///
    /// Used by both clipboard paste (`Ctrl+V`) and bracketed paste
    /// (terminal paste via `Cmd+V`). Replaces selection if any.
    ///
    /// - Parameter string: The text to insert.
    func insertText(_ string: String) {
        guard !string.isEmpty else { return }

        // For single-line text fields, strip newlines from pasted text.
        var sanitized = string.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        // Filter by content type if set.
        if let contentType = textContentType {
            sanitized = contentType.filterString(sanitized)
        }
        guard !sanitized.isEmpty else { return }

        pushUndoState()

        // Replace selection if present
        if let range = selectionRange {
            deleteRangeWithoutUndo(range)
            clearSelection()
        }

        // Insert text
        var current = text.wrappedValue
        let index = current.index(current.startIndex, offsetBy: min(cursorPosition, current.count))
        current.insert(contentsOf: sanitized, at: index)
        text.wrappedValue = current
        cursorPosition += sanitized.count
    }
}

// MARK: - Clipboard Helpers

private extension TextFieldHandler {
    /// Copies text to the system clipboard using platform-specific command.
    func copyToClipboard(_ text: String) {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pbcopy")

        let pipe = Pipe()
        process.standardInput = pipe

        do {
            try process.run()
            pipe.fileHandleForWriting.write(Data(text.utf8))
            pipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()
        } catch {
            // Silently fail if clipboard is unavailable
        }
        #elseif os(Linux)
        // Try xclip first, then xsel
        for command in ["/usr/bin/xclip", "/usr/bin/xsel"] where FileManager.default.fileExists(atPath: command) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = command.contains("xclip") ? ["-selection", "clipboard"] : ["--clipboard", "--input"]

            let pipe = Pipe()
            process.standardInput = pipe

            do {
                try process.run()
                pipe.fileHandleForWriting.write(Data(text.utf8))
                pipe.fileHandleForWriting.closeFile()
                process.waitUntilExit()
                return
            } catch {
                continue
            }
        }
        #endif
    }

    /// Pastes text from the system clipboard using platform-specific command.
    func pasteFromClipboard() -> String? {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pbpaste")

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            // Strip trailing newline that pbpaste adds
            var result = String(data: data, encoding: .utf8) ?? ""
            if result.hasSuffix("\n") {
                result.removeLast()
            }
            return result
        } catch {
            return nil
        }
        #elseif os(Linux)
        // Try xclip first, then xsel
        for command in ["/usr/bin/xclip", "/usr/bin/xsel"] where FileManager.default.fileExists(atPath: command) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = command.contains("xclip") ? ["-selection", "clipboard", "-o"] : ["--clipboard", "--output"]

            let pipe = Pipe()
            process.standardOutput = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                var result = String(data: data, encoding: .utf8) ?? ""
                if result.hasSuffix("\n") {
                    result.removeLast()
                }
                return result
            } catch {
                continue
            }
        }
        return nil
        #else
        return nil
        #endif
    }
}
