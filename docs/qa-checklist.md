# FocusGlass QA Checklist

## Build and package

- Run `swift build`.
- Run `swift test`.
- Run `./Scripts/package-app.sh`.
- For active dev-loop verification, prefer
  `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`;
  the script reuses `./Scripts/package-app.sh`, relaunches the real
  `build/FocusGlass.app`, forwards `FOCUSGLASS_DATA_DIR` as a launch argument,
  and can also stream `--logs` or `--telemetry`.
- Before tester handoff, check that `VERSION`, public tag, zip name, and tester
  branch name describe the same visible version, for example `0.0.2` and
  `v0.0.2`.
- For release handoff, run `./Scripts/package-release.sh` and verify the zip
  plus `.sha256` appear under `build/releases/<version>/`.
- In the main window, verify the bottom-right badge shows the app version and
  build number. It should not appear in the menu bar panel or fullscreen focus
  mode.
- After code changes, check whether `docs/assistant-context.md`,
  `docs/architecture.md`, `docs/product-context.md`,
  `docs/design/design-source.md`, or `docs/qa-checklist.md` need updates.
- Launch `build/FocusGlass.app` for permission QA, because raw `swift run`
  cannot fully exercise app-bundle notification prompts.
- For destructive packaged-app QA, point the app at a temporary data folder with
  `FOCUSGLASS_DATA_DIR` first, then unset it after the run, so real
  `~/Library/Application Support/FocusGlass` data and diagnostics are not
  touched.
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
  created/expiry timestamps, subsystem code, details, and resolution hint. When
  `FOCUSGLASS_DATA_DIR` is set, diagnostics move to
  `$FOCUSGLASS_DATA_DIR/Logs/diagnostics.jsonl`.
- Data card shows the data folder, `workspace.json`, `settings.json`, and last
  save status.

## Strict mode rules

- From the cockpit Strict Mode summary, click the manage action and verify
  Settings opens directly on the Strict Mode tab.
- Verify the cockpit blocked-app count matches the number of enabled app rules
  in Settings. Site rules must be reported separately and must not inflate the
  app count.
- Add an app rule from running applications.
- Add an app rule manually by bundle id.
- Add a site rule such as `youtube.com`.
- Add a wildcard site rule such as `*.reddit.com`.
- Change actions and enabled state for both app and site rules.
- Delete app and site rules.
- Verify strict rules do not fire during break segments by default.
- Enable `Строгий режим во время перерывов` and verify the same rule can fire
  during a break segment.
- Set a rule action to `Поставить на паузу`, trigger it while the timer is
  running, and verify the timer becomes paused and no longer ticks down.
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
- For a deterministic browser-rule smoke test without an external network
  dependency, serve a local page on `127.0.0.1`, add an enabled site rule for
  `127.0.0.1`, open the page in Safari, and verify the real Automation URL
  probe applies the selected action and records the event.
- Verify the fullscreen warning uses localized text, for example
  "`youtube.com заблокирован. Возвращаю к таймеру.`" in RU.
- Select `quitAfterOptIn` and verify FocusGlass shows a destructive
  confirmation before saving the opt-in. Cancel it and verify the rule keeps
  its previous safe action.
- Load or construct a legacy `quitAfterOptIn` rule without the persisted opt-in
  and verify it falls back to `hide` instead of terminating the target app.
- Trigger rules during an active session and verify Strict Mode history records
  the target, timestamp, rule/action, session, project, task when present, and
  timer mode.
- Relaunch with the same `FOCUSGLASS_DATA_DIR` and verify distraction history
  persists. Use the clear action and verify the history becomes empty.

## Projects and tasks

- Create a project from empty state.
- Select the active project from the cockpit project dropdown.
- Verify the wide cockpit layout keeps project context on the left, the timer in
  the center, and active/project tasks on the right.
- Verify the old top-level intention field is not visible in cockpit, menu bar,
  or fullscreen focus.
- Add project notes from the cockpit disclosure, relaunch with the same
  `FOCUSGLASS_DATA_DIR`, and verify notes persist under the selected project.
- Open the project editor sheet and verify the notes field can be edited there
  too.
- Rename a project and verify existing tasks still appear under that project.
- Delete a project and verify its tasks/sessions become unassigned.
- Add a task from the focus screen.
- Add a task while `Без проекта` is selected and verify it appears under
  `Без проекта` without creating a new project.
- Create more than three unfinished tasks in one project and verify the active
  task list scrolls instead of truncating.
- Verify the selected active task appears as a featured card with full title,
  progress/status, and a compact edit affordance.
- Verify regular task rows use one wide visual card, allow 2-3 title lines, and
  do not waste width on a separate permanent edit column.
- Select an active task for the next timer session, start the timer, switch the
  selection, complete the timer, and verify time was applied to the task
  selected at start.
- Edit task title, project, estimate, and done/undone state in the sheet.
- Switch a task between `С временем` and `Обычная`; timed tasks should show
  estimate/progress, checklist tasks should not receive session progress.
- Verify estimate presets 5, 15, 25, 45, 60 and custom stepper minutes persist
  after relaunch.
- Verify time steppers snap correctly: `1 -> 5 -> 10`, `6 -> 10`, `5 -> 1`,
  and `0 -> 5` where zero is allowed.
- Enter minutes manually from the keyboard in task estimate and timer segment
  duration fields. In Settings -> Timers, verify a Flow segment such as
  `Разогрев` accepts an exact typed value, not only plus/minus steps.
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
- Verify project/task edit buttons respond when clicking the full 44x44 hover
  area around the pencil icon.
- Verify Settings text fields use glass styling instead of rounded-border
  stock controls.
- Verify long RU/EN values such as "Как в macOS", "Универсальный доступ", and
  long preset names remain readable and show helpful tooltips.
- Quickly switch between system/light/dark and theme profiles; UI should update
  with a smooth animated color transition while runtime icon, save, and custom
  app-icon persistence complete after their debounces.
- When running the app from Documents, Desktop, or Downloads, changing Theme
  Studio values must not show a macOS file-access prompt; the runtime Dock icon
  may update only until app quit in those protected locations.
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
- Expand advanced Theme Studio and verify background top/mid/bottom, surface,
  elevated surface, text, and muted text can be changed through color pickers,
  not manual hex typing, and changes are visible in the single live preview.
- Duplicate or import a custom theme and verify `Удалить тему` appears only for
  that custom theme. Verify built-in themes show `Сбросить`, not delete.

## Fullscreen focus

- Open Focus Mode from the main window and menu bar panel.
- Verify the focus window enters macOS fullscreen automatically.
- Verify the old shield icon is absent from the fullscreen top bar.
- While idle, paused, or completed, controls are visible.
- While running, controls hide without hover and appear in the top hover zone.
- Reset while running is available only through hover controls.
- Skip segment is available in fullscreen hover controls with the same disabled
  behavior as the main screen.
- Escape or close control exits focus mode.

## Analytics

- Complete a session assigned to a project and verify project analytics update.
- Rename that project and verify analytics still count the old session.
- Complete or migrate an unassigned session and verify it appears as
  "Unassigned"/"Без проекта", not as an empty label.
- Verify planned vs actual/effectiveness reflects the completed session totals.
- Verify recent sessions show time, project/task context, mode, planned time,
  honest time, and distraction count without clipping in RU and EN.
- Complete sessions in at least two timer modes and verify mode effectiveness
  groups them correctly.
- Trigger strict rules in at least two projects or modes and verify distraction
  analytics groups the persisted events by project and mode.
- Complete a session with a selected task and verify `Focus by task` /
  `Фокус по задачам` appears after project summaries and before recent
  sessions.
- Verify sessions with no selected task stay in project/recent-session
  analytics and do not create a task summary.
- Rename an existing task and project, then verify the task summary uses their
  current names while retaining all historical totals.
- Delete a task with linked sessions and verify it remains as a historical
  summary using the latest captured title/project context.
- Verify timed tasks show planned vs honest focus, effectiveness, and a
  progress bar.
- Verify checklist and historical tasks show associated focus and sessions but
  never show time-progress or effectiveness.
- Seed at least 12 task summaries and verify `Show more` / `Показать ещё`
  reveals six at a time, the final remainder, and then `Show less` /
  `Свернуть`.
- Check long RU/EN task titles, compact/wide grids, Light/Dark/custom themes,
  the full-width expansion target, and complete accessibility labels.

## Layout and localization

- Check wide layout at 1680 pt and above. The contextual status rail may appear
  only when this width is available.
- Check medium layout around 980-1679 pt. The timer must remain centered between
  project context and the task workspace without a duplicate context rail.
- Check compact layout below 980 px.
- In compact layout, verify navigation labels retain their readable width and
  move through the horizontal navigation rail instead of compressing or
  overlapping.
- Verify the main screen has project selection on the left of the timer and
  project tasks on the right.
- Verify the right context rail does not duplicate the active project card.
- Switch RU and EN and verify buttons, chips, sheets, empty states, Settings,
  and fullscreen controls do not clip or overlap.
- Use long RU and EN project/task names and verify primary titles wrap to their
  intended 2-3 lines instead of becoming unreadable one-line truncations.
- Enable macOS Full Keyboard Access and traverse sidebar routes, project cards,
  mode chips, task actions, Settings tabs, strict rows, and destructive
  confirmations. Verify focus rings are visible and selected controls expose
  the selected accessibility trait exactly once.
- Restore the owner's original macOS Keyboard Navigation setting after the QA
  run.
- Compare secondary labels in system light, system dark, and a custom theme;
  muted text must remain readable without competing with primary text.
- Verify notification titles/bodies and permission error text follow the
  selected RU/EN language.
- Switch Settings tabs: General, Timers, Strict Mode, Access, Appearance.
- Switch appearance between system/light/dark and verify the app follows macOS
  when set to system while keeping the selected accent theme.
- Verify the menu bar panel reads as a compact HUD, not a large square card.
