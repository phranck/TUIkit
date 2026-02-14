# TUIkit Internationalization (i18n) Guide

TUIkit provides comprehensive internationalization support with 5 languages built-in: English, German, French, Italian, and Spanish. All framework strings use a type-safe, dot-notation based localization system.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Using Localized Strings](#using-localized-strings)
3. [Type-Safe Keys](#type-safe-keys)
4. [Switching Languages](#switching-languages)
5. [Adding New Keys](#adding-new-keys)
6. [Adding New Languages](#adding-new-languages)
7. [Advanced Usage](#advanced-usage)

## Quick Start

### Basic Usage

Use `LocalizedString` to display localized text:

```swift
import TUIkit

VStack {
    LocalizedString(.button(.ok))
    LocalizedString(.label(.name))
    LocalizedString(.error(.notFound))
}
```

Or use the `Text(localized:)` convenience initializer:

```swift
Text(localized: .dialog(.confirm))
```

### Switching Languages at Runtime

```swift
// In your app
AppState.shared.setLanguage(.german)

// The UI automatically re-renders with German strings
```

## Using Localized Strings

### With LocalizedString View

`LocalizedString` is a `View` that displays a localized string:

```swift
VStack {
    LocalizedString(.button(.save))
    LocalizedString(.error(.invalidInput))
    LocalizedString(.validation(.emailInvalid))
}
```

### With Text View

Use the `Text(localized:)` initializer for cases where you need a `Text` view directly:

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

### With String Keys

For dynamic key resolution or advanced use cases:

```swift
let key = "button.ok"
let localizedText = LocalizationService.shared.string(for: key)
```

## Type-Safe Keys

All framework strings are available as type-safe `LocalizationKey` enums. This provides:
- **Compile-time safety**: Typos are caught by the compiler
- **IDE autocomplete**: Full support for all available keys
- **Refactoring safety**: Safe renaming across the codebase

### Key Categories

#### Button Keys

```swift
LocalizationKey.Button.ok
LocalizationKey.Button.cancel
LocalizationKey.Button.save
LocalizationKey.Button.delete
// ... and 17 more
```

#### Label Keys

```swift
LocalizationKey.Label.name
LocalizationKey.Label.description
LocalizationKey.Label.value
LocalizationKey.Label.status
// ... and 13 more
```

#### Error Keys

```swift
LocalizationKey.Error.invalidInput
LocalizationKey.Error.notFound
LocalizationKey.Error.accessDenied
LocalizationKey.Error.timeout
// ... and 7 more
```

#### Placeholder Keys

```swift
LocalizationKey.Placeholder.search
LocalizationKey.Placeholder.enterText
LocalizationKey.Placeholder.selectOption
// ... and 3 more
```

#### Menu Keys

```swift
LocalizationKey.Menu.file
LocalizationKey.Menu.edit
LocalizationKey.Menu.view
LocalizationKey.Menu.help
// ... and 4 more
```

#### Dialog Keys

```swift
LocalizationKey.Dialog.confirm
LocalizationKey.Dialog.deleteConfirmation
LocalizationKey.Dialog.unsavedChanges
// ... and 4 more
```

#### Validation Keys

```swift
LocalizationKey.Validation.emailInvalid
LocalizationKey.Validation.passwordTooShort
LocalizationKey.Validation.usernameTaken
LocalizationKey.Validation.fieldRequired
```

## Switching Languages

### Get Current Language

```swift
let current = AppState.shared.currentLanguage
print(current.displayName)  // "Deutsch", "Français", etc.
```

### Supported Languages

- `.english` - English
- `.german` - Deutsch
- `.french` - Français
- `.italian` - Italiano
- `.spanish` - Español

### Change Language at Runtime

```swift
// Using AppState
AppState.shared.setLanguage(.german)

// Or directly via LocalizationService
LocalizationService.shared.setLanguage(.french)
```

### Language Persistence

Language preferences are automatically saved to disk:
- **macOS**: `~/Library/Application Support/tuikit/language`
- **Linux**: `~/.config/tuikit/language`

The saved preference is restored when the app restarts.

## Adding New Keys

When you need to add new localized strings to the framework:

### 1. Add to LocalizationKey Enum

Edit `Sources/TUIkit/Localization/LocalizationKeys.swift`:

```swift
public enum LocalizationKey {
    public enum Button: String {
        // ... existing cases
        case myNewButton = "button.my_new_button"
    }
}
```

### 2. Add to All Translation Files

Add the same key to all 5 translation JSON files:

- `Sources/TUIkit/Localization/translations/en.json`
- `Sources/TUIkit/Localization/translations/de.json`
- `Sources/TUIkit/Localization/translations/fr.json`
- `Sources/TUIkit/Localization/translations/it.json`
- `Sources/TUIkit/Localization/translations/es.json`

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

And similarly for French, Italian, and Spanish.

### 3. Update Tests (if needed)

If adding a new category, add corresponding test methods in:
- `Tests/TUIkitTests/LocalizationServiceTests.swift`
- `Tests/TUIkitTests/LocalizationKeyConsistencyTests.swift`

### 4. Run Consistency Tests

Verify that all keys in the enum exist in the translation files:

```bash
swift test --filter LocalizationKeyConsistencyTests
```

## Adding New Languages

To add support for a new language:

### 1. Add to Language Enum

Edit `Sources/TUIkit/Localization/LocalizationService.swift`:

```swift
public enum Language: String, Codable {
    case english = "en"
    case german = "de"
    case french = "fr"
    case italian = "it"
    case spanish = "es"
    case portuguese = "pt"  // New language

    public var displayName: String {
        switch self {
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .italian: "Italiano"
        case .spanish: "Español"
        case .portuguese: "Português"  // Add display name
        }
    }
}
```

### 2. Create Translation File

Create a new JSON file with all keys translated:

`Sources/TUIkit/Localization/translations/pt.json`:

```json
{
  "button.ok": "OK",
  "button.cancel": "Cancelar",
  ...
}
```

Make sure all keys from the other language files are included.

### 3. Update Package.swift

The translations are automatically discovered from the directory, no changes needed.

### 4. Test the New Language

```swift
let service = LocalizationService()
service.setLanguage(.portuguese)
let ok = service.string(for: LocalizationKey.Button.ok)
print(ok)  // "OK"
```

## Advanced Usage

### Direct Service Access

For advanced scenarios, access the localization service directly:

```swift
let service = LocalizationService.shared

// Get current language
let current = service.currentLanguage

// Get a string
let text = service.string(for: "button.ok")

// Change language
service.setLanguage(.german)
```

### Using Raw String Keys

While not recommended (loses type safety), you can use raw string keys:

```swift
let text = LocalizationService.shared.string(for: "button.ok")
```

### Fallback Behavior

String resolution uses a fallback chain:
1. **Current language**: Try to find the key in the active language
2. **English**: If not found, fall back to English
3. **Key itself**: If not found in any language, return the key as-is

This ensures the app always has something to display, even with incomplete translations.

### Environment Access

`LocalizationService` is available in the environment:

```swift
struct MyView: View {
    @Environment(\.localizationService) var localization

    var body: some View {
        Text(localization.string(for: "button.ok"))
    }
}
```

## Integration with Views

### In Custom Components

```swift
struct MyDialog: View {
    var body: some View {
        VStack {
            LocalizedString(.dialog(.confirm))
            HStack {
                Button("OK") { /* ... */ }
                    .buttonLabel(LocalizedString(.button(.cancel)))
            }
        }
    }
}
```

### In Form Validation

```swift
struct LoginForm: View {
    @State var email = ""
    @State var showError = false

    var body: some View {
        VStack {
            TextField(LocalizationKey.Placeholder.enterName.rawValue, text: $email)

            if showError {
                LocalizedString(.validation(.emailInvalid))
                    .foregroundColor(.red)
            }
        }
    }
}
```

## Best Practices

1. **Always use type-safe keys**: Use `LocalizationKey` enums instead of raw strings
2. **Group related strings**: Keep strings organized by category (Button, Label, Error, etc.)
3. **Keep keys concise**: Use short, descriptive key names
4. **Run consistency tests**: Always run `LocalizationKeyConsistencyTests` after adding keys
5. **Test all languages**: Verify strings look correct in all supported languages
6. **Document dynamic strings**: If using raw keys, document why they're necessary

## Troubleshooting

### String Not Appearing

- Check that the key exists in `LocalizationKey` enum
- Verify the key is in all translation JSON files
- Run consistency tests: `swift test --filter LocalizationKeyConsistencyTests`

### Wrong Language Showing

- Verify the language was set: `AppState.shared.currentLanguage`
- Check that the language is supported (en, de, fr, it, es)
- Ensure the translation file exists for that language

### Translation File Errors

If JSON syntax errors prevent loading:
- Validate JSON: Use `jsonlint` or an online JSON validator
- Check for missing commas or quotes
- Ensure no trailing commas in objects/arrays

## Related Documentation

- **Localization Service API**: See `LocalizationService.swift`
- **Localization Keys**: See `LocalizationKeys.swift`
- **Translation Files**: `Sources/TUIkit/Localization/translations/`
