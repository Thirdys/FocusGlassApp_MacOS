# FocusGlass Product Context

## Purpose

FocusGlass is a native macOS focus timer for real daily work. It combines a
menu bar timer, a planning cockpit, editable focus tasks, project-level
analytics, fullscreen focus, and soft strict-mode setup.

The product should feel like an operational tool: quiet, dense enough for
repeat use, fast to scan, and useful immediately after launch.

## UX principles

- Open into the working cockpit, not marketing or onboarding.
- Keep the active session path short: pick mode, choose project, optionally
  select a task, start. Longer context belongs in project notes.
- Store relationships with stable IDs. Renaming a project must not break tasks
  or analytics.
- Use sheets for editing projects and tasks so dense cards remain readable.
- Keep quick choices on the main screen and deeper configuration in Settings.
- Ask for permissions explicitly and accurately. Notifications can use the
  system prompt once; Accessibility, Automation, and Login Items stay visible
  setup actions with clear statuses.
- Fullscreen focus must remove nonessential chrome. Running sessions hide
  controls until hover but always keep Escape/close available. Strict
  protection runs for active timer sessions in both the normal and fullscreen
  flows; fullscreen only changes presentation and return behavior.
- RU and EN are first-class UI states and must fit in compact, medium, and wide
  layouts.

## Current decisions

- Persistence is split JSON in Application Support while SwiftData is deferred
  until full Xcode is available: `workspace.json` for user work data and
  `settings.json` for preferences.
- Schema v6 preserves legacy `state.json` migration and blocks autosave if
  workspace JSON is corrupt, so projects/tasks are not overwritten by defaults.
- `FocusTask.projectID` and `FocusSessionRecord.projectID` are the source of
  truth. Legacy `projectName` is kept only for migration/readability.
- Built-in timer presets are editable in place and can be reset one preset at a
  time.
- The main focus screen keeps only quick mode chips; Settings contains the
  preset editor.
- Settings is a calm tabbed setup surface: General, Timers, Strict Mode, Access,
  and Appearance. Advanced theme editing is collapsed by default.
- The app follows macOS light/dark by default while preserving the selected
  theme; every profile has explicit Light/Dark palettes and the user can pin
  light or dark mode.
- Project context is stored as project-scoped notes. Legacy global `intention`
  is migrated once and is not shown as a standalone cockpit field.
- Completed sessions open an outcome with planned vs honest time, distractions,
  captured task context, and complete/continue/start-next actions.
- Strict rule matches persist in session-linked distraction history and feed
  the current analytics surfaces.
- The Menu Bar HUD is a lifecycle-managed nonactivating `NSPanel`, not a
  transient popover, so it can appear over other apps and fullscreen Spaces.
- Figma is optional. `docs/design` and the SwiftUI implementation are the
  current design source.
- Project documentation is kept current with code changes. Future assistant
  sessions should start from `docs/assistant-context.md` and then inspect the
  specific implementation files relevant to the task.

## In scope

- Native macOS SwiftUI app, menu bar extra, main window, Settings, and
  fullscreen focus window.
- Local-first projects, tasks, recent sessions, analytics, themes, timer
  presets, and strict-mode rules.
- RU/EN localization.
- Notification permission flow, Accessibility setup, Automation probe, Login
  Items setup, and Shortcuts hook checklist.
- App and site distraction rules for active normal/fullscreen focus sessions.
- Package script for local `.app` bundle testing.

## Out of scope for now

- Cloud sync, accounts, teams, billing, and cross-device state.
- System-wide site blocking through Network Extension or hosts-file mutation.
- Full SwiftData migration until a full Xcode toolchain is available.
- Figma dependency for day-to-day development.
- Complex calendar/task-manager integrations.

## Documentation upkeep

Documentation is part of the product quality bar. Any change that affects user
data, settings, macOS permissions, strict mode, theme behavior, icon behavior,
main/menu/fullscreen UI, build packaging, tests, or QA expectations must update
the matching file under `docs/` before the task is considered complete.

Use `docs/assistant-context.md` as the durable memory layer for implementation
decisions and known caveats. Keep it concise, factual, and synchronized with
the code.
