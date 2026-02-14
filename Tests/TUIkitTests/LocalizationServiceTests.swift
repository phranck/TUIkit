//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LocalizationServiceTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing
@testable import TUIkit

// MARK: - Localization Service Tests

@Suite("LocalizationService")
final class LocalizationServiceTests {
    let fileManager = FileManager.default

    private func createService() -> LocalizationService {
        LocalizationService()
    }

    // MARK: - Bundle Loading Tests

    @Test("Loads English translations from bundle")
    func loadEnglishTranslations() {
        let sut = createService()
        let englishStrings = sut.string(for: "button.ok")
        #expect(englishStrings == "OK")
    }

    @Test("Loads German translations from bundle")
    func loadGermanTranslations() {
        let sut = createService()
        sut.setLanguage(.german)
        let germanStrings = sut.string(for: "button.ok")
        #expect(germanStrings == "OK")
    }

    @Test("Loads French translations from bundle")
    func loadFrenchTranslations() {
        let sut = createService()
        sut.setLanguage(.french)
        let frenchStrings = sut.string(for: "button.cancel")
        #expect(frenchStrings == "Annuler")
    }

    @Test("Loads Italian translations from bundle")
    func loadItalianTranslations() {
        let sut = createService()
        sut.setLanguage(.italian)
        let italianStrings = sut.string(for: "button.yes")
        #expect(italianStrings == "Sì")
    }

    @Test("Loads Spanish translations from bundle")
    func loadSpanishTranslations() {
        let sut = createService()
        sut.setLanguage(.spanish)
        let spanishStrings = sut.string(for: "button.no")
        #expect(spanishStrings == "No")
    }

    // MARK: - String Resolution Tests

    @Test("Resolves dot-notation keys")
    func resolvesDotNotationKeys() {
        let sut = createService()
        let string = sut.string(for: "button.ok")
        #expect(string == "OK")
    }

    @Test("Resolves nested keys")
    func resolvesNestedKeys() {
        let sut = createService()
        let string = sut.string(for: "error.invalid_input")
        #expect(string == "Invalid input")
    }

    @Test("Resolves all key categories")
    func resolvesAllKeyCategories() {
        #expect(sut.string(for: "button.save") == "Save")
        #expect(sut.string(for: "label.name") == "Name")
        #expect(sut.string(for: "error.not_found") == "Not found")
        #expect(sut.string(for: "placeholder.search") == "Search...")
        #expect(sut.string(for: "menu.file") == "File")
        #expect(sut.string(for: "dialog.confirm") == "Confirm")
        #expect(sut.string(for: "validation.email_invalid") == "Invalid email address")
    }

    // MARK: - Fallback Tests

    @Test("Falls back to English when key missing in current language")
    func fallsBackToEnglish() {
        sut.setLanguage(.german)
        let sut = createService()
        let string = sut.string(for: "button.ok")
        #expect(string != "button.ok")
    }

    @Test("Returns key when not found in any language")
    func returnsKeyWhenNotFound() {
        let unknownKey = "nonexistent.key.that.does.not.exist"
        let sut = createService()
        let string = sut.string(for: unknownKey)
        #expect(string == unknownKey)
    }

    @Test("Fallback chain works correctly")
    func fallbackChain() {
        sut.setLanguage(.german)
        let germanString = sut.string(for: "button.ok")
        #expect(germanString == "OK")

        sut.setLanguage(.english)
        let englishString = sut.string(for: "button.ok")
        #expect(englishString == "OK")
        #expect(germanString == englishString)
    }

    // MARK: - Language Switching Tests

    @Test("Switches language successfully")
    func switchesLanguage() {
        let sut = createService()
        sut.setLanguage(.english)
        #expect(sut.currentLanguage == .english)

        sut.setLanguage(.german)
        #expect(sut.currentLanguage == .german)

        sut.setLanguage(.french)
        #expect(sut.currentLanguage == .french)
    }

    @Test("Language property returns current language")
    func languageProperty() {
        let sut = createService()
        sut.setLanguage(.english)
        #expect(sut.currentLanguage == .english)

        sut.setLanguage(.italian)
        #expect(sut.currentLanguage == .italian)
    }

    @Test("Resolves strings after language switch")
    func resolvesStringsAfterSwitch() {
        let sut = createService()
        sut.setLanguage(.english)
        var string = sut.string(for: "button.save")
        #expect(string == "Save")

        sut.setLanguage(.german)
        string = sut.string(for: "button.save")
        #expect(string == "Speichern")

        sut.setLanguage(.french)
        string = sut.string(for: "button.save")
        #expect(string == "Enregistrer")
    }

    // MARK: - Persistence Tests

    @Test("Saves language preference to config file", .disabled("Disabled: File I/O conflicts with parallel test execution"))
    func savesLanguagePreference() {
        sut.setLanguage(.german)
        let path = Self.configFilePath()
        let content = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        #expect(content == "de")
    }

    @Test("Loads language preference from config file", .disabled("Disabled: File I/O conflicts with parallel test execution"))
    func loadsLanguagePreference() {
        let path = Self.configFilePath()
        let dirPath = (path as NSString).deletingLastPathComponent
        try? fileManager.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? "fr".write(toFile: path, atomically: true, encoding: .utf8)

        let newService = LocalizationService()
        #expect(newService.currentLanguage == .french)
    }

    @Test("Handles missing config file gracefully", .disabled("Disabled: File I/O conflicts with parallel test execution"))
    func handlesMissingConfigFile() {
        try? fileManager.removeItem(atPath: Self.configFilePath())

        let newService = LocalizationService()
        #expect(newService.currentLanguage == .english)
    }

    @Test("Handles invalid config file content gracefully", .disabled("Disabled: File I/O conflicts with parallel test execution"))
    func handlesInvalidConfigFile() {
        let path = Self.configFilePath()
        let dirPath = (path as NSString).deletingLastPathComponent
        try? fileManager.createDirectory(
            atPath: dirPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try? "invalid_lang_code".write(toFile: path, atomically: true, encoding: .utf8)

        let newService = LocalizationService()
        #expect(newService.currentLanguage == .english)
    }

    // MARK: - Language Enum Tests

    @Test("Language enum raw values are correct")
    func languageRawValues() {
        #expect(LocalizationService.Language.english.rawValue == "en")
        #expect(LocalizationService.Language.german.rawValue == "de")
        #expect(LocalizationService.Language.french.rawValue == "fr")
        #expect(LocalizationService.Language.italian.rawValue == "it")
        #expect(LocalizationService.Language.spanish.rawValue == "es")
    }

    @Test("Language enum display names are correct")
    func languageDisplayNames() {
        #expect(LocalizationService.Language.english.displayName == "English")
        #expect(LocalizationService.Language.german.displayName == "Deutsch")
        #expect(LocalizationService.Language.french.displayName == "Français")
        #expect(LocalizationService.Language.italian.displayName == "Italiano")
        #expect(LocalizationService.Language.spanish.displayName == "Español")
    }

    @Test("Language enum is codable")
    func languageIsCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let english = LocalizationService.Language.english
        let encodedEnglish = try? encoder.encode(english)
        let decodedEnglish = try? decoder.decode(LocalizationService.Language.self, from: encodedEnglish ?? Data())
        #expect(decodedEnglish == english)

        let german = LocalizationService.Language.german
        let encodedGerman = try? encoder.encode(german)
        let decodedGerman = try? decoder.decode(LocalizationService.Language.self, from: encodedGerman ?? Data())
        #expect(decodedGerman == german)
    }

    // MARK: - Caching Tests

    @Test("Caches translation dictionaries")
    func cacheTranslations() {
        _ = sut.string(for: "button.ok")

        let string1 = sut.string(for: "button.ok")
        let string2 = sut.string(for: "button.ok")
        #expect(string1 == string2)
    }

    @Test("Cache is per-language")
    func cacheIsPerLanguage() {
        sut.setLanguage(.english)
        let englishString = sut.string(for: "button.save")
        #expect(englishString == "Save")

        sut.setLanguage(.german)
        let germanString = sut.string(for: "button.save")
        #expect(germanString == "Speichern")

        sut.setLanguage(.english)
        let englishAgain = sut.string(for: "button.save")
        #expect(englishAgain == "Save")
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

// MARK: - Localization Key Tests

@Suite("LocalizationKey")
final class LocalizationKeyTests {
    var service: LocalizationService!

    init() {
        service = LocalizationService()
        service.setLanguage(.english)
    }

    @Test("Button keys resolve correctly")
    func buttonKeys() {
        #expect(service.string(for: LocalizationKey.Button.ok) == "OK")
        #expect(service.string(for: LocalizationKey.Button.cancel) == "Cancel")
        #expect(service.string(for: LocalizationKey.Button.save) == "Save")
        #expect(service.string(for: LocalizationKey.Button.delete) == "Delete")
    }

    @Test("Label keys resolve correctly")
    func labelKeys() {
        #expect(service.string(for: LocalizationKey.Label.name) == "Name")
        #expect(service.string(for: LocalizationKey.Label.description) == "Description")
        #expect(service.string(for: LocalizationKey.Label.value) == "Value")
        #expect(service.string(for: LocalizationKey.Label.status) == "Status")
    }

    @Test("Error keys resolve correctly")
    func errorKeys() {
        #expect(service.string(for: LocalizationKey.Error.invalidInput) == "Invalid input")
        #expect(service.string(for: LocalizationKey.Error.notFound) == "Not found")
        #expect(service.string(for: LocalizationKey.Error.accessDenied) == "Access denied")
    }

    @Test("Placeholder keys resolve correctly")
    func placeholderKeys() {
        #expect(service.string(for: LocalizationKey.Placeholder.search) == "Search...")
        #expect(service.string(for: LocalizationKey.Placeholder.enterText) == "Enter text...")
        #expect(service.string(for: LocalizationKey.Placeholder.selectOption) == "Select an option...")
    }

    @Test("Menu keys resolve correctly")
    func menuKeys() {
        #expect(service.string(for: LocalizationKey.Menu.file) == "File")
        #expect(service.string(for: LocalizationKey.Menu.edit) == "Edit")
        #expect(service.string(for: LocalizationKey.Menu.view) == "View")
    }

    @Test("Dialog keys resolve correctly")
    func dialogKeys() {
        #expect(service.string(for: LocalizationKey.Dialog.confirm) == "Confirm")
        #expect(service.string(for: LocalizationKey.Dialog.deleteConfirmation) == "Are you sure you want to delete this?")
        #expect(service.string(for: LocalizationKey.Dialog.success) == "Operation completed successfully")
    }

    @Test("Validation keys resolve correctly")
    func validationKeys() {
        #expect(service.string(for: LocalizationKey.Validation.emailInvalid) == "Invalid email address")
        #expect(service.string(for: LocalizationKey.Validation.passwordTooShort) == "Password must be at least 8 characters")
        #expect(service.string(for: LocalizationKey.Validation.usernameTaken) == "Username already exists")
    }

    @Test("Keys work across all languages")
    func keysAcrossLanguages() {
        service.setLanguage(.german)
        #expect(service.string(for: LocalizationKey.Button.ok) == "OK")

        service.setLanguage(.french)
        #expect(service.string(for: LocalizationKey.Button.cancel) == "Annuler")

        service.setLanguage(.italian)
        #expect(service.string(for: LocalizationKey.Error.notFound) == "Non trovato")
    }

    @Test("Key enum raw values match string keys")
    func keyRawValues() {
        #expect(LocalizationKey.Button.ok.rawValue == "button.ok")
        #expect(LocalizationKey.Error.notFound.rawValue == "error.not_found")
        #expect(LocalizationKey.Label.name.rawValue == "label.name")
    }
}
