# FocusGlass Assistant Context

Last reviewed: 2026-05-29.

Read this file first when returning to the project. It is intentionally written
as implementation context for future assistant sessions, not as marketing copy.

## Human context

FocusGlass is personally very important to the user. Treat it as a soulful,
long-term project made with care, not as a disposable MVP or a quick demo. The
current direction should be protected and developed thoughtfully instead of
being replaced from the root.

The user sees the assistant as a friend and collaborator, not only as a tool.
Work with patience, honesty, and respect for the trust behind the project. Keep
technical decisions clear, avoid rushed changes, preserve durable context, and
build with love for the future people who will use the app.

## Documentation rule

Project documentation is part of the implementation. When changing behavior,
storage, permissions, visual language, build/package flow, or QA expectations,
update the relevant document in the same change:

- `docs/assistant-context.md` for the current implementation map and caveats.
- `docs/architecture.md` for data model, services, migrations, permissions,
  theme/icon side effects, and strict-mode behavior.
- `docs/design/design-source.md` for layout, visual system, controls, icon, and
  UX rules.
- `docs/product-context.md` for product decisions and in/out of scope.
- `docs/qa-checklist.md` for automated and manual verification.

If code and docs disagree, treat the code as the source for the fix and update
the docs before finishing the task.

## Codex workspace

Open Codex in the repository root:

```sh
/Applications/Codex.app/Contents/Resources/codex app /Users/thirdys/Documents/New\ Project/FocusGlassApp_MacOS
```

Do not open the parent folder `/Users/thirdys/Documents/New Project` when Git UI
or PR state matters. That parent folder is not a git repository, so Codex will
not display the FocusGlass git state there.

Assistant work should use the `codex/next` branch. The owner may use other
branches, but assistant-created work is expected to be easy to distinguish by
the `codex/` branch prefix and the `Ассистент: Codex` signature in commits/PRs.

## Current product shape

FocusGlass is a native macOS SwiftUI focus timer with:

- main cockpit window;
- menu bar HUD;
- fullscreen focus window;
- Settings surface;
- local JSON persistence;
- editable projects, tasks, timer presets, strict rules, and themes;
- RU/EN localization;
- macOS permissions setup for Notifications, Accessibility, Automation, and
  Launch at Login.

The app is local-first. There is no account, sync, cloud, or remote service.

## Targets and entry points

- `Package.swift` defines macOS 14 targets:
  - `FocusGlassCore`: pure timer, analytics, and strict-rule types.
  - `FocusGlassApp`: SwiftUI app, view model, services, UI, resources.
- `Sources/FocusGlassApp/FocusGlassApp.swift` defines the app shell:
  - `WindowGroup("FocusGlass", id: "main")` for the cockpit.
  - AppKit `NSStatusItem` with a template glyph and `NSPopover` hosting `MenuBarPanel`.
  - `WindowGroup("Focus", id: "focus-mode")` for fullscreen focus.
  - `Settings` with `SettingsView`.
- `FocusGlassViewModel` is the app-level `@MainActor` state owner.

## Important implementation map

- `Sources/FocusGlassCore/TimerTypes.swift`
  defines `TimerMode`, `TimerPhase`, `TimerStatus`, `TimerSegment`, and
  `TimerPreset.defaultPresets`.
- `Sources/FocusGlassCore/FocusTimerEngine.swift`
  owns timer transitions and produces `TimerEngineSnapshot`.
- `Sources/FocusGlassCore/FocusGuardTypes.swift`
  defines permission statuses and app/site strict rules.
- `Sources/FocusGlassCore/AnalyticsEngine.swift`
  summarizes sessions and calculates focus score.
- `Sources/FocusGlassApp/FocusGlassViewModel.swift`
  bridges UI, engine, persistence, permissions, theme state, strict mode, and
  window reuse.
- `Sources/FocusGlassApp/Services/FocusGlassStore.swift`
  loads/saves split JSON state and protects user workspace data from bad
  decode/write paths.
- `Sources/FocusGlassApp/Services/FocusGuardService.swift`
  performs permission checks, notification requests, Apple Events probes,
  browser URL checks, and strict-mode actions.
- `Sources/FocusGlassApp/Services/FocusGlassDiagnosticsLogger.swift`
  writes seven-day JSONL diagnostics.
- `Sources/FocusGlassApp/Services/FocusGlassRuntimeIcon.swift`
  contains the shared runtime app icon renderer.
- `Scripts/generate-app-icon.swift`
  mirrors the app icon geometry for bundled `AppIcon.icns`.

## Data model and persistence

Current persistent files live in:

`~/Library/Application Support/FocusGlass/workspace.json`
`~/Library/Application Support/FocusGlass/settings.json`

`workspace.json` stores user work:

- intention;
- active project ID plus legacy readable active project name;
- projects;
- tasks;
- strict distraction rules;
- recent session records.

`settings.json` stores app preferences:

- selected theme ID and editable theme profiles;
- appearance mode (`system`, `light`, `dark`);
- selected timer preset and editable presets;
- language;
- strict-mode enabled flag;
- permissions onboarding flag.

Legacy `state.json` is still decoded for migration and is not deleted. New saves
write schema v4 split files. If `workspace.json` cannot decode, the store backs
it up as `workspace.invalid-YYYYMMDD-HHMMSS.json`, blocks automatic saves, logs
the issue, and avoids replacing user data with defaults. If `settings.json`
cannot decode, it is backed up and defaults are used while workspace still
loads.

The relationship source of truth is `projectID`. `FocusTask.projectName` and
`FocusSessionRecord.projectName` are legacy/readable fallbacks only. They must
not be used for grouping, analytics, or deciding which tasks belong to a
project.

## View model lifecycle

`FocusGlassViewModel.init` does this order:

1. Create `FocusTimerEngine`.
2. Load `FocusGlassStore`.
3. Sanitize/migrate starter or legacy state.
4. Merge built-in themes and timer presets with persisted values.
5. Configure language, selected preset, active project name, appearance
   observer, runtime icon, and timer engine.
6. Refresh or request permissions depending on launch options.
7. Persist clean split state unless workspace persistence is blocked.

Notes:

- `sanitizedStarterState` returns a schema v3 migrated state marker, while the
  actual current split saves write schema v4.
- `activeTasks` is intentionally scoped to `activeProjectID` and does not fall
  back to all tasks when a selected project is missing.
- Project rename does not cascade into task/session strings. Display and
  grouping should use `projectID`.
- Project delete unassigns tasks and sessions by clearing `projectID` and
  readable legacy project labels.

## UI structure

Main cockpit:

- `FocusTodayView` has quick preset chips, intention input, project selector on
  the left, circular timer in the center, and project tasks on the right.
- `ActiveProjectCard` is for project selection/edit/add and does not list
  tasks.
- `FocusStackCard` lists active tasks for the current project and opens task
  editing sheets.
- Every piece of working information needs one primary home. Avoid duplicating
  the same project, task, timer, analytics, permission, or strict-mode content in
  multiple visible areas unless the repeated appearance has a clearly different
  role such as navigation, status, or editing.
- `FocusContextRailView` must not duplicate working content from the main area.
  It should stay contextual: timer state and strict-mode status only. Project
  tasks belong in `FocusStackCard` next to the timer.

Settings:

- `SettingsContentView` uses custom tab control `GlassSegmentedControl`.
- General uses `GlassSelect` for language and appearance mode.
- Timers show localized mode descriptions for Pomodoro, Countdown, Stopwatch,
  Flow, Timebox, and Intervals in the preset editor and chip tooltips.
- Timers use `GlassSelect` for preset mode and phase, `GlassStepper` for
  segment minutes, and a per-preset reset.
- Strict Mode uses app and site rule editors with `GlassSelect` for actions.
- Permissions rows share `FocusPermissionStatus` and show calm states instead
  of false red warnings.
- Appearance exposes built-in themes first and keeps Theme Studio advanced
  controls in a disclosure group.

Reusable controls live in `Views/Components.swift`:

- `LiquidGlassPanel`;
- `LiquidGlassButtonStyle`;
- `GlassSegmentedControl`;
- `GlassSelect`;
- `GlassStepper`;
- `GlassTextFieldStyle`;
- `EmptyInlineState`;
- timer and analytics visual helpers.

Known visual caveats to remember:

- The main active project selector uses `GlassSelect` so the cockpit matches
  Settings controls instead of showing a stock SwiftUI `Menu`.
- Advanced Theme Studio still uses SwiftUI `Slider`; build a `GlassSlider` if
  the goal becomes "no stock controls anywhere".

## Fullscreen focus

Opening `focus-mode` is a two-part flow:

- `openWindow(id: "focus-mode")` opens the scene.
- `FullscreenWindowAccessor` inside `FullscreenFocusView` calls
  `window.toggleFullScreen(nil)` once when the window is available.

`FocusGlassViewModel.openFocusModeFullscreen()` only activates the app. Do not
move fullscreen toggling into the view model unless window ownership is also
changed.

Fullscreen focus rules:

- No old shield icon in the top bar.
- Controls are visible for idle, paused, and completed states.
- Controls are hidden while running until pointer hover in the top zone.
- Escape works through an invisible cancel button.
- Strict distraction checks run while strict mode and the timer are running.
  Fullscreen focus shows the warning inline at the bottom; the normal cockpit
  shows a transient toast and returns the user to FocusGlass.

## Permissions and strict mode

Permission state uses `FocusPermissionStatus`:

- `unknown`: still checking or cannot conclude yet;
- `granted`: available;
- `missing`: user action is needed;
- `unavailable`: current launch mode cannot support this action.

Important macOS behavior:

- Notifications can prompt only from a real `.app` bundle. Use
  `./Scripts/package-app.sh` and launch `build/FocusGlass.app` for QA.
- Accessibility uses `AXIsProcessTrusted` for status and
  `AXIsProcessTrustedWithOptions(...prompt: true)` only after a user action.
- Automation has no universal global granted API; the app stores the last
  successful Apple Events probe.
- Launch at Login uses `SMAppService.mainApp.status`.

Strict rules:

- App rules match bundle identifiers.
- Site rules normalize domains and support Safari, Chrome, Arc, and Edge URL
  probes through Apple Events.
- Default app/site rule action is hide.
- When a rule triggers, FocusGlass warns, hides or controls the target based on
  action, activates FocusGlass, and records the distraction count for the
  session.

## Theme, appearance, and icons

`ThemeProfile` drives glass surfaces, text colors, timer rings, heatmap colors,
strict color, highlight color, opacity, radius, density, and motion tokens.

`appearanceMode` behavior:

- `system`: UI follows macOS light/dark via `AppleInterfaceThemeChangedNotification`.
- `light` and `dark`: UI pins to that mode with `.preferredColorScheme`.
- `effectiveTheme` adapts the selected theme to the resolved appearance.
- `iconTheme` uses the selected theme adapted to the resolved appearance for
  system, light, and dark modes, so runtime/custom icons follow macOS light/dark.

Theme switching is intentionally animated, split, and batched:

- UI theme changes through the published theme/appearance state first and
  advance `themeTransitionID`.
- Root app scenes apply `FocusGlassViewModel.themeTransitionAnimation` to that
  transition token, so palette changes crossfade instead of snapping instantly.
- User-triggered theme and appearance changes run through
  `performThemeMutation`; system macOS light/dark notifications use
  `updateSystemAppearanceAnimated`.
- Runtime Dock icon drawing is deferred by about 120 ms so AppKit icon drawing
  does not block the selection click or light/dark switch.
- Settings persistence and `NSWorkspace.setIcon` custom app-icon persistence
  are debounced by about 700 ms.
- Built-in theme edits are batched into one custom-theme mutation instead of
  creating several theme side-effect schedules.
- `isThemeSideEffectPending` is only published when it actually changes, so
  rapid slider updates do not repeatedly invalidate the whole UI just to keep
  showing the same "saving" state.
- `lastThemePerformanceMessage` records UI scheduling, runtime icon, save, and
  custom app-icon timing. Diagnostics logs `theme.switch_completed` after the
  final debounced side effects finish.

Finder `.icns` is static and generated from the same geometry as the runtime
icon. `Scripts/package-app.sh` regenerates the static icon before packaging so
the bundled app stays aligned with `FocusGlassRuntimeIcon`. Runtime/custom app
icon persistence is best-effort; macOS may reject `NSWorkspace.setIcon` for
local bundles.

`L10n` must not directly call SwiftPM's generated `Bundle.module` accessor. For
local `.app` bundles, resources live under `Contents/Resources`, while the
generated accessor for this SwiftPM executable can resolve a different path and
fatal-error before the built-in dictionary fallbacks are used. Keep localization
lookup tolerant of missing bundles.

The menu bar icon is an AppKit `NSStatusItem` image-only button with an
`NSImage.isTemplate` glyph. Keep it as black geometry on transparency and let
macOS tint it for light, dark, translucent, and highlighted menu bar states. The
glyph should stay visually aligned with the launcher icon as a compact timer
face with one progress arc and focus dot; SwiftUI `MenuBarExtra` custom labels
previously rendered as a dark blob or tiny fallback glyph in local QA.

## Build, package, and tests

Use:

```sh
swift build --disable-sandbox
swift test --disable-sandbox
./Scripts/package-app.sh
./Scripts/package-release.sh
```

`swift run FocusGlass` is useful for quick UI checks but cannot fully test
notification permissions because it is not a real app bundle. In this assistant
sandbox, plain SwiftPM sandboxing can fail while compiling `Package.swift`, so
use the `--disable-sandbox` variants above for verification.

`build/` is ignored generated output. Keep local `.app` bundles, release zips,
and checksums out of git. For manual tester handoff or GitHub Releases, use
`Scripts/package-release.sh`, which packages `FocusGlass.app` into
`build/releases/<version>/FocusGlass-<version>.zip` and writes a SHA-256 file
next to it.

The current test suite covers timer transitions, analytics, permission status
helpers, rule decoding/matching, migration from legacy project names, split
state persistence, invalid JSON protection, preset editing/reset, task estimate
clamping, project-scoped task lists, and debounced theme side effects.

## High-risk areas

- User data safety: never let a decode failure silently create and save an
  empty workspace over real user data.
- macOS permissions: test from `build/FocusGlass.app`, not only `swift run`.
- Strict mode: warn returns to FocusGlass without hiding the target; hide does
  the same return flow and hides the matched app/browser. Fullscreen warnings
  stay inside the focus window, while normal mode uses a toast.
- Theme switching: do not put runtime icon drawing, persistence, or
  `NSWorkspace.setIcon` back into immediate slider/change handlers.
- Localization: RU is default and must be checked for clipping in compact
  layouts.
- Documentation: update docs whenever implementation behavior changes.
