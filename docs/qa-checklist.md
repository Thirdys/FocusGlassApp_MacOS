# FocusGlass QA Checklist

## Build and package

- Run `swift build`.
- Run `swift test`.
- Run `./Scripts/package-app.sh`.
- For release handoff, run `./Scripts/package-release.sh` and verify the zip
  plus `.sha256` appear under `build/releases/<version>/`.
- After code changes, check whether `docs/assistant-context.md`,
  `docs/architecture.md`, `docs/product-context.md`,
  `docs/design/design-source.md`, or `docs/qa-checklist.md` need updates.
- Launch `build/FocusGlass.app` for permission QA, because raw `swift run`
  cannot fully exercise app-bundle notification prompts.
- Verify the Dock/Finder icon reads as a glass focus timer, not a prohibition or
  generic settings control.
- Verify the first main-window launch shows a short theme-aware FocusGlass reveal
  and Reduce Motion shortens it to a low-motion fade.
- Verify `~/Library/Application Support/FocusGlass/workspace.json` and
  `settings.json` are created after first launch/save.

## First launch and permissions

- Fresh state starts without demo projects/tasks.
- First app-bundle launch refreshes permission statuses.
- Notification system prompt appears only if notifications are not determined
  and `hasSeenPermissionsOnboarding` is false.
- Clicking "Запросить уведомления" from RU UI either shows the native macOS
  prompt or a Russian explanation for why it cannot be shown.
- If macOS has already denied notifications, the app opens Notification
  Settings and records the denial reason in diagnostics.
- Relaunch does not repeatedly show the notification prompt.
- Permission rows do not show false missing states while status is unknown.
- Accessibility is shown as a status plus explicit request/open action; no
  system settings window opens automatically before the user clicks.
- Automation request triggers a probe and updates status after the prompt.
- Launch at Login shows current status and can be enabled/disabled, or opens
  Login Items when local bundle setup cannot register.
- Shortcuts hooks are presented as interactive Automation rows for FocusGlass
  Start, Pause, Resume, and End with access status, direct run actions, and
  visible success/failure feedback after checks and runs.
- Permission failures write JSONL diagnostics under
  `~/Library/Application Support/FocusGlass/Logs/diagnostics.jsonl` with
  created/expiry timestamps, subsystem code, details, and resolution hint.
- Data card shows the data folder, `workspace.json`, `settings.json`, and last
  save status.

## Strict mode rules

- Add an app rule from running applications.
- Add an app rule manually by bundle id.
- Add a site rule such as `youtube.com`.
- Add a wildcard site rule such as `*.reddit.com`.
- Change actions and enabled state for both app and site rules.
- Delete app and site rules.
- In normal mode while the timer is running, switch to a warn-rule app and
  verify FocusGlass returns to the main timer without hiding the app and shows a
  toast warning.
- In normal mode while the timer is running, switch to a hide-rule app and
  verify FocusGlass returns to the main timer, hides the app, and shows a toast
  warning.
- In fullscreen focus mode while the timer is running, switch to a warn-rule app
  and verify FocusGlass returns to the fullscreen timer without hiding the app.
- In fullscreen focus mode while the timer is running, switch to a hide-rule app
  and verify FocusGlass returns to the fullscreen timer and hides the app.
- In fullscreen focus mode while the timer is running, open a blocked site in a
  supported browser and verify the browser is hidden and FocusGlass returns to
  the timer.
- Verify the fullscreen warning uses localized text, for example
  "`youtube.com заблокирован. Возвращаю к таймеру.`" in RU.

## Projects and tasks

- Create a project from empty state.
- Select the active project from the dropdown in the active project card.
- Rename a project and verify existing tasks still appear under that project.
- Delete a project and verify its tasks/sessions become unassigned.
- Add a task from the focus screen.
- Edit task title, project, estimate, and done/undone state in the sheet.
- Verify estimate presets 5, 15, 25, 45, 60 and custom stepper minutes persist
  after relaunch.
- Relaunch `build/FocusGlass.app` after creating projects/tasks and verify they
  remain in `workspace.json`.

## Timer presets

- Select each quick mode chip from the working screen.
- Verify reset and skip are visually distinct; reset uses a counterclockwise
  arrow, skip uses a forward-end icon.
- Verify skip is disabled or muted for a single-segment preset.
- In Settings, edit a preset name, mode, segments, duration, phase, and
  `autoStartNext`.
- Verify editing Pomodoro does not change Countdown, Stopwatch, Flow, Timebox,
  or Intervals.
- Reset only Pomodoro and verify other edited presets remain edited.
- Relaunch and verify selected preset and edited presets persist.

## Settings and theme UX

- Verify Settings tabs use the glass segmented control, not stock segmented
  picker styling.
- Verify the selected Settings tab shows a concise section summary under the
  tab rail in RU and EN.
- Hover preset chips, Settings tabs, action buttons, permission actions, strict
  rule selects/add/delete controls, sidebar routes, and compact icon actions;
  the glass hover state should be visible and should follow the selected theme
  in macOS light and dark appearance.
- Hover and click project cards and sidebar route rows away from their text;
  highlighted surfaces should keep a full-surface pointer target.
- Verify checkbox toggles in preset segments and strict-mode rules use the same
  FocusGlass glass checkbox treatment in on/off states.
- Verify the main active project chooser uses the glass dropdown styling and
  theme-aware hover, not a stock SwiftUI menu.
- Verify language, appearance mode, preset mode, segment phase, and strict rule
  action use glass dropdowns.
- Verify segment duration and task estimate use glass steppers instead of stock
  steppers.
- Verify Settings text fields use glass styling instead of rounded-border
  stock controls.
- Verify long RU/EN values such as "Как в macOS", "Универсальный доступ", and
  long preset names remain readable and show helpful tooltips.
- Quickly switch between system/light/dark and theme profiles; UI should update
  with a smooth animated color transition while runtime icon, save, and custom
  app-icon persistence complete after their debounces.
- Change macOS light/dark while FocusGlass is set to "Как в macOS" and verify
  the app transitions smoothly rather than snapping instantly, and the runtime
  Dock icon updates with the resolved appearance.
- Quit immediately after selecting another theme or changing macOS appearance,
  relaunch the packaged app, and verify the last icon snapshot was not skipped
  by pending theme side effects.
- Drag several Theme Studio controls quickly and verify the final value is what
  persists after the debounce, without visible UI stalls during dragging.
- Check Appearance for the theme side-effect status/performance message.
- Confirm advanced Theme Studio is collapsed by default.

## Fullscreen focus

- Open Focus Mode from the main window and menu bar panel.
- Verify the focus window enters macOS fullscreen automatically.
- Verify the old shield icon is absent from the fullscreen top bar.
- While idle, paused, or completed, controls are visible.
- While running, controls hide without hover and appear in the top hover zone.
- Reset while running is available only through hover controls.
- Escape or close control exits focus mode.

## Analytics

- Complete a session assigned to a project and verify project analytics update.
- Rename that project and verify analytics still count the old session.
- Complete or migrate an unassigned session and verify it appears as
  "Unassigned"/"Без проекта", not as an empty label.

## Layout and localization

- Check wide layout at 1320 px and above.
- Check medium layout around 980-1319 px.
- Check compact layout below 980 px.
- Verify the main screen has project selection on the left of the timer and
  project tasks on the right.
- Verify the right context rail does not duplicate the active project card.
- Switch RU and EN and verify buttons, chips, sheets, empty states, Settings,
  and fullscreen controls do not clip or overlap.
- Verify notification titles/bodies and permission error text follow the
  selected RU/EN language.
- Switch Settings tabs: General, Timers, Strict Mode, Access, Appearance.
- Switch appearance between system/light/dark and verify the app follows macOS
  when set to system while keeping the selected accent theme.
- Verify the menu bar panel reads as a compact HUD, not a large square card.
