# TUIkit i18n Developer Guide

This guide is for developers working on TUIkit's localization infrastructure, not for app developers using TUIkit. See [i18n-guide.md](i18n-guide.md) for end-user documentation.

## Architecture Overview

The TUIkit localization system consists of:

### 1. **LocalizationService** (`LocalizationService.swift`)
Core service that manages:
- Language selection and persistence
- JSON translation file loading
- String resolution with fallback chains
- Thread-safe access via `NSLock`

### 2. **LocalizationKey** (`LocalizationKeys.swift`)
Type-safe enum hierarchy providing:
- Compile-time safe key references
- Organized by category (Button, Label, Error, etc.)
- Convenient extensions for LocalizedString and Text views

### 3. **LocalizedString** (`LocalizedString.swift`)
Simple View component that displays localized strings by key.

### 4. **Translation Files** (`Localization/translations/*.json`)
JSON files for each language:
- `en.json` - English (primary reference)
- `de.json` - German
- `fr.json` - French
- `it.json` - Italian
- `es.json` - Spanish

## Adding New Translation Categories

To add a new category of strings (e.g., for a new UI area):

### Step 1: Update LocalizationKey Enum

Edit `Sources/TUIkit/Localization/LocalizationKeys.swift`:

```swift
public enum LocalizationKey {
    // ... existing categories

    /// New category for notifications
    public enum Notification: String {
        case success = "notification.success"
        case warning = "notification.warning"
        case error = "notification.error"
    }
}

// Add convenient extension
extension LocalizedString {
    public init(_ key: LocalizationKey.Notification) {
        self.init(key.rawValue)
    }
}

extension Text {
    public init(localized key: LocalizationKey.Notification) {
        self.init(localized: key.rawValue)
    }
}

extension LocalizationService {
    public func string(for key: LocalizationKey.Notification) -> String {
        string(for: key.rawValue)
    }
}
```

### Step 2: Add Keys to All Translation Files

For each of the 5 language files:

**en.json**:
```json
{
  "notification.success": "Success",
  "notification.warning": "Warning",
  "notification.error": "Error",
  ...
}
```

**de.json**:
```json
{
  "notification.success": "Erfolg",
  "notification.warning": "Warnung",
  "notification.error": "Fehler",
  ...
}
```

**fr.json**, **it.json**, **es.json**: Similar translations

### Step 3: Add Tests

Edit `Tests/TUIkitTests/LocalizationKeyConsistencyTests.swift`:

```swift
// MARK: - Notification Key Tests

func testAllNotificationKeysExistInTranslations() {
    let keys = [
        LocalizationKey.Notification.success,
        LocalizationKey.Notification.warning,
        LocalizationKey.Notification.error,
    ]

    for key in keys {
        XCTAssertNotNil(
            englishTranslations[key.rawValue],
            "Notification key '\(key.rawValue)' not found in translations"
        )
    }
}
```

Also update `testNoExtraneousKeysInTranslations()` to include the new keys in the `enumKeys` set.

Update `testAllEnumKeysAreCovered()` to reflect the new key count.

### Step 4: Add to Service Extensions (optional)

If you want LocalizationService to support the new category:

```swift
// LocalizationService.swift (inside public extension)
public func string(for key: LocalizationKey.Notification) -> String {
    string(for: key.rawValue)
}
```

### Step 5: Run Tests

```bash
swift test --filter LocalizationKeyConsistencyTests
```

All consistency tests should pass, verifying:
- Every enum key exists in translations
- No extraneous keys in translation files
- Correct total key count

## Adding a New Language

To add support for a completely new language:

### Step 1: Update Language Enum

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
        // ... existing cases
        case .portuguese: "Português"  // NEW
        }
    }
}
```

### Step 2: Create Translation File

Create `Sources/TUIkit/Localization/translations/pt.json` with ALL keys from the framework:

```json
{
  "button.ok": "Tudo bem",
  "button.cancel": "Cancelar",
  ...
  // Include ALL keys - use en.json as reference
}
```

**Important**: Every key from en.json must be present in the new language file.

### Step 3: Run Consistency Tests

```bash
swift test --filter LocalizationKeyConsistencyTests
```

This will verify that all enum keys exist in the new language file.

### Step 4: Test the New Language

```swift
let service = LocalizationService()
service.setLanguage(.portuguese)

// Verify strings load correctly
let ok = service.string(for: .button(.ok))
XCTAssertNotEqual(ok, "button.ok")  // Should be translated
```

## Key Design Principles

### 1. Dot-Notation Keys
Keys use `category.subcategory` format:
- `button.ok` - Button in Button category
- `error.not_found` - "not_found" error in Error category
- `validation.email_invalid` - "email_invalid" in Validation category

**Why**: Clearly organizes related strings, easy to grep, matches JSON structure.

### 2. Enum Categories
Each JSON prefix becomes an enum:
- All `button.*` keys → `LocalizationKey.Button` enum
- All `error.*` keys → `LocalizationKey.Error` enum
- All `validation.*` keys → `LocalizationKey.Validation` enum

**Why**: Type safety, IDE autocomplete, compile-time checking.

### 3. Fallback Chain
Resolution tries: Current Language → English → Key
```swift
service.setLanguage(.french)
let text = service.string(for: "button.ok")
// Tries: French → English → Returns "button.ok"
```

**Why**: Graceful degradation if a key is missing or language incomplete.

### 4. Persistence
Language choice is saved to disk and restored on app restart:
- **macOS**: `~/Library/Application Support/tuikit/language`
- **Linux**: `~/.config/tuikit/language`

**Why**: Users expect their language preference to persist.

### 5. Thread Safety
`LocalizationService` uses `NSLock()` for thread-safe access:
- Language switching is atomic
- Translation loading is atomic
- Multiple threads can safely access simultaneously

**Why**: Apps may need to change language from background threads.

## Testing Strategy

### LocalizationServiceTests.swift
Core functionality tests:
- Bundle loading for all languages
- String resolution and dot-notation
- Fallback behavior
- Language switching
- Persistence to disk
- Thread safety

### LocalizationKeyTests.swift
Type-safe key testing:
- Each key category resolves correctly
- Keys work across all languages
- Enum raw values match string keys

### LocalizationKeyConsistencyTests.swift
**Most important**: Validates sync between code and translations:
- Every enum key exists in en.json
- Every enum key exists in all other languages
- No extraneous keys in translation files
- Expected total key count

**Run after any localization changes**:
```bash
swift test --filter LocalizationKeyConsistencyTests
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
2. **Dot-separated keys**: `"button.ok"`, not `"button": { "ok": ... }`
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

## Performance Considerations

### Caching
Translations are cached per language after first load:
```swift
// First access: loads from Bundle, caches
let text1 = service.string(for: "button.ok")

// Subsequent accesses: use cache
let text2 = service.string(for: "button.ok")  // Cache hit
```

### Bundle Resources
Translation files are bundled at compile time:
- Included in `Package.swift` with `.copy("Localization/translations")`
- Loaded via `Bundle.module.url(...)`
- Zero runtime overhead for bundling

### Lock Contention
While `NSLock` is used, contention is minimal:
- Lock is only held during cache operations
- String lookups are fast dictionary access
- Lock is released immediately after

## Common Pitfalls

### 1. Forgetting a Language
Adding a key but not translating to all 5 languages:
- **Caught by**: `testNoExtraneousKeysInTranslations()` in consistency tests
- **Fix**: Add key to all 5 JSON files

### 2. Typos in Enum
Using `button.ок` (Cyrillic 'k') instead of `button.ok` (Latin 'k'):
- **Caught by**: IDE if you copy from enum
- **Prevention**: Always use `LocalizationKey.Button.ok.rawValue`

### 3. Mismatched JSON Structure
Changing key format after release (e.g., `button_ok` → `button.ok`):
- **Issue**: Breaks existing preferences if keys changed
- **Prevention**: Keys are permanent API, don't rename

### 4. Incomplete Translations
Leaving English text in non-English translations:
- **Testing**: Manual review of all languages
- **Tools**: String comparison scripts (planned for future)

### 5. Character Encoding Issues
Special characters garbled in translation files:
- **Cause**: File saved in wrong encoding
- **Fix**: Ensure UTF-8 encoding, validate with `jsonlint`

## Future Enhancements

Planned improvements to the localization system:

1. **Pluralization**: Handle plural forms ("1 item", "2 items")
2. **Interpolation**: Support `"Hello {name}"` style formatting
3. **Context**: Multiple translations based on context (e.g., Cancel as button vs command)
4. **Import/Export Tool**: `tuikit i18n export --format=xliff` for easier translation management
5. **String Analysis Tool**: Detect unused keys and missing translations
6. **RTL Support**: Right-to-left language support for Arabic, Hebrew

## References

- **Main Documentation**: See [i18n-guide.md](i18n-guide.md)
- **LocalizationService API**: `Sources/TUIkit/Localization/LocalizationService.swift`
- **LocalizationKey Enums**: `Sources/TUIkit/Localization/LocalizationKeys.swift`
- **Translation Files**: `Sources/TUIkit/Localization/translations/`
