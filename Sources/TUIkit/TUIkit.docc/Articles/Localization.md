# Localization

Build multilingual terminal applications with TUIkit's comprehensive internationalization system.

## Overview

TUIkit provides built-in support for 5 languages: English, German, French, Italian, and Spanish. All framework strings use a type-safe, dot-notation based localization system with persistent language preferences and automatic fallback chains.

### Key Features

- **Type-safe keys**: Compile-time verified `LocalizationKey` enums with IDE autocomplete
- **5 languages built-in**: EN, DE, FR, IT, ES with complete translations
- **Persistent storage**: Language preference automatically saved and restored (XDG-compatible paths)
- **Fallback chain**: Current language → English → key itself for graceful degradation
- **Thread-safe**: Safe language switching from any thread at runtime
- **JSON-based**: Easy to extend with new strings and languages

## Quick Start

### Display Localized Strings

Use `LocalizedString` to show localized text:

```swift
import TUIkit

VStack {
    LocalizedString(.button(.ok))
    LocalizedString(.error(.notFound))
    LocalizedString(.dialog(.confirm))
}
```

Or use the `Text(localized:)` convenience initializer:

```swift
Text(localized: .button(.save))
```

### Switch Language at Runtime

```swift
AppState.shared.setLanguage(.german)
// UI automatically re-renders with German strings
```

### Supported Languages

- `.english` - English
- `.german` - Deutsch
- `.french` - Français
- `.italian` - Italiano
- `.spanish` - Español

## Type-Safe Keys

All localized strings are available as `LocalizationKey` enums organized by category. This provides compile-time safety, IDE autocomplete, and refactoring support.

### Key Categories

#### Button Keys

21 button strings including: ok, cancel, yes, no, save, delete, close, apply, reset, submit, search, clear, add, remove, edit, done, next, previous, back, forward, refresh

```swift
LocalizationKey.Button.ok
LocalizationKey.Button.cancel
LocalizationKey.Button.save
```

#### Label Keys

17 label strings including: search, name, description, value, status, error, warning, info, loading, empty, none, page, item, items, total, from, to

```swift
LocalizationKey.Label.name
LocalizationKey.Label.description
LocalizationKey.Label.status
```

#### Error Keys

11 error strings including: invalidInput, requiredField, notFound, accessDenied, networkError, unknown, invalidFormat, operationFailed, timeout, fileNotFound, permissionDenied

```swift
LocalizationKey.Error.invalidInput
LocalizationKey.Error.notFound
LocalizationKey.Error.timeout
```

#### Placeholder Keys

6 placeholder strings: search, enterText, enterValue, selectOption, enterName, chooseFile

```swift
LocalizationKey.Placeholder.search
LocalizationKey.Placeholder.enterText
LocalizationKey.Placeholder.selectOption
```

#### Menu Keys

8 menu strings: file, edit, view, help, new, open, save, exit

```swift
LocalizationKey.Menu.file
LocalizationKey.Menu.edit
LocalizationKey.Menu.help
```

#### Dialog Keys

7 dialog strings: confirm, deleteConfirmation, unsavedChanges, overwriteConfirmation, exitConfirmation, success, error

```swift
LocalizationKey.Dialog.confirm
LocalizationKey.Dialog.deleteConfirmation
LocalizationKey.Dialog.unsavedChanges
```

#### Validation Keys

4 validation strings: emailInvalid, passwordTooShort, usernameTaken, fieldRequired

```swift
LocalizationKey.Validation.emailInvalid
LocalizationKey.Validation.passwordTooShort
LocalizationKey.Validation.usernameTaken
```

## Using Localized Strings

### LocalizedString View

Display a localized string as a View component:

```swift
struct MyView: View {
    var body: some View {
        VStack {
            LocalizedString(.button(.save))
            LocalizedString(.error(.invalidInput))
            LocalizedString(.validation(.emailInvalid))
        }
    }
}
```

### Text View with Localization

Use the `Text(localized:)` initializer:

```swift
struct MyControl: View {
    var body: some View {
        VStack {
            Text(localized: .menu(.file))
            Text(localized: .placeholder(.search))
        }
    }
}
```

### Direct Service Access

For advanced use cases, access the service directly:

```swift
let service = LocalizationService.shared
let text = service.string(for: .button(.ok))
```

## Language Switching

### Get Current Language

```swift
let current = AppState.shared.currentLanguage
print(current.displayName)  // "English", "Deutsch", etc.
```

### Change Language

```swift
// Via AppState
AppState.shared.setLanguage(.german)

// Or directly via service
LocalizationService.shared.setLanguage(.french)
```

### Language Persistence

Language preferences are automatically saved to:
- **macOS**: `~/Library/Application Support/tuikit/language`
- **Linux**: `~/.config/tuikit/language`

The saved preference is restored when the app restarts.

### Fallback Behavior

String resolution uses a fallback chain:

1. Try to find the key in the active language
2. If not found, fall back to English
3. If still not found, return the key itself as-is

This ensures the UI always has something to display, even with incomplete translations.

## Environment Access

`LocalizationService` is available in the view environment:

```swift
struct MyView: View {
    @Environment(\.localizationService) var localization

    var body: some View {
        Text(localization.string(for: .button(.ok)))
    }
}
```

## Adding New Keys

To add new localized strings to the framework:

### 1. Update LocalizationKey Enum

Edit `Sources/TUIkit/Localization/LocalizationKeys.swift`:

```swift
public enum LocalizationKey {
    public enum Button: String {
        // ... existing cases
        case myNewButton = "button.my_new_button"
    }
}
```

Then add convenient extensions:

```swift
extension LocalizedString {
    public init(_ key: LocalizationKey.Button) {
        self.init(key.rawValue)
    }
}

extension Text {
    public init(localized key: LocalizationKey.Button) {
        self.init(localized: key.rawValue)
    }
}

extension LocalizationService {
    public func string(for key: LocalizationKey.Button) -> String {
        string(for: key.rawValue)
    }
}
```

### 2. Add to All Translation Files

Add the same key to all 5 translation JSON files:

**en.json**:
```json
{
  "button.my_new_button": "My New Button",
  ...
}
```

**de.json**:
```json
{
  "button.my_new_button": "Mein neuer Button",
  ...
}
```

Similar for `fr.json`, `it.json`, `es.json`.

### 3. Update Tests

Add tests in `Tests/TUIkitTests/LocalizationKeyConsistencyTests.swift`:

```swift
@Test("All button keys exist in translations")
func allButtonKeysExist() {
    let keys = [
        LocalizationKey.Button.ok,
        LocalizationKey.Button.myNewButton,
        // ... all other button keys
    ]

    for key in keys {
        #expect(englishTranslations[key.rawValue] != nil)
    }
}
```

### 4. Run Consistency Tests

Verify all keys exist in translation files:

```bash
swift test --filter LocalizationKeyConsistencyTests
```

## Adding New Languages

To add support for a new language:

### 1. Update Language Enum

Edit `Sources/TUIkit/Localization/LocalizationService.swift`:

```swift
public enum Language: String, Codable {
    case english = "en"
    case german = "de"
    case french = "fr"
    case italian = "it"
    case spanish = "es"
    case portuguese = "pt"  // NEW

    public var displayName: String {
        switch self {
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .italian: "Italiano"
        case .spanish: "Español"
        case .portuguese: "Português"  // NEW
        }
    }
}
```

### 2. Create Translation File

Create `Sources/TUIkit/Localization/translations/pt.json` with **all** keys from other language files:

```json
{
  "button.ok": "OK",
  "button.cancel": "Cancelar",
  ...
  // Must include ALL keys (use en.json as reference)
}
```

### 3. Test the New Language

```swift
let service = LocalizationService()
service.setLanguage(.portuguese)
let ok = service.string(for: .button(.ok))
```

### 4. Run Consistency Tests

```bash
swift test --filter LocalizationKeyConsistencyTests
```

## Design Principles

### Dot-Notation Keys

Keys use `category.key_name` format:

```
button.ok
error.not_found
validation.email_invalid
```

This organizes related strings, makes them easy to find, and matches JSON structure.

### Enum Categories

Each JSON prefix becomes an enum category:
- All `button.*` keys → `LocalizationKey.Button`
- All `error.*` keys → `LocalizationKey.Error`
- All `validation.*` keys → `LocalizationKey.Validation`

This provides type safety, IDE autocomplete, and compile-time verification.

### Thread Safety

``LocalizationService`` uses `NSLock` for thread-safe access:

```swift
// Safe to call from any thread
DispatchQueue.global().async {
    AppState.shared.setLanguage(.german)
}
```

### Performance Caching

Translations are cached per language after first load:

```swift
let text1 = service.string(for: .button(.ok))  // Loads and caches
let text2 = service.string(for: .button(.ok))  // Uses cache
```

## JSON File Format

### Structure

```json
{
  "category.key": "English text",
  "category.another_key": "More text",
  ...
}
```

### Rules

1. **Flat structure**: No nested objects (all keys are top-level)
2. **Dot-separated keys**: `"button.ok"`, not nested objects
3. **UTF-8 encoding**: Required for non-Latin characters
4. **Valid JSON**: No trailing commas, proper escaping

### Example

```json
{
  "button.ok": "OK",
  "button.cancel": "Cancel",
  "error.not_found": "Not found",
  "error.unicode_test": "Unicode: café, Ñoño, 日本語",
  "placeholder.enter_name": "Enter name..."
}
```

## Best Practices

1. **Always use type-safe keys**: Use `LocalizationKey` enums instead of raw strings
2. **Keep keys organized**: Group related strings by category
3. **Use descriptive names**: Short, clear key names
4. **Run consistency tests**: Always verify after adding keys
5. **Test all languages**: Check translations look correct in each language
6. **Handle missing strings**: Rely on the fallback chain for incomplete translations

## Testing

TUIkit includes comprehensive localization tests:

### LocalizationServiceTests
Core functionality tests covering:
- Bundle loading for all languages
- String resolution with dot-notation
- Fallback behavior
- Language switching
- Persistence to disk
- Thread safety

### LocalizationKeyConsistencyTests
Validation tests ensuring:
- Every enum key exists in all translation files
- No extraneous keys in translation files
- Expected total key count

Run after any localization changes:

```bash
swift test --filter LocalizationKeyConsistencyTests
```

## Troubleshooting

### String Not Appearing

- Verify the key exists in `LocalizationKey` enum
- Check the key is in all translation JSON files
- Run consistency tests to verify

### Wrong Language Showing

- Verify language was set: `AppState.shared.currentLanguage`
- Confirm language is supported (en, de, fr, it, es)
- Check translation file exists for that language

### JSON Syntax Errors

If translation files won't load:
- Validate JSON syntax
- Check for missing commas or quotes
- Ensure UTF-8 encoding
- No trailing commas in objects

## See Also

- <doc:GettingStarted> — Getting started with TUIkit
- <doc:AppLifecycle> — Application lifecycle and setup
- <doc:Architecture> — Framework architecture
