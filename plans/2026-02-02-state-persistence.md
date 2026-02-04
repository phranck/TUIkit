# State Persistence (Session Continuity / Crash Recovery)

## Context

Builds on the State Storage Identity refactoring. `StateStorage` keeps `@State` values
stable in memory across render passes. This feature adds optional disk persistence so
that state can survive app restarts or crashes.

## Use Cases in Terminal Apps

1. **Crash Recovery** — SIGTERM/SIGINT: write last state to disk, restore on restart
2. **Session Continuity** — e.g. a TUI file manager remembers current directory, scroll position
3. **Explicit Save/Restore** — user-triggered (keybinding for "Save Session")

**Not a use case:** iOS-style background killing (does not exist in terminal apps).

## Design Sketch

### New Property Wrapper: `@RestoredState`

```swift
@RestoredState var currentPath: String = "~"
@RestoredState var scrollOffset: Int = 0
```

Difference from `@State`: values are serialized to disk on change (debounced) or on
app shutdown, and restored on next launch.

**Constraint:** `Value` must be `Codable`. `@State` remains without this constraint.

### `StatePersistenceAdapter` Protocol

```swift
protocol StatePersistenceAdapter {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data?
    func removeAll() throws
}
```

Default implementation: JSON file at `~/.config/<app-name>/state.json` or
XDG-compliant path.

### Integration with `StateStorage`

`StateStorage` gains an optional `persistence: StatePersistenceAdapter?`.
On `storage(for:default:)` lookup, disk is checked first, then default is used.
On value change, disk write is triggered (debounced).

### Signal Handler for Crash Recovery

`AppRunner` registers signal handlers for SIGTERM/SIGINT that call
`StateStorage.flush()` before the app terminates.

## Dependencies

- **State Storage Identity must be completed** (Phase 1-4 minimum)
- `Codable` constraint only affects `@RestoredState`, not `@State`
- Signal handlers must coordinate with existing terminal cleanup (raw mode restore)

## Open Questions

1. **Debounce interval?** Write every state change immediately vs. batched (e.g. every 500ms)?
2. **Encryption?** Sensitive data in state? Probably not needed for terminal apps.
3. **Migration?** What if state structure changes between app versions?
4. **Granularity?** Everything in one file or one file per view identity?

## Status

- [ ] Finalize design
- [ ] `StatePersistenceAdapter` protocol + file implementation
- [ ] `@RestoredState` property wrapper
- [ ] Integration into `StateStorage`
- [ ] Signal handlers in `AppRunner`
- [ ] Tests
- [ ] Documentation
