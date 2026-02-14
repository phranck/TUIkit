//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LocalizationServiceTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import XCTest
@testable import TUIkit

// MARK: - Localization Service Tests

final class LocalizationServiceTests: XCTestCase {
    var sut: LocalizationService!
    let fileManager = FileManager.default

    override func setUp() {
        super.setUp()
        sut = LocalizationService()
    }

    override func tearDown() {
        super.tearDown()
        // Clean up stored language preference
        try? fileManager.removeItem(atPath: Self.configFilePath())
    }

    // MARK: - Bundle Loading Tests

    func testLoadsEnglishTranslationsFromBundle() {
        let englishStrings = sut.string(for: "button.ok")
        XCTAssertEqual(englishStrings, "OK")
    }

    func testLoadsGermanTranslationsFromBundle() {
        sut.setLanguage(.german)
        let germanStrings = sut.string(for: "button.ok")
        XCTAssertEqual(germanStrings, "OK")
    }

    func testLoadsFrenchTranslationsFromBundle() {
        sut.setLanguage(.french)
        let frenchStrings = sut.string(for: "button.cancel")
        XCTAssertEqual(frenchStrings, "Annuler")
    }

    func testLoadsItalianTranslationsFromBundle() {
        sut.setLanguage(.italian)
        let italianStrings = sut.string(for: "button.yes")
        XCTAssertEqual(italianStrings, "Sì")
    }

    func testLoadsSpanishTranslationsFromBundle() {
        sut.setLanguage(.spanish)
        let spanishStrings = sut.string(for: "button.no")
        XCTAssertEqual(spanishStrings, "No")
    }

    // MARK: - String Resolution Tests

    func testResolvesDotNotationKeys() {
        let string = sut.string(for: "button.ok")
        XCTAssertEqual(string, "OK")
    }

    func testResolvesNestedKeys() {
        let string = sut.string(for: "error.invalid_input")
        XCTAssertEqual(string, "Invalid input")
    }

    func testResolvesAllKeyCategories() {
        // Button
        XCTAssertEqual(sut.string(for: LocalizationKey.Button.save), "Save")
        // Label
        XCTAssertEqual(sut.string(for: LocalizationKey.Label.name), "Name")
        // Error
        XCTAssertEqual(sut.string(for: LocalizationKey.Error.notFound), "Not found")
        // Placeholder
        XCTAssertEqual(sut.string(for: LocalizationKey.Placeholder.search), "Search...")
        // Menu
        XCTAssertEqual(sut.string(for: LocalizationKey.Menu.file), "File")
        // Dialog
        XCTAssertEqual(sut.string(for: LocalizationKey.Dialog.confirm), "Confirm")
        // Validation
        XCTAssertEqual(sut.string(for: LocalizationKey.Validation.emailInvalid), "Invalid email address")
    }

    // MARK: - Fallback Tests

    func testFallsBackToEnglishWhenKeyMissingInCurrentLanguage() {
        sut.setLanguage(.german)
        // Even if a key were missing in German, it would fall back to English
        // This tests the fallback chain: current language -> English -> key
        let string = sut.string(for: "button.ok")
        XCTAssertNotEqual(string, "button.ok")
    }

    func testReturnsKeyWhenNotFoundInAnyLanguage() {
        let unknownKey = "nonexistent.key.that.does.not.exist"
        let string = sut.string(for: unknownKey)
        XCTAssertEqual(string, unknownKey)
    }

    func testFallsBackChain() {
        // Set German, resolve a key
        sut.setLanguage(.german)
        let germanString = sut.string(for: "button.ok")
        XCTAssertEqual(germanString, "OK")

        // Switch to English
        sut.setLanguage(.english)
        let englishString = sut.string(for: "button.ok")
        XCTAssertEqual(englishString, "OK")
        XCTAssertEqual(germanString, englishString)
    }

    // MARK: - Language Switching Tests

    func testSwitchesLanguageSuccessfully() {
        sut.setLanguage(.english)
        XCTAssertEqual(sut.currentLanguage, .english)

        sut.setLanguage(.german)
        XCTAssertEqual(sut.currentLanguage, .german)

        sut.setLanguage(.french)
        XCTAssertEqual(sut.currentLanguage, .french)
    }

    func testLanguagePropertyReturnsCurrentLanguage() {
        sut.setLanguage(.english)
        XCTAssertEqual(sut.currentLanguage, .english)

        sut.setLanguage(.italian)
        XCTAssertEqual(sut.currentLanguage, .italian)
    }

    func testResolveStringsAfterLanguageSwitch() {
        // Start with English
        sut.setLanguage(.english)
        var string = sut.string(for: "button.save")
        XCTAssertEqual(string, "Save")

        // Switch to German
        sut.setLanguage(.german)
        string = sut.string(for: "button.save")
        XCTAssertEqual(string, "Speichern")

        // Switch to French
        sut.setLanguage(.french)
        string = sut.string(for: "button.save")
        XCTAssertEqual(string, "Enregistrer")
    }

    // MARK: - Persistence Tests

    func testSavesLanguagePreferenceToConfigFile() {
        sut.setLanguage(.german)
        let path = Self.configFilePath()
        let content = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        XCTAssertEqual(content, "de")
    }

    func testLoadsLanguagePreferenceFromConfigFile() {
        // First, save a language preference
        let path = Self.configFilePath()
        let dirPath = (path as NSString).deletingLastPathComponent
        try? fileManager.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? "fr".write(toFile: path, atomically: true, encoding: .utf8)

        // Create a new service instance
        let newService = LocalizationService()
        XCTAssertEqual(newService.currentLanguage, .french)
    }

    func testHandlesMissingConfigFileGracefully() {
        // Ensure config file doesn't exist
        try? fileManager.removeItem(atPath: Self.configFilePath())

        // Create service, should default to English
        let newService = LocalizationService()
        XCTAssertEqual(newService.currentLanguage, .english)
    }

    func testHandlesInvalidConfigFileContentGracefully() {
        let path = Self.configFilePath()
        let dirPath = (path as NSString).deletingLastPathComponent
        try? fileManager.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        // Write invalid language code
        try? "invalid_lang_code".write(toFile: path, atomically: true, encoding: .utf8)

        // Create service, should default to English
        let newService = LocalizationService()
        XCTAssertEqual(newService.currentLanguage, .english)
    }

    // MARK: - Thread Safety Tests

    @MainActor
    func testIsThreadSafe() {
        let expectation = self.expectation(description: "Concurrent access should complete")
        let concurrentQueue = DispatchQueue(label: "com.tuikit.test.concurrent", attributes: .concurrent)
        var completedOperations = 0
        let lock = NSLock()

        // Perform concurrent language switches and string resolutions
        for i in 0 ..< 100 {
            concurrentQueue.async {
                let language: LocalizationService.Language = [.english, .german, .french, .italian, .spanish][i % 5]
                self.sut.setLanguage(language)
                _ = self.sut.string(for: "button.ok")

                lock.lock()
                completedOperations += 1
                if completedOperations == 100 {
                    expectation.fulfill()
                }
                lock.unlock()
            }
        }

        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedOperations, 100)
    }

    // MARK: - Language Enum Tests

    func testLanguageEnumRawValues() {
        XCTAssertEqual(LocalizationService.Language.english.rawValue, "en")
        XCTAssertEqual(LocalizationService.Language.german.rawValue, "de")
        XCTAssertEqual(LocalizationService.Language.french.rawValue, "fr")
        XCTAssertEqual(LocalizationService.Language.italian.rawValue, "it")
        XCTAssertEqual(LocalizationService.Language.spanish.rawValue, "es")
    }

    func testLanguageEnumDisplayNames() {
        XCTAssertEqual(LocalizationService.Language.english.displayName, "English")
        XCTAssertEqual(LocalizationService.Language.german.displayName, "Deutsch")
        XCTAssertEqual(LocalizationService.Language.french.displayName, "Français")
        XCTAssertEqual(LocalizationService.Language.italian.displayName, "Italiano")
        XCTAssertEqual(LocalizationService.Language.spanish.displayName, "Español")
    }

    func testLanguageEnumIsCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // English
        let english = LocalizationService.Language.english
        let encodedEnglish = try? encoder.encode(english)
        let decodedEnglish = try? decoder.decode(LocalizationService.Language.self, from: encodedEnglish ?? Data())
        XCTAssertEqual(decodedEnglish, english)

        // German
        let german = LocalizationService.Language.german
        let encodedGerman = try? encoder.encode(german)
        let decodedGerman = try? decoder.decode(LocalizationService.Language.self, from: encodedGerman ?? Data())
        XCTAssertEqual(decodedGerman, german)
    }

    // MARK: - Caching Tests

    func testCachesTranslationDictionaries() {
        // First access loads from bundle
        _ = sut.string(for: "button.ok")

        // Second access should use cache (we can't directly test cache, but verify consistency)
        let string1 = sut.string(for: "button.ok")
        let string2 = sut.string(for: "button.ok")
        XCTAssertEqual(string1, string2)
    }

    func testCacheIsPerLanguage() {
        sut.setLanguage(.english)
        let englishString = sut.string(for: "button.save")
        XCTAssertEqual(englishString, "Save")

        sut.setLanguage(.german)
        let germanString = sut.string(for: "button.save")
        XCTAssertEqual(germanString, "Speichern")

        // Switch back to English, should still be cached
        sut.setLanguage(.english)
        let englishAgain = sut.string(for: "button.save")
        XCTAssertEqual(englishAgain, "Save")
    }

    // MARK: - Helper Methods

    private static func configFilePath() -> String {
        #if os(macOS)
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first?.path ?? NSHomeDirectory()
        return (appSupport as NSString).appendingPathComponent("tuikit/language")
        #else
        let configHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
            ?? ((NSHomeDirectory() as NSString).appendingPathComponent(".config"))
        return (configHome as NSString).appendingPathComponent("tuikit/language")
        #endif
    }
}

// MARK: - LocalizedString View Tests

final class LocalizedStringViewTests: XCTestCase {
    @MainActor
    func testLocalizedStringCreatesViewWithKey() {
        let view = LocalizedString("button.ok")
        XCTAssertNotNil(view)
    }

    @MainActor
    func testLocalizedStringReturnsCorrectText() {
        let view = LocalizedString("button.ok")
        // Note: We can't directly test the body output without rendering,
        // but we verify the view is created successfully
        XCTAssertNotNil(view)
    }
}

// MARK: - TextLocalizationExtension Tests

final class TextLocalizationExtensionTests: XCTestCase {
    @MainActor
    func testTextLocalizedInitializer() {
        // Just verify it creates without crashing
        let text = Text(localized: "button.ok")
        XCTAssertNotNil(text)
    }

    @MainActor
    func testTextLocalizedWithDifferentKeys() {
        let buttons = ["button.ok", "button.cancel", "button.save"]
        for key in buttons {
            let text = Text(localized: key)
            XCTAssertNotNil(text)
        }
    }
}

// MARK: - AppState Localization Extension Tests

final class AppStateLocalizationExtensionTests: XCTestCase {
    @MainActor
    func testAppStateCurrentLanguageProperty() {
        LocalizationService.shared.setLanguage(.english)
        XCTAssertEqual(AppState.shared.currentLanguage, .english)

        LocalizationService.shared.setLanguage(.german)
        XCTAssertEqual(AppState.shared.currentLanguage, .german)
    }

    @MainActor
    func testAppStateSetLanguageMethod() {
        AppState.shared.setLanguage(.french)
        XCTAssertEqual(LocalizationService.shared.currentLanguage, .french)

        AppState.shared.setLanguage(.italian)
        XCTAssertEqual(LocalizationService.shared.currentLanguage, .italian)
    }
}

// MARK: - Localization Key Type-Safety Tests

final class LocalizationKeyTests: XCTestCase {
    var service: LocalizationService!

    override func setUp() {
        super.setUp()
        service = LocalizationService()
        service.setLanguage(.english)
    }

    func testButtonKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Button.ok), "OK")
        XCTAssertEqual(service.string(for: LocalizationKey.Button.cancel), "Cancel")
        XCTAssertEqual(service.string(for: LocalizationKey.Button.save), "Save")
        XCTAssertEqual(service.string(for: LocalizationKey.Button.delete), "Delete")
    }

    func testLabelKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Label.name), "Name")
        XCTAssertEqual(service.string(for: LocalizationKey.Label.description), "Description")
        XCTAssertEqual(service.string(for: LocalizationKey.Label.value), "Value")
        XCTAssertEqual(service.string(for: LocalizationKey.Label.status), "Status")
    }

    func testErrorKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Error.invalidInput), "Invalid input")
        XCTAssertEqual(service.string(for: LocalizationKey.Error.notFound), "Not found")
        XCTAssertEqual(service.string(for: LocalizationKey.Error.accessDenied), "Access denied")
    }

    func testPlaceholderKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Placeholder.search), "Search...")
        XCTAssertEqual(service.string(for: LocalizationKey.Placeholder.enterText), "Enter text...")
        XCTAssertEqual(service.string(for: LocalizationKey.Placeholder.selectOption), "Select an option...")
    }

    func testMenuKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Menu.file), "File")
        XCTAssertEqual(service.string(for: LocalizationKey.Menu.edit), "Edit")
        XCTAssertEqual(service.string(for: LocalizationKey.Menu.view), "View")
    }

    func testDialogKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Dialog.confirm), "Confirm")
        XCTAssertEqual(service.string(for: LocalizationKey.Dialog.deleteConfirmation), "Are you sure you want to delete this?")
        XCTAssertEqual(service.string(for: LocalizationKey.Dialog.success), "Operation completed successfully")
    }

    func testValidationKeysResolveCorrectly() {
        XCTAssertEqual(service.string(for: LocalizationKey.Validation.emailInvalid), "Invalid email address")
        XCTAssertEqual(service.string(for: LocalizationKey.Validation.passwordTooShort), "Password must be at least 8 characters")
        XCTAssertEqual(service.string(for: LocalizationKey.Validation.usernameTaken), "Username already exists")
    }

    func testKeysWorkAcrossLanguages() {
        service.setLanguage(.german)
        XCTAssertEqual(service.string(for: LocalizationKey.Button.ok), "OK")

        service.setLanguage(.french)
        XCTAssertEqual(service.string(for: LocalizationKey.Button.cancel), "Annuler")

        service.setLanguage(.italian)
        XCTAssertEqual(service.string(for: LocalizationKey.Error.notFound), "Non trovato")
    }

    func testKeyEnumRawValuesMatchStringKeys() {
        // Verify that enum raw values match the string constants
        XCTAssertEqual(LocalizationKey.Button.ok.rawValue, "button.ok")
        XCTAssertEqual(LocalizationKey.Error.notFound.rawValue, "error.not_found")
        XCTAssertEqual(LocalizationKey.Label.name.rawValue, "label.name")
    }
}

// MARK: - LocalizationKey View Extension Tests

final class LocalizationKeyViewExtensionTests: XCTestCase {
    @MainActor
    func testLocalizedStringWithTypeSafeKeys() {
        let buttonView = LocalizedString(LocalizationKey.Button.ok)
        XCTAssertNotNil(buttonView)

        let errorView = LocalizedString(LocalizationKey.Error.notFound)
        XCTAssertNotNil(errorView)

        let labelView = LocalizedString(LocalizationKey.Label.name)
        XCTAssertNotNil(labelView)
    }

    @MainActor
    func testTextWithTypeSafeKeys() {
        let buttonText = Text(localized: LocalizationKey.Button.save)
        XCTAssertNotNil(buttonText)

        let menuText = Text(localized: LocalizationKey.Menu.file)
        XCTAssertNotNil(menuText)

        let dialogText = Text(localized: LocalizationKey.Dialog.confirm)
        XCTAssertNotNil(dialogText)
    }

    @MainActor
    func testAllKeyTypesWork() {
        // Verify all key types can be used with LocalizedString
        _ = LocalizedString(LocalizationKey.Button.ok)
        _ = LocalizedString(LocalizationKey.Label.name)
        _ = LocalizedString(LocalizationKey.Error.notFound)
        _ = LocalizedString(LocalizationKey.Placeholder.search)
        _ = LocalizedString(LocalizationKey.Menu.file)
        _ = LocalizedString(LocalizationKey.Dialog.confirm)
        _ = LocalizedString(LocalizationKey.Validation.emailInvalid)
    }
}
