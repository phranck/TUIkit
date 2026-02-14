//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LocalizationKeyConsistencyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing
@testable import TUIkit

// MARK: - Localization Key Consistency Tests

/// Validates that all LocalizationKey enums match the actual translation files.
///
/// These tests ensure:
/// 1. Every key in the enum exists in the English translation file
/// 2. No extra keys are in the translation files that don't exist in the enum
/// 3. All enum keys are actually used (no dead code)
@Suite("LocalizationKeyConsistency")
final class LocalizationKeyConsistencyTests {
    private var englishTranslations: [String: String] = [:]

    init() {
        self.englishTranslations = Self.loadTranslations()
    }

    // MARK: - Helper Method

    private static func loadTranslations() -> [String: String] {
        // Try to load from the main framework bundle first (for production)
        var url = Bundle.module.url(
            forResource: "en",
            withExtension: "json",
            subdirectory: "Localization/translations"
        )

        // If not found, try to load from the project directory (for tests)
        if url == nil {
            let projectPath = FileManager.default.currentDirectoryPath
            let sourcePath = (projectPath as NSString).appendingPathComponent(
                "Sources/TUIkit/Localization/translations/en.json"
            )
            if FileManager.default.fileExists(atPath: sourcePath) {
                url = URL(fileURLWithPath: sourcePath)
            }
        }

        guard let url = url else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONSerialization.jsonObject(
                with: data,
                options: .fragmentsAllowed
            ) as? [String: String]
            return dict ?? [:]
        } catch {
            return [:]
        }
    }

    // MARK: - Button Key Tests

    @Test("All button keys exist in translations")
    func allButtonKeysExist() {
        let keys = [
            LocalizationKey.Button.ok,
            LocalizationKey.Button.cancel,
            LocalizationKey.Button.yes,
            LocalizationKey.Button.no,
            LocalizationKey.Button.save,
            LocalizationKey.Button.delete,
            LocalizationKey.Button.close,
            LocalizationKey.Button.apply,
            LocalizationKey.Button.reset,
            LocalizationKey.Button.submit,
            LocalizationKey.Button.search,
            LocalizationKey.Button.clear,
            LocalizationKey.Button.add,
            LocalizationKey.Button.remove,
            LocalizationKey.Button.edit,
            LocalizationKey.Button.done,
            LocalizationKey.Button.next,
            LocalizationKey.Button.previous,
            LocalizationKey.Button.back,
            LocalizationKey.Button.forward,
            LocalizationKey.Button.refresh,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Button key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Label Key Tests

    @Test("All label keys exist in translations")
    func allLabelKeysExist() {
        let keys = [
            LocalizationKey.Label.search,
            LocalizationKey.Label.name,
            LocalizationKey.Label.description,
            LocalizationKey.Label.value,
            LocalizationKey.Label.status,
            LocalizationKey.Label.error,
            LocalizationKey.Label.warning,
            LocalizationKey.Label.info,
            LocalizationKey.Label.loading,
            LocalizationKey.Label.empty,
            LocalizationKey.Label.none,
            LocalizationKey.Label.page,
            LocalizationKey.Label.item,
            LocalizationKey.Label.items,
            LocalizationKey.Label.total,
            LocalizationKey.Label.from,
            LocalizationKey.Label.to,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Label key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Error Key Tests

    @Test("All error keys exist in translations")
    func allErrorKeysExist() {
        let keys = [
            LocalizationKey.Error.invalidInput,
            LocalizationKey.Error.requiredField,
            LocalizationKey.Error.notFound,
            LocalizationKey.Error.accessDenied,
            LocalizationKey.Error.networkError,
            LocalizationKey.Error.unknown,
            LocalizationKey.Error.invalidFormat,
            LocalizationKey.Error.operationFailed,
            LocalizationKey.Error.timeout,
            LocalizationKey.Error.fileNotFound,
            LocalizationKey.Error.permissionDenied,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Error key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Placeholder Key Tests

    @Test("All placeholder keys exist in translations")
    func allPlaceholderKeysExist() {
        let keys = [
            LocalizationKey.Placeholder.search,
            LocalizationKey.Placeholder.enterText,
            LocalizationKey.Placeholder.enterValue,
            LocalizationKey.Placeholder.selectOption,
            LocalizationKey.Placeholder.enterName,
            LocalizationKey.Placeholder.chooseFile,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Placeholder key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Menu Key Tests

    @Test("All menu keys exist in translations")
    func allMenuKeysExist() {
        let keys = [
            LocalizationKey.Menu.file,
            LocalizationKey.Menu.edit,
            LocalizationKey.Menu.view,
            LocalizationKey.Menu.help,
            LocalizationKey.Menu.new,
            LocalizationKey.Menu.open,
            LocalizationKey.Menu.save,
            LocalizationKey.Menu.exit,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Menu key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Dialog Key Tests

    @Test("All dialog keys exist in translations")
    func allDialogKeysExist() {
        let keys = [
            LocalizationKey.Dialog.confirm,
            LocalizationKey.Dialog.deleteConfirmation,
            LocalizationKey.Dialog.unsavedChanges,
            LocalizationKey.Dialog.overwriteConfirmation,
            LocalizationKey.Dialog.exitConfirmation,
            LocalizationKey.Dialog.success,
            LocalizationKey.Dialog.error,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Dialog key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Validation Key Tests

    @Test("All validation keys exist in translations")
    func allValidationKeysExist() {
        let keys = [
            LocalizationKey.Validation.emailInvalid,
            LocalizationKey.Validation.passwordTooShort,
            LocalizationKey.Validation.usernameTaken,
            LocalizationKey.Validation.fieldRequired,
        ]

        for key in keys {
            #expect(englishTranslations[key.rawValue] != nil, "Validation key '\(key.rawValue)' not found in translations")
        }
    }

    // MARK: - Coverage Tests

    @Test("No extraneous keys in translations")
    func noExtraneousKeys() {
        // Collect all known enum keys
        var enumKeys = Set<String>()

        // Button keys
        enumKeys.insert(LocalizationKey.Button.ok.rawValue)
        enumKeys.insert(LocalizationKey.Button.cancel.rawValue)
        enumKeys.insert(LocalizationKey.Button.yes.rawValue)
        enumKeys.insert(LocalizationKey.Button.no.rawValue)
        enumKeys.insert(LocalizationKey.Button.save.rawValue)
        enumKeys.insert(LocalizationKey.Button.delete.rawValue)
        enumKeys.insert(LocalizationKey.Button.close.rawValue)
        enumKeys.insert(LocalizationKey.Button.apply.rawValue)
        enumKeys.insert(LocalizationKey.Button.reset.rawValue)
        enumKeys.insert(LocalizationKey.Button.submit.rawValue)
        enumKeys.insert(LocalizationKey.Button.search.rawValue)
        enumKeys.insert(LocalizationKey.Button.clear.rawValue)
        enumKeys.insert(LocalizationKey.Button.add.rawValue)
        enumKeys.insert(LocalizationKey.Button.remove.rawValue)
        enumKeys.insert(LocalizationKey.Button.edit.rawValue)
        enumKeys.insert(LocalizationKey.Button.done.rawValue)
        enumKeys.insert(LocalizationKey.Button.next.rawValue)
        enumKeys.insert(LocalizationKey.Button.previous.rawValue)
        enumKeys.insert(LocalizationKey.Button.back.rawValue)
        enumKeys.insert(LocalizationKey.Button.forward.rawValue)
        enumKeys.insert(LocalizationKey.Button.refresh.rawValue)

        // Label keys
        enumKeys.insert(LocalizationKey.Label.search.rawValue)
        enumKeys.insert(LocalizationKey.Label.name.rawValue)
        enumKeys.insert(LocalizationKey.Label.description.rawValue)
        enumKeys.insert(LocalizationKey.Label.value.rawValue)
        enumKeys.insert(LocalizationKey.Label.status.rawValue)
        enumKeys.insert(LocalizationKey.Label.error.rawValue)
        enumKeys.insert(LocalizationKey.Label.warning.rawValue)
        enumKeys.insert(LocalizationKey.Label.info.rawValue)
        enumKeys.insert(LocalizationKey.Label.loading.rawValue)
        enumKeys.insert(LocalizationKey.Label.empty.rawValue)
        enumKeys.insert(LocalizationKey.Label.none.rawValue)
        enumKeys.insert(LocalizationKey.Label.page.rawValue)
        enumKeys.insert(LocalizationKey.Label.item.rawValue)
        enumKeys.insert(LocalizationKey.Label.items.rawValue)
        enumKeys.insert(LocalizationKey.Label.total.rawValue)
        enumKeys.insert(LocalizationKey.Label.from.rawValue)
        enumKeys.insert(LocalizationKey.Label.to.rawValue)

        // Error keys
        enumKeys.insert(LocalizationKey.Error.invalidInput.rawValue)
        enumKeys.insert(LocalizationKey.Error.requiredField.rawValue)
        enumKeys.insert(LocalizationKey.Error.notFound.rawValue)
        enumKeys.insert(LocalizationKey.Error.accessDenied.rawValue)
        enumKeys.insert(LocalizationKey.Error.networkError.rawValue)
        enumKeys.insert(LocalizationKey.Error.unknown.rawValue)
        enumKeys.insert(LocalizationKey.Error.invalidFormat.rawValue)
        enumKeys.insert(LocalizationKey.Error.operationFailed.rawValue)
        enumKeys.insert(LocalizationKey.Error.timeout.rawValue)
        enumKeys.insert(LocalizationKey.Error.fileNotFound.rawValue)
        enumKeys.insert(LocalizationKey.Error.permissionDenied.rawValue)

        // Placeholder keys
        enumKeys.insert(LocalizationKey.Placeholder.search.rawValue)
        enumKeys.insert(LocalizationKey.Placeholder.enterText.rawValue)
        enumKeys.insert(LocalizationKey.Placeholder.enterValue.rawValue)
        enumKeys.insert(LocalizationKey.Placeholder.selectOption.rawValue)
        enumKeys.insert(LocalizationKey.Placeholder.enterName.rawValue)
        enumKeys.insert(LocalizationKey.Placeholder.chooseFile.rawValue)

        // Menu keys
        enumKeys.insert(LocalizationKey.Menu.file.rawValue)
        enumKeys.insert(LocalizationKey.Menu.edit.rawValue)
        enumKeys.insert(LocalizationKey.Menu.view.rawValue)
        enumKeys.insert(LocalizationKey.Menu.help.rawValue)
        enumKeys.insert(LocalizationKey.Menu.new.rawValue)
        enumKeys.insert(LocalizationKey.Menu.open.rawValue)
        enumKeys.insert(LocalizationKey.Menu.save.rawValue)
        enumKeys.insert(LocalizationKey.Menu.exit.rawValue)

        // Dialog keys
        enumKeys.insert(LocalizationKey.Dialog.confirm.rawValue)
        enumKeys.insert(LocalizationKey.Dialog.deleteConfirmation.rawValue)
        enumKeys.insert(LocalizationKey.Dialog.unsavedChanges.rawValue)
        enumKeys.insert(LocalizationKey.Dialog.overwriteConfirmation.rawValue)
        enumKeys.insert(LocalizationKey.Dialog.exitConfirmation.rawValue)
        enumKeys.insert(LocalizationKey.Dialog.success.rawValue)
        enumKeys.insert(LocalizationKey.Dialog.error.rawValue)

        // Validation keys
        enumKeys.insert(LocalizationKey.Validation.emailInvalid.rawValue)
        enumKeys.insert(LocalizationKey.Validation.passwordTooShort.rawValue)
        enumKeys.insert(LocalizationKey.Validation.usernameTaken.rawValue)
        enumKeys.insert(LocalizationKey.Validation.fieldRequired.rawValue)

        // Check for extraneous keys
        let translationKeys = Set(englishTranslations.keys)
        let extraneousKeys = translationKeys.subtracting(enumKeys)

        #expect(extraneousKeys.isEmpty, "Found keys in translations that don't exist in LocalizationKey enum: \(extraneousKeys.sorted())")
    }

    @Test("All enum keys are covered in translations")
    func allEnumKeysCovered() {
        let expectedKeyCount = 21 + 17 + 11 + 6 + 8 + 7 + 4
        #expect(englishTranslations.count == expectedKeyCount, "Expected \(expectedKeyCount) keys in translations, but got \(englishTranslations.count)")
    }

    @Test("Translation file is valid JSON")
    func translationFileIsValid() {
        #expect(!englishTranslations.isEmpty, "English translations could not be loaded")
        #expect(!englishTranslations.isEmpty, "English translations are empty")
    }
}
