# Environment System Architecture Analysis

## Overview
The Environment system in TUIkit is **rendering-independent**. It consists of three independent subsystems that flow into RenderContext but are not inherently coupled to rendering types.

---

## 1. ENVIRONMENT FILES

### Location
- `/Users/phranck/Developer/Projects/Private/TUIkit/Sources/TUIkit/Environment/`

### Files
1. **Environment.swift** (169 lines)
   - `EnvironmentKey` protocol (public)
   - `EnvironmentValues` struct (public)
   - `EnvironmentModifier<Content, V>` struct (internal)
   - Badge, ListStyle, SelectionDisabled keys (private)

2. **TUIContext.swift** (271 lines)
   - `LifecycleManager` class (final, thread-safe)
   - `TUIContext` class (final, dependency container)

3. **Preferences.swift** (269 lines)
   - `PreferenceKey` protocol (public)
   - `PreferenceValues` struct (public)
   - `PreferenceStorage` class (final, thread-local)
   - `PreferenceModifier<Content, K>` struct (internal)
   - `OnPreferenceChangeModifier<Content, K>` struct (internal)

---

## 2. KEY FINDING: ENVIRONMENT IS RENDERING-INDEPENDENT

### EnvironmentValues Structure
```swift
public struct EnvironmentValues: @unchecked Sendable {
    private var storage: [ObjectIdentifier: Any] = [:]
    
    public subscript<K: EnvironmentKey>(key: K.Type) -> K.Value {
        get/set
    }
    
    func setting<V>(_ keyPath: WritableKeyPath<Self, V>, to value: V) -> Self
}
```

**Independence Analysis:**
- Pure data container with no dependencies on Rendering types
- No RenderContext, FrameBuffer, Renderable, or Terminal references
- Contains only values (types, colors, styling enums, etc.)
- Completely serializable/copyable

### FocusManager: The ONLY Exception (Environment ↔ Rendering Link)
FocusManager is defined in Focus module but added to EnvironmentValues via extension:

```swift
// In Focus/Focus.swift - lines 58-65
extension EnvironmentValues {
    public var focusManager: FocusManager {
        get { self[FocusManagerKey.self] }
        set { self[FocusManagerKey.self] = newValue }
    }
}

private struct FocusManagerKey: EnvironmentKey {
    static let defaultValue = FocusManager()
}
```

**Critical Point:** FocusManager is NOT rendering-specific—it's an interaction/event handler. It manages:
- Focus sections and focusable elements
- Keyboard navigation
- State tracking

It's only linked to rendering because interactive views (Button, TextField) need to register themselves during render time.

---

## 3. RENDERCONTEXT STRUCTURE

Location: `/Users/phranck/Developer/Projects/Private/TUIkit/Sources/TUIkit/Rendering/RenderContext.swift`

```swift
public struct RenderContext {
    // Layout constraints
    public var availableWidth: Int
    public var availableHeight: Int
    
    // Environment (independent of rendering)
    public var environment: EnvironmentValues
    
    // TUI services
    var tuiContext: TUIContext
    var identity: ViewIdentity
    
    // Rendering-specific state
    var activeFocusSectionID: String?
    var pulsePhase: Double = 0
    var cursorTimer: CursorTimer?
    var focusIndicatorColor: Color?
    var hasExplicitWidth: Bool = false
    var hasExplicitHeight: Bool = false
    var isMeasuring: Bool = false
}
```

**Key Insight:** RenderContext is a pipeline that carries three types of information:
1. **Rendering constraints** (width/height, measuring flag)
2. **Environment values** (pure data)
3. **Runtime services** (TUIContext)

EnvironmentValues is one field among many—it's not special to rendering.

---

## 4. TUICONTEXT: RUNTIME SERVICES CONTAINER

```swift
final class TUIContext: @unchecked Sendable {
    let lifecycle: LifecycleManager          // View appear/disappear/task management
    let keyEventDispatcher: KeyEventDispatcher
    let preferences: PreferenceStorage      // Bottom-up preference collection
    let stateStorage: StateStorage          // Persistent @State values
    let renderCache: RenderCache            // EquatableView memoization
}
```

**What it stores:**
- **Lifecycle** — appear/disappear callbacks, async tasks
- **Key events** — handlers registered by interactive views
- **Preferences** — collected during rendering (bottom-up)
- **State storage** — @State values indexed by ViewIdentity
- **Render cache** — memoized FrameBuffer output

**Where it's used:**
- Owned by `AppRunner` (the app instance)
- Passed to every `RenderContext`
- Accessed by modifiers via `context.tuiContext`

**No rendering types:** TUIContext contains only pure data structures and managers—no FrameBuffer, Renderable, Terminal, etc.

---

## 5. PREFERENCE SYSTEM

Two-way data flow:
- **Environment:** Top-down (parent → child via context)
- **Preferences:** Bottom-up (child → parent during rendering)

```swift
public protocol PreferenceKey {
    associatedtype Value
    static var defaultValue: Value { get }
    static func reduce(value: inout Value, nextValue: () -> Value)
}

public struct PreferenceValues {
    private var storage: [ObjectIdentifier: Any] = [:]
}

final class PreferenceStorage: @unchecked Sendable {
    private var stack: [PreferenceValues] = [PreferenceValues()]
    private var callbacks: [ObjectIdentifier: [(Any) -> Void]] = [:]
}
```

**Flow:**
1. Views set preferences via `.preference(key:, value:)` modifier
2. PreferenceStorage collects them in a stack during rendering
3. Parent views read collected preferences after children render

---

## 6. ENVIRONMENT → RENDERING FLOW

### EnvironmentModifier (Internal)
```swift
struct EnvironmentModifier<Content: View, V>: View {
    let content: Content
    let keyPath: WritableKeyPath<EnvironmentValues, V>
    let value: V
    
    var body: some View { content }
}

extension EnvironmentModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let modifiedEnvironment = context.environment.setting(keyPath, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}
```

**Key flow:**
1. Modifier reads current environment from context
2. Creates modified copy via `setting(keyPath:, to:)`
3. Creates new context with modified environment
4. Renders content with new context (environment flows down)

### PreferenceModifier (Internal)
```swift
extension PreferenceModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        context.tuiContext.preferences.setValue(value, forKey: K.self)
        return TUIkit.renderToBuffer(content, context: context)
    }
}
```

---

## 7. VIEWMODIFIER PROTOCOL (Core)

Location: `/Users/phranck/Developer/Projects/Private/TUIkit/Sources/TUIkit/Core/ViewModifier.swift`

```swift
@MainActor
public protocol ViewModifier {
    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer
    func adjustContext(_ context: RenderContext) -> RenderContext
}
```

**Key findings:**
- ViewModifier operates on **FrameBuffer level** (post-rendering)
- Takes rendered buffer and returns modified buffer
- Has access to RenderContext for reading constraints/environment/services
- Used by modifiers like `.padding()`, `.frame()`, `.foregroundColor()`

### ModifiedView Structure
```swift
public struct ModifiedView<Content: View, Modifier: ViewModifier>: View {
    public let content: Content
    public let modifier: Modifier
    public var body: Never { fatalError("ModifiedView renders via Renderable") }
}

extension ModifiedView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let adjustedContext = modifier.adjustContext(context)
        let childBuffer = TUIkit.renderToBuffer(content, context: adjustedContext)
        return modifier.modify(buffer: childBuffer, context: context)
    }
}
```

**Rendering flow:**
1. Modifier adjusts context (e.g., reduce width for padding)
2. Content renders with adjusted context → produces FrameBuffer
3. Modifier transforms buffer (e.g., add padding lines)
4. Returns modified buffer

**ViewModifier does NOT directly depend on RenderContext internals** — it only uses what it needs (adjustContext hook, constraint reading).

---

## 8. CAN ENVIRONMENT BE SEPARATED FROM RENDERING?

### YES, with caveats:

**Completely separable:**
- `EnvironmentValues` struct
- `EnvironmentKey` protocol
- `PreferenceKey` protocol
- `PreferenceValues` struct
- Preference collection logic

These are pure data structures with zero rendering dependencies.

**Already separated (independent modules):**
- `LifecycleManager`
- `KeyEventDispatcher`
- `StateStorage`
- `RenderCache`

These can exist without rendering and are composition members of TUIContext.

**Tightly coupled (requires refactoring):**
- `EnvironmentModifier` — uses `Renderable` protocol and `renderToBuffer()` function
- `PreferenceModifier` — uses `Renderable` protocol and `renderToBuffer()` function
- `FocusManager` — conceptually independent but registered during render time

### Theoretical Separation Strategy:
```
Current:
  Environment/ ← imports from Rendering/
    └ uses Renderable, renderToBuffer(), RenderContext

Proposed:
  Core/Environment/    ← pure data (EnvironmentValues, PreferenceValues)
  Rendering/Modifiers/ ← EnvironmentModifier, PreferenceModifier (use Renderable)
  Runtime/             ← TUIContext, services
```

---

## 9. DEPENDENCY SUMMARY

### Environment Module Dependencies
```
Environment.swift
  ├─ imports: Foundation (none from Rendering)
  └─ exports: EnvironmentKey, EnvironmentValues
  
  EnvironmentModifier (internal)
    └─ depends: Renderable, RenderContext, renderToBuffer()

TUIContext.swift
  ├─ imports: Foundation
  └─ exports: LifecycleManager, TUIContext
  
  (No dependencies on Rendering types)

Preferences.swift
  ├─ imports: (none visible)
  ├─ exports: PreferenceKey, PreferenceValues, PreferenceStorage
  │
  └─ PreferenceModifier, OnPreferenceChangeModifier (internal)
      └─ depend: Renderable, RenderContext, renderToBuffer()
```

### Rendering Dependencies on Environment
```
RenderContext.swift
  ├─ contains: environment: EnvironmentValues
  ├─ contains: tuiContext: TUIContext
  └─ (imports EnvironmentValues and TUIContext)

Renderable.swift (protocol)
  ├─ uses: RenderContext (passed to renderToBuffer)
  └─ (does not import EnvironmentValues directly)
```

---

## 10. CONCRETE EXAMPLE: FOCUS MANAGER INTEGRATION

FocusManager is stored in EnvironmentValues but accessed during rendering:

```swift
// In Focus/Focus.swift
extension EnvironmentValues {
    public var focusManager: FocusManager {
        get { self[FocusManagerKey.self] }
        set { self[FocusManagerKey.self] = newValue }
    }
}

// In ButtonCore or similar interactive view (Renderable conformance)
extension _ButtonCore: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        
        // Register self if not disabled
        if !isDisabled {
            focusManager.register(self)
        }
        
        // ... rendering logic
    }
}
```

**Flow:**
1. FocusManager lives in environment (pure data)
2. During rendering (renderToBuffer), view reads focusManager from context.environment
3. View registers itself with focusManager
4. FocusManager tracks focus state across multiple render passes
5. View reads focused state to apply focus styling

---

## 11. LIFECYCLE OF ENVIRONMENT

### Per-Render-Pass
1. **RenderContext created** at root with fresh EnvironmentValues
2. **EnvironmentModifiers** create modified contexts as they recurse down
3. **Interactive views** register with FocusManager (from environment)
4. **Preferences collected** in stack during bottom-up merge

### Cross-Render-Pass (Persistent)
- EnvironmentValues contents persist (parent set them, stored in context)
- FocusManager state persists (across renders, tracks focus)
- PreferenceStorage resets each render (callbacks + stack cleared at start)
- StateStorage persists @State values (indexed by identity)

---

## SUMMARY TABLE

| Component | Rendering-Independent? | Stored Where | Purpose |
|-----------|------------------------|--------------|---------|
| EnvironmentValues | YES | Core (would be) | Pure data config |
| EnvironmentKey | YES | Core (would be) | Key protocol |
| EnvironmentModifier | NO | Rendering | Modifier for environment |
| PreferenceValues | YES | Core (would be) | Pure data collection |
| PreferenceKey | YES | Core (would be) | Key protocol |
| PreferenceStorage | YES | Runtime | Collects prefs during render |
| PreferenceModifier | NO | Rendering | Modifier for preferences |
| FocusManager | PARTIAL | Focus module | Interaction handler (registered at render) |
| TUIContext | YES | Runtime | Service container |
| LifecycleManager | YES | Runtime | Lifecycle tracking |
| KeyEventDispatcher | YES | Runtime | Event routing |

---

## FINAL ANSWER

**Q: How does EnvironmentValues flow into RenderContext?**
A: RenderContext has a public `environment: EnvironmentValues` field. Views/modifiers read from it and can create modified contexts via `context.withEnvironment(_:)`.

**Q: Is EnvironmentValues independent of rendering?**
A: YES. EnvironmentValues is pure data. Only the modifiers that modify it (EnvironmentModifier, PreferenceModifier) depend on rendering.

**Q: What is TUIContext?**
A: Runtime service container owned by AppRunner. Bundles lifecycle, key events, preferences, state, and render cache. Passed to every RenderContext so modifiers can access services during rendering.

**Q: Can Environment be separated from Rendering?**
A: YES. The data structures are already independent. Only the modifier wrappers (EnvironmentModifier, PreferenceModifier) need refactoring to live in Rendering module (they use Renderable protocol).

**Q: Does ViewModifier depend on RenderContext?**
A: Only indirectly. ViewModifier.modify receives RenderContext to read constraints, but doesn't depend on its internal structure—it just reads what it needs.
