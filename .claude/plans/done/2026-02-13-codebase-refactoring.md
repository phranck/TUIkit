# Refactor: Codebase Quality & SwiftUI API Parity

## Preface

Konsolidierte Findings aus zwei Audits:
1. **SwiftUI API Parity** - Vergleich der oeffentlichen APIs mit SwiftUI-Signaturen
2. **Code Quality** - Duplikate, Inkonsistenzen, grosse Dateien

---

## 1. Focus-Registration Code-Duplikation (HIGH)

### Problem
9 interaktive Views wiederholen ~80 LOC identischen Focus-Registration-Code:
- FocusID aus StateStorage laden/erstellen
- FocusManager-Registration
- Disabled-State pruefen

### Betroffene Dateien
- `Button.swift`, `TextField.swift`, `SecureField.swift`
- `Toggle.swift`, `Slider.swift`, `Stepper.swift`
- `RadioButton.swift`, `List.swift`, `Table.swift`

### Umsetzung
Shared Helper extrahieren, z.B.:

```swift
struct FocusRegistration {
    let focusID: String
    let isFocused: Bool

    static func resolve(
        context: RenderContext,
        explicitFocusID: String?,
        defaultPrefix: String,
        propertyIndex: Int
    ) -> FocusRegistration { ... }
}
```

---

## 2. FocusID-Generierung standardisieren (HIGH)

### Problem
Verschiedene Strategien fuer Default-FocusIDs:
- `Button`: `"button-\(label)"` (nutzt User-Daten, Kollisionsgefahr bei gleichen Labels)
- `List`: `"list-\(context.identity.path)"` (nutzt internen Pfad)
- `Table`: `"table-\(context.identity.path)"`
- `RadioButton`: `"radio-group-\(context.identity.path)"`

### Umsetzung
Alle auf `context.identity.path` standardisieren. Einzeilige Aenderung pro Datei.

---

## 3. State-Property-Index Dokumentation (MEDIUM)

### Problem
`StateStorage.StateKey(identity:, propertyIndex:)` verwendet Magic Numbers (0, 1, 2...) ohne Dokumentation, was jeder Index speichert.

### Betroffene Dateien
Alle 9 interaktiven Views + Spinner

### Umsetzung
Pro View dokumentierte Konstanten:

```swift
private enum StateIndex {
    static let focusID = 0
    static let handler = 1
}
```

---

## 4. Disabled-State Inkonsistenz (MEDIUM)

### Problem
`isDisabled` wird in 9 Views unterschiedlich gehandhabt:
- Manche pruefen vor Focus-Registration
- Manche pruefen nach Registration
- Unterschiedliche visuelle Darstellung des Disabled-State

### Umsetzung
Einheitliches Pattern definieren und in allen Views anwenden. Idealerweise Teil des Focus-Registration-Helpers aus Punkt 1.

---

## 5. List API vereinfachen (MEDIUM)

### Problem
List hat 8 Init-Overloads mit TUI-spezifischen Parametern im Initializer (`emptyPlaceholder`, `showFooterSeparator`, `focusID`). SwiftUI loest das ueber Modifier.

### Umsetzung
- TUI-spezifische Parameter als Modifier anbieten: `.listEmptyPlaceholder()`, `.listFooterSeparator()`
- `focusID` als `.focusID()` Modifier (konsistent ueber alle Views)
- Init-Overloads reduzieren

---

## 6. Grosse Dateien aufteilen (LOW)

### Kandidaten
| Datei | Zeilen | Vorschlag |
|-------|--------|-----------|
| `List.swift` | 879 | Public API + `_ListCore` trennen |
| `StatusBarItem.swift` | 757 | Render-Logik extrahieren |
| `Color.swift` | 600 | Color-Resolution auslagern |
| `TextFieldHandler.swift` | 600 | Cursor-Management extrahieren |
| `Focus.swift` | 590 | `FocusManager`, `FocusSection`, `Focusable` trennen |
| `Renderable.swift` | 553 | Protokolle + RenderContext trennen |
| `Stacks.swift` | 527 | VStack/HStack/ZStack einzeln |
| `Table.swift` | 517 | Column-Layout extrahieren |
| `TextField.swift` | 506 | Text-Editing-Handler extrahieren |

---

## 7. SecureField ViewBuilder-Label-Variante (LOW)

### Problem
SwiftUI bietet `SecureField(text:prompt:label:)` mit `@ViewBuilder`. TUIkit hat nur die String-Variante.

### Umsetzung
ViewBuilder-Init analog zu TextField hinzufuegen.

---

## Priorisierte Reihenfolge

| # | Task | Aufwand | Impact |
|---|------|---------|--------|
| 1 | Focus-Registration Helper extrahieren | Mittel | Hoch (entfernt ~80 LOC Duplikation) |
| 2 | FocusID-Generierung standardisieren | Gering | Hoch (verhindert Bugs) |
| 3 | State-Property-Index Konstanten | Gering | Mittel (Lesbarkeit) |
| 4 | Disabled-State vereinheitlichen | Mittel | Mittel (Konsistenz) |
| 5 | List API Modifier-Migration | Hoch | Mittel (SwiftUI-Konformitaet) |
| 6 | Grosse Dateien aufteilen | Hoch | Gering (Wartbarkeit) |
| 7 | SecureField ViewBuilder | Gering | Gering (API-Vollstaendigkeit) |

---

## Verification

- `swift build` nach jeder Aenderung
- `swift test` - alle 1037+ Tests muessen bestehen
- Keine Verhaltensaenderung (reines Refactoring)
