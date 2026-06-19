# FocusGlass Architecture

## Targets

- `FocusGlassCore`: pure Swift timer modes, state transitions, presets, focus
  scoring, analytics summaries, and distraction rule types.
- `FocusGlassApp`: native SwiftUI macOS app with menu bar, cockpit window,
  fullscreen focus mode, settings, local storage, notifications, accessibility
  routing, and Shortcuts hooks.

## Implementation map

- `FocusGlassApp.swift` owns the scene structure: main `WindowGroup`,
  fullscreen focus `WindowGroup`, Settings, and the AppKit `NSStatusItem` that
  hosts the SwiftUI menu bar panel in an `NSPopover`.
- `FocusGlassViewModel` is the app state coordinator. It owns timer selection,
  projects, tasks, recent sessions, strict rules, permissions service, storage
  status, theme selection, runtime icons, and window reuse.
- `FocusTimerEngine` is the pure timer state machine. UI code should interact
  through view-model snapshots, not by duplicating timer math.
- `FocusGlassStore` owns split JSON persistence and invalid-file protection.
- `FocusGuardService` owns macOS permission checks, notifications, Apple Events
  probes, browser URL lookup, and strict-mode actions.
- `FocusGlassDiagnosticsLogger` writes short-lived structured diagnostics.
- `FocusGlassRuntimeIcon` and `Scripts/generate-app-icon.swift` share one icon
  geometry: a readable glass timer face, one focus-progress ring, hands, focus
  point, and highlight.

## Persistence

The current working build stores app state as JSON in Application Support:

`~/Library/Application Support/FocusGlass/workspace.json`
`~/Library/Application Support/FocusGlass/settings.json`

For local packaged-app QA, `FocusGlassStoragePaths` also honors the
`FOCUSGLASS_DATA_DIR` environment variable. When it is set, `workspace.json`,
`settings.json`, legacy `state.json`, and diagnostics are read and written under
that directory instead of the real Application Support folder. This is a
developer/test override only; normal app launches should leave it unset.

This keeps the app local-first and testable with the current Command Line Tools
installation. SwiftData remains the intended persistence layer after full Xcode
is installed, because this machine currently cannot load `SwiftDataMacros` from
Command Line Tools.

SwiftData migration target:

- `Project`
- `FocusTask`
- `FocusSession`
- `TimerPreset`
- `ThemePreset`
- `DistractionRule`
- `FocusEvent`
- `DailyInsight`

### JSON schema v4

User data and app preferences are deliberately split so a settings decode issue
does not erase projects/tasks:

- `FocusGlassWorkspaceState` writes `workspace.json`: `intention`,
  `activeProjectID`, `activeTaskID`, legacy readable `activeProject`,
  `projects`, `tasks`, `distractionRules`, and `recentSessions`.
- `FocusGlassSettingsState` writes `settings.json`: `selectedThemeID`,
  `themeProfiles`, `appearanceMode`, `selectedPresetID`, `timerPresets`,
  `language`, `strictModeEnabled`, `strictModeEnforcesDuringBreaks`, and
  `hasSeenPermissionsOnboarding`.
- `FocusGlassPersistedState` remains as a legacy combined decode type for
  migration from `state.json`.

The state is local-only and currently includes:

- `selectedThemeID`, `themeProfiles`, `appearanceMode`: editable Theme Studio
  profiles plus system/light/dark appearance preference.
- `selectedPresetID`, `timerPresets`: editable timer modes, including built-in
  presets that can be customized in place.
- `language`, `strictModeEnabled`, `strictModeEnforcesDuringBreaks`,
  `hasSeenPermissionsOnboarding`: app-level preferences, strict-mode break
  behavior, and first-launch permission onboarding state.
- `intention`, `activeProjectID`, `activeTaskID`, `activeProject`: current
  focus context. `activeProject` is retained only as a legacy/readable string.
- `projects`: `FocusProject` values with stable `id`, `name`, `detail`, and
  `accentName`.
- `tasks`: `FocusTask` values keyed to projects by optional `projectID`.
  `timingMode` is `.timed` or `.checklist`; legacy tasks without this field
  decode as `.timed`. `projectName` is decoded only for legacy migration and is
  not the source of truth after v3.
- `recentSessions`: `FocusSessionRecord` values keyed to projects only by
  optional `projectID` and optionally to a task by `taskID`/`taskTitle`, with
  `projectName` retained only as a legacy/readable string.
- `distractionRules`: strict focus rule specs.

### Legacy migration and v4 split

On load, `FocusGlassViewModel.sanitizedStarterState` migrates persisted state
before the app starts writing current split files:

- Tasks and sessions with missing `projectID` are matched to a project by their
  legacy `projectName`.
- If no matching project exists, the item remains unassigned with
  `projectID == nil` and an empty legacy project label.
- `activeProjectID` is restored only if it still points at an existing project;
  otherwise the legacy `activeProject` name is used, then the first project, and
  finally `nil`.
- `activeTaskID` is restored only if it still points at an unfinished task in
  the active project scope. Invalid task selections are cleared instead of
  silently selecting a different task.
- Legacy starter/demo projects, tasks, intentions, and placeholder projects
  from pre-schema builds are removed so an empty user state stays empty.
- `sanitizedStarterState` returns a schema v4 migrated state marker for legacy
  cleanup, then new saves write split `schemaVersion: 4` files. Legacy
  `state.json` is kept in place and not deleted.
- If `workspace.json` cannot decode, FocusGlass copies it to
  `workspace.invalid-YYYYMMDD-HHMMSS.json`, blocks automatic saves, and logs the
  issue so user projects/tasks are not overwritten by a clean empty state.
- If `settings.json` cannot decode, FocusGlass backs it up, restores default
  settings, and keeps loading the workspace.

Project rename does not cascade through task strings. Tasks and sessions stay
associated through stable `projectID`, so analytics and task grouping survive
renames. Sessions with `projectID == nil` are displayed as unassigned even if a
legacy readable `projectName` is still present.

### Task timing

Tasks support two timing modes:

- `.timed`: keeps `estimate` and `completed` progress. When a preset completes,
  the view model adds the session's honest focus time to the task captured at
  timer start, clamped to the task estimate.
- `.checklist`: keeps the same fields for persistence compatibility, but the UI
  hides estimate/progress and completed session time is not applied.

Starting a timer captures the currently selected `activeTaskID` into an internal
session task ID. Later task selection changes do not redirect the current
session's honest focus time.

### Timer presets

`TimerPreset.defaultPresets` defines the built-in defaults, but persisted
`timerPresets` are the runtime source of truth. Settings can edit a preset name,
mode, segment list, segment duration in minutes, phase, and `autoStartNext`.
`resetPresetToDefault` restores only the selected built-in preset to its
default definition.

### Theme and icon side effects

Theme changes deliberately animate UI updates, separate heavier side effects,
and batch multi-step theme mutations:

- `selectedThemeID`, `themeProfiles`, and `appearanceMode` call
  `handleThemePreferenceChanged`.
- The UI updates first through the published theme/appearance state.
- `themeTransitionID` advances inside `FocusGlassViewModel.themeTransitionAnimation`;
  root app scenes animate against that token so palette changes crossfade
  instead of snapping.
- macOS system appearance notifications use `updateSystemAppearanceAnimated`
  when `appearanceMode == .system`; the icon update path is scheduled again so
  the open-app Dock icon and the last persisted custom icon snapshot follow the
  new resolved appearance.
- Runtime Dock icon drawing is deferred by about 120 ms with
  `scheduleRuntimeIconUpdate`. `iconTheme` uses the selected theme adapted to the
  resolved light/dark appearance, including system appearance changes.
- Settings persistence and `NSWorkspace.setIcon` custom app-icon persistence
  are debounced by about 700 ms in `scheduleThemeSideEffects`.
- App termination flushes pending theme side effects before the process exits,
  so the last chosen icon snapshot is not lost only because a debounce was
  still waiting.
- `Scripts/package-app.sh` regenerates the static `.icns` from
  `Scripts/generate-app-icon.swift` before copying it into the app bundle.
- The packaged `.icns` remains the readable fallback for a closed app. Runtime
  theme colors are restored for the running Dock icon immediately after launch;
  a fully terminated process cannot react to later user-theme edits by itself.
- The main window adds a short theme-aware launch overlay before exposing the
  normal shell. It respects macOS Reduce Motion by using a shorter fade path.
- `L10n` uses a safe resource-bundle lookup instead of directly touching
  SwiftPM's generated `Bundle.module`, because local `.app` packaging keeps
  resources in `Contents/Resources` while the generated accessor for a SwiftPM
  executable can otherwise fatal-error before dictionary fallbacks are used.
- Built-in Theme Studio edits are applied through `performThemeMutation`, so
  duplicating a built-in theme and applying the actual edit produce one
  side-effect schedule instead of several.
- Theme Studio preview explicitly visualizes advanced color tokens: background
  top/mid/bottom as a window gradient, text/muted text on a live sample, and
  surface/elevated colors as chips.
- Built-in themes can be reset to defaults. Custom themes have a separate
  delete action and are never removed through reset.
- `lastThemePerformanceMessage` records UI scheduling, runtime icon, save, and
  custom app-icon durations.
- Diagnostics logs `theme.switch_completed` after the final debounced side
  effects finish.

Do not reintroduce synchronous custom icon persistence into every Theme Studio
field/slider update, and do not bypass the animated theme mutation helpers for
user-facing theme/appearance changes; both make light/dark or theme switching
feel abrupt or stuck.

## Strict Focus

The first implementation uses a layered strict focus model:

- Permission states use `unknown`, `granted`, `missing`, and `unavailable`
  rather than raw booleans, so the UI does not show false negatives while async
  macOS checks are still running or when the app is launched outside a bundle.
- Notifications go through `UNUserNotificationCenter`; the prompt is only
  requested from a real `.app` bundle and is guarded by
  `hasSeenPermissionsOnboarding`.
- Accessibility uses `AXIsProcessTrusted` for status and
  `AXIsProcessTrustedWithOptions` plus the Privacy deep-link for explicit user
  setup.
- Automation uses Apple Events probes for System Events/browser integration.
  macOS does not expose a universal permission status, so FocusGlass stores the
  most recent successful probe.
- Launch at Login uses `SMAppService.mainApp.status`; local bundle failures send
  the user to Login Items settings.
- Shortcuts hooks named `FocusGlass Start`, `FocusGlass Pause`,
  `FocusGlass Resume`, and `FocusGlass End`.
- Distraction rules can target apps or sites. App rules match bundle IDs. Site
  rules match active browser URLs in Safari, Chrome, Arc, and Edge through
  browser-level Apple Events, not a system network blocker.
- Strict rules are evaluated while strict mode is enabled and the timer is
  running. By default, evaluation is limited to focus segments; the persisted
  `strictModeEnforcesDuringBreaks` setting lets users opt into enforcement
  during break segments. Warn actions leave the target app open, return the user
  to FocusGlass, and show either the fullscreen warning or a normal-mode toast.
  Hide actions use the same return flow and hide the matched app/browser.
- The `pauseSession` strict action pauses the timer engine, stops the scheduled
  tick, syncs the engine snapshot, runs Shortcut `FocusGlass Pause`, and then
  returns the user to FocusGlass.

The focus window fullscreen transition is implemented by
`FullscreenWindowAccessor` inside `FullscreenFocusView`. The view model method
`openFocusModeFullscreen` only activates the application after the window is
opened.

When launched with `swift run`, FocusGlass is a raw SwiftPM executable and
macOS does not provide an app bundle proxy for UserNotifications. The app
therefore disables notification permission checks in that mode. Use
`Scripts/package-app.sh` and launch `build/FocusGlass.app` to test notification
permissions as a real app bundle.

## Diagnostics

FocusGlass writes local diagnostic logs for permission and notification
failures to:

`~/Library/Application Support/FocusGlass/Logs/diagnostics.jsonl`

Each line is a JSON object with `createdAt`, `expiresAt`, `level`,
`subsystem`, `code`, human-readable `message`, structured `details`,
`resolutionHint`, and app/build version fields. Entries are retained for seven
days and pruned on write/read. The intent is to make failures understandable to
both a user and an assistant reading logs later: old entries keep exact timing
and expiry metadata, and each entry includes a concrete hint so a previously
fixed issue is not mistaken for a current unexplained failure.

## Design Source

Figma is optional. The repo-local design source is `docs/design`, backed by the
generated concept screens and SwiftUI tokens. If Figma edit access becomes
available, the same screens should be moved into Figma without changing the app
information architecture.
