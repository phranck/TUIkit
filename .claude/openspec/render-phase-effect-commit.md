# OpenSpec: Separate Measurement, Rendering, and Effect Commit

**Change ID**: render-phase-effect-commit
**Date**: 2026-07-21
**Status**: Implemented (2026-07-22, issues #55/#56/#57/#58 — PRs #59/#60/#61 + docs PR)
**GitHub Issue**: #13 ([P0-08])
**Depends on**: #10 (stable identity, merged), #12 (keyed traversal, merged)

---

## Why

The runtime evaluates view bodies up to three times per frame (first-frame header
measurement, main pass, header-correction pass), but effect registration is not
separated from evaluation. A single ambient `Bool` (`RenderContext.isMeasuring`)
is the only phase mechanism, and it is honored inconsistently:

- The first-frame header sizing pass (`RenderLoop.render()`, RenderLoop.swift:210-218)
  and the correction pass (RenderLoop.swift:237-249) run full renders **without**
  marking them as measurement. All effect guards are bypassed there.
- Roughly half of the effect sites carry no guard at all: key handlers
  (KeyPressModifier.swift:32, Menu.swift:297, AlertPresentationModifier.swift:108),
  preferences (Preferences.swift:28,52-70), `onChange` (OnChangeModifier.swift:43-59),
  header/status-bar registration (AppHeaderModifier.swift:52,
  StatusBarItemsModifier.swift:60-75), observation tracking and `markActive`
  (Renderable.swift:179-196), and the token-based `Spinner`/`_ImageCore` effects.

Observable defects today:

1. Effects from discarded trees commit live: `onAppear` fires and `.task` starts
   from the measurement pass; a view dropped by the correction pass keeps its
   effects and stays "visible" until the next frame because
   `currentRenderSlots` accumulates across passes within one frame.
2. Key handlers register 2-3x per frame (`clearHandlers()` runs once per frame,
   TUIContext.swift:515).
3. Focusables from the discarded pass win: `FocusSection.register` deduplicates
   by `focusID` (FocusSection.swift:40), so the *first* (abandoned) pass provides
   the live handlers.
4. `onChange` index claims shift across passes (`onChangeCounters` resets per
   frame, StateStorage.swift:184), corrupting first-frame change detection.
5. Preference callbacks fire multiple times per frame; reduce-based values
   accumulate (PreferenceKey.swift:150-156).
6. GC operates on the union of all passes instead of the committed tree.

## Reference model (SwiftUI)

SwiftUI separates phases strictly: body evaluation and layout measurement are
pure and may run arbitrarily often; effects are bound to identity lifetime in
the **committed** tree; per-frame data (preferences, focus declarations) are
values recomputed each update where the last committed tree simply replaces the
previous one; lifetime effects (`onAppear`, `task`) derive from the identity
diff between committed trees; `onChange`/`onPreferenceChange` actions run after
the update, never during it.

## Design decision

**Variant C — hybrid, mirroring SwiftUI's conceptual split** (chosen over a
monolithic frame transaction and over guard-patching):

The classification rule, documented at every effect site:

> **Does the effect outlive the frame? No → pass collector. Yes → pending diff.**

### 1. Phase model

```swift
public enum RenderPhase: Sendable {
    case measure   // layout sizing; no effect may reach live runtime state
    case render    // candidate-tree evaluation; effects recorded, never applied
}
```

- `RenderContext.phase: RenderPhase` (default `.render`) **replaces**
  `isMeasuring` completely. No deprecation bridge (project is WIP; user
  decision 2026-07-21). API-compat manifest is regenerated with the tool.
- Deliberate deviation from the issue text: commit is **not** a context phase.
  No view body is ever evaluated during commit, so a `.commit` case would be
  dead state. Commit is an explicit step in `RenderLoop` (see choreography).
  Document this deviation when closing #13.

### 2. Pass collectors (effects that do NOT outlive the frame)

Key handlers, preference values + callbacks, status-bar section items, header
buffer, focus sections/focusables.

- `RenderLoop` creates **fresh instances of the existing manager types** per
  pass and injects them via the environment. Effect sites remain unchanged —
  they keep writing to "their manager"; it just is the scratch instance.
  (Precedent: `context.isolatedForBackground()` used by Alert.)
- On commit, the final pass's collectors are adopted atomically into the live
  managers. Discarded passes are dropped; nothing to roll back because nothing
  live was touched.
- Persistent focus state (`activeSectionID`, `focusedID`) stays on the live
  `FocusManager`; only per-frame sections/focusables go through the collector.
  Today's `endRenderPass` validation becomes part of commit.

### 3. Pending diff (effects that DO outlive the frame)

`onAppear` actions, `onDisappear` registrations, `.task` mounts,
`onChange`/`onPreferenceChange` actions, markActive sets for
state/cache/observation GC.

- During `.render` passes only **records** are collected; no action runs, no
  task starts.
- At commit, the final record set is diffed against persistent state:
  - New slots → `onAppear` action fires (after tree construction — closer to
    the original; `RenderCycle.md` update required).
  - Vanished slots → disappear callback + task cancel.
  - Task mounts → `updateTask` restart-ID semantics (unchanged).
  - `onChange`: (old, new) computed during traversal; action and
    `setTrackedValue` deferred to commit. Index claims reset per **pass**
    instead of per frame (fixes defect 4).
  - GC runs on the **final** tree's active set only.

### 4. Frame choreography (`RenderLoop.render()`)

```
1. beginFrame                       (tracking reset, once per frame)
2. evaluate App.body                (hydration, pure)
3. [first frame only] measure pass  phase=.measure, scratch discarded,
                                    only header height kept
4. main pass                        phase=.render → collectors R1 + records P1
5. [header height differs]
   correction pass                  phase=.render → R2 + P2; R1/P1 discarded
6. COMMIT (the only point where live state mutates):
   a. final collectors → live managers (atomic), focus validation
   b. writeFrame                    (terminal output)
   c. lifecycle/task/onChange/preference effects via diff of final records
   d. GC with final active set
```

Effect actions run after `writeFrame` (6c), consistent with today's
`onDisappear` timing; state changes from `onAppear` trigger the next frame as
before. Header/status-bar renderings inside `writeFrame` are pure output
renderings with isolated, effect-free contexts.

### 5. Removals (no deprecations)

- `RenderContext.isMeasuring` (all 15 usage sites migrated).
- Token-based `LifecycleManager` APIs (`recordAppear(token:)`,
  `startTask(token:)`, …); `Spinner` and `_ImageCore` migrate to
  identity-based slots (sole remaining users).
- `StateRegistration.activeContext` / `counter` / `activeEnvironment` legacy
  fallbacks, once no path needs them.

## Documentation mandate (non-negotiable, user condition)

1. **In code**: every new type (`RenderPhase`, collectors, pending records)
   carries thorough doc comments with purpose, invariants, and the
   classification rule. The frame choreography lives as an architecture
   comment in `RenderLoop`. Every effect site states which pattern it follows
   and why.
2. **In DocC**: `RenderCycle.md` rewritten for the new model (phases, commit
   point, changed `onAppear` timing) plus a conceptual section on the internal
   structure — behavior and architecture yes, implementation details no.
3. Documentation is a checklist item in every plan, not end-polish.

## Testing strategy

1. **Characterization before rebuild** (own commits, gates green): tests
   pinning today's misbehavior (first-frame `onAppear` from measure pass,
   duplicate handlers from correction pass, `onChange` index shift), marked
   `withKnownIssue` where they show the wrong behavior (pattern exists for
   issue #14). They flip green during the rebuild and the markers drop.
2. **Harness**: `RuntimeCharacterizationHarness` gains the commit step and
   phase traces (`TraceRecorder` exists). Acceptance criteria become directly
   testable:
   - measure pass: zero effects (no tasks, handlers, state/cache/terminal mutation)
   - abandoned frame: zero effects
   - single-pass vs. correction-pass: identical buffer + identical effect traces
   - deterministic traces for header, status bar, preferences, focus, task,
     observation
3. **Gates per commit**: `./scripts/test-linux.sh` (macOS + Linux,
   warning-fatal), DocC diagnostics-free, API manifest regenerated via tool.
   Every commit green on its own (independently revertible steps).

## Plan split (each with its own Plan-Nr. via `plans next`)

1. **Plan 1 — Characterization + phase foundation**: characterization tests;
   `RenderPhase` replaces `isMeasuring` completely; measure pass marked
   `.measure` in `RenderLoop`. No collectors yet.
2. **Plan 2 — Pass collectors**: scratch instances for key handlers,
   preferences, status bar, header, focus; commit step 6a; correction pass
   discards cleanly.
3. **Plan 3 — Pending diff**: lifecycle/task/onChange/onPreferenceChange to
   record+commit; GC on final active set; `onAppear` timing change;
   `Spinner`/`_ImageCore` migration; remove token APIs +
   `StateRegistration` legacy.
4. **Plan 4 — Docs + closure**: `RenderCycle.md` + architecture article;
   diagnostics for unsupported user side effects in `body` (acceptance
   criterion, via existing `RuntimeDiagnostics`); final gate runs; close #13
   documenting the `.commit` deviation.

## Acceptance criteria (from issue #13)

- Framework-controlled measurement starts no tasks, registers no live
  handlers/subscriptions, commits no state, storage, cache, lifecycle, or
  terminal mutation. Arbitrary user side effects inside `body` are unsupported
  and are documented/diagnosed.
- An abandoned frame has no lifecycle or terminal side effects.
- Only commit changes terminal output and visible runtime records.
- Buffer and committed effects are identical across single-pass and
  correction-pass layouts.
- Deterministic phase traces cover header, status bar, preferences, focus,
  task, and Observation paths.
- Swift 6.0 macOS/Linux gates and DocC complete without diagnostics.

## Verified facts (audited 2026-07-21 on main @ 3219f2e)

- `RenderContext.isMeasuring` — RenderContext.swift:58; set only in
  ChildInfo.swift:232,252.
- Unmarked measure/correction passes — RenderLoop.swift:210-218, 237-249.
- Guarded sites — LifecycleModifier.swift:25,54,87; FocusRegistration.swift:67,107,121;
  FocusSectionModifier.swift:47,59; ModalPresentationModifier.swift:68;
  AlertPresentationModifier.swift:101; NavigationSplitView.swift:248,257.
- Unguarded sites — see "Why" above (all file:line refs re-checked post-pull).
- Per-frame reset points — TUIContext.beginRenderPass (TUIContext.swift:514-527),
  endRenderPass (TUIContext.swift:530-536).
- Existing isolation precedent — `RenderContext.isolatedForBackground()`
  (RenderContext+TUIContext.swift:49; used by AlertPresentationModifier.swift:94,
  ModalPresentationModifier.swift:60).
- Harness — Tests/TUIkitTests/Support/RuntimeCharacterizationHarness.swift;
  known-issue pattern — RuntimeCharacterizationTests.swift:227-253.
- Gate script — `./scripts/test-linux.sh` (repo root).
