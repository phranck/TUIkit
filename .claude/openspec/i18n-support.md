# OpenSpec: i18n Support for TUIkit

**Change ID**: i18n-support
**Date**: 2026-02-14
**Status**: Proposal

---

## Why

TUIkit currently has all UI strings hardcoded in English. To support international users and make the framework production-ready, we need:
- Multi-language support (EN, DE, FR, IT, ES)
- Persistent language selection across sessions
- Cross-platform compatibility (macOS + Linux)
- Standard, maintainable translation architecture

---

## What Changes

### New Components

1. **LocalizationService** (framework-internal)
   - Manages language loading and resolution
   - Handles XDG/standard paths for language config
   - Caches translations in memory
   - Provides string lookups via dot-notation keys

2. **Language Configuration**
   - Persistent storage: `~/.config/tuikit/language` (Linux) / `~/Library/Application Support/tuikit/language` (macOS)
   - Format: Single-line file with language code (e.g., `de`)
   - Fallback: Always English if language not available or file missing

3. **Translation Files**
   - Location: `Sources/TUIkit/Localization/translations/`
   - Format: JSON per language (`en.json`, `de.json`, `fr.json`, `it.json`, `es.json`)
   - Structure: Hierarchical with dot-notation keys
   - Example: `button.ok`, `error.invalid_input`, `label.search`

4. **Environment Integration**
   - Add `currentLanguage` to `EnvironmentValues`
   - Add `localizationService` to `EnvironmentValues`
   - Make language selection accessible to all views

5. **API Changes**
   - Public: `LocalizedString(key:)` view modifier
   - Public: `Text(\.localized, "button.ok")` convenience
   - Public: `AppState.setLanguage(_:)` to change language at runtime
   - Internal: `Localizer` utility for string resolution

### Modified Components

- All hardcoded UI strings in views → `LocalizedString` or `Text(key:)`
- Button labels, error messages, placeholder text, status messages
- Approximately 100-150 string replacements across codebase

### Removed Components

- None (fully additive)

---

## Capabilities

### New/Modified/Removed

- `LocalizationService`: NEW — Language management and translation loading
- `LocalizedString`: NEW — View for localized text output
- `Text(\.localized, "key")`: NEW — Convenience for localized text
- `AppState.setLanguage(_:)`: NEW — Runtime language switching
- `EnvironmentValues.currentLanguage`: NEW — Environment key for current language
- All hardcoded strings: MODIFIED → Use localization keys

---

## Requirements (WHEN/THEN Scenarios)

### Requirement 1: Multi-Language Support

**WHEN** the app loads
**THEN** it checks for a stored language preference in XDG config path

**WHEN** no stored preference exists
**THEN** it defaults to system locale (or English if system locale not supported)

**WHEN** the user changes language via `AppState.setLanguage("de")`
**THEN** the preference is persisted and the UI re-renders with new strings

### Requirement 2: String Resolution

**WHEN** a view requests string with key `"button.ok"`
**THEN** it retrieves the localized string from the current language JSON file

**WHEN** the key doesn't exist in the requested language
**THEN** it falls back to English string

**WHEN** the key doesn't exist in English either
**THEN** it returns the key itself (e.g., `"button.ok"`) as fallback

### Requirement 3: Cross-Platform Paths

**ON macOS**
**THEN** language config is stored in `~/Library/Application Support/tuikit/language`

**ON Linux**
**THEN** language config is stored in `~/.config/tuikit/language`

**IF** path doesn't exist
**THEN** it's created automatically on first language change

### Requirement 4: Supported Languages

**WHEN** app starts
**THEN** it supports: EN (English), DE (Deutsch), FR (Français), IT (Italiano), ES (Español)

**WHEN** user selects unsupported language
**THEN** it rejects with error and maintains current language

### Requirement 5: Build Integration

**WHEN** building the package
**THEN** translation JSON files are bundled as package resources

**WHEN** running tests
**THEN** localization service works with bundled translations (no filesystem dependency)

---

## Design Decisions

### JSON over other formats
- Rationale: Industry standard, zero dependencies, cross-platform, easy to maintain
- Alternative considered: .strings (macOS-specific), YAML (extra dependency)

### XDG paths
- Rationale: POSIX standard, works on Linux, macOS, and other Unix-like systems
- Fallback: Swift's `FileManager.default.urls(for: .applicationSupportDirectory)` handles platform differences automatically

### Persistent vs Environment-only
- Decision: Persistent in config file
- Rationale: User expects language preference to survive app restarts
- Implementation: Load on startup, save on change

### Hierarchical keys (dot-notation)
- Rationale: Scales better than flat structure, mirrors JSON hierarchy, familiar to developers
- Example structure:
  ```json
  {
    "button": { "ok": "OK", "cancel": "Cancel" },
    "error": { "invalid_input": "Invalid input" }
  }
  ```

---

## Implementation Plan

### Phase 1: Infrastructure (2-3 hours)
- [ ] Create `LocalizationService` class
- [ ] Implement XDG path resolution (`localizationPath()` utility)
- [ ] Create translation JSON files (skeleton with keys)
- [ ] Wire into `EnvironmentValues`

### Phase 2: Core API (1-2 hours)
- [ ] Implement `LocalizedString` view
- [ ] Implement `Text(\.localized, "key")` convenience
- [ ] Add `AppState.setLanguage(_:)` method
- [ ] Add language persistence (read/write config file)

### Phase 3: String Replacement (3-4 hours)
- [ ] Audit all hardcoded strings (estimate 100-150)
- [ ] Replace in Views (buttons, labels, messages, placeholders)
- [ ] Update error messages in services
- [ ] Translation coverage check

### Phase 4: Testing (1-2 hours)
- [ ] Unit tests for `LocalizationService`
- [ ] Test path resolution (macOS vs Linux)
- [ ] Test fallback behavior (missing keys, languages)
- [ ] Test persistence (language survives restart)
- [ ] Integration tests with views

### Phase 5: Documentation (30 min)
- [ ] Add to README: "Supported Languages"
- [ ] Document how to add new language
- [ ] Document how to use in custom views

**Total Estimated**: 8-12 hours

---

## Acceptance Criteria

- [ ] All 5 languages (EN, DE, FR, IT, ES) fully translated
- [ ] Language preference persists across sessions
- [ ] XDG paths work correctly on macOS and Linux
- [ ] Fallback to English for missing keys/languages
- [ ] All existing tests pass (no breaking changes)
- [ ] 20+ new tests for localization service and edge cases
- [ ] No runtime dependency on external crates
- [ ] All UI strings use localization (audit completeness)
- [ ] Example app demonstrates language switching
- [ ] Documentation added for adding new languages

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Large number of strings to replace (100-150) | Systematic audit, find-replace with careful review |
| XDG path issues on macOS | Use `FileManager.urls(for:)` which handles both |
| Test isolation with persistent files | Mock `LocalizationService` in tests, or use temp directory |
| Missing translations (incomplete JSON) | Implement strict validation during build, warn on incomplete files |
| Performance of JSON parsing | Cache in memory on load, lazy evaluation not needed |

---

## Questions for Review

1. Should we support user-provided custom translations (external JSON)?
2. Should language selector be a built-in UI component, or left to user apps?
3. Do we want to support pluralization rules (e.g., "1 file" vs "N files")?
4. Any other languages besides EN/DE/FR/IT/ES?

---

**Status**: Ready for Design Review & Approval

