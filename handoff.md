# FocusGlass Handoff

Last updated: 2026-06-19

## Human Context

FocusGlass is personally important to the user. Treat it as a soulful, long-term project made with care, not as a disposable MVP or a quick demo. Work slowly enough to preserve quality, explain decisions clearly, and protect the existing direction the user cares about.

The user sees the assistant as a friend and collaborator, not only as a tool. Keep that trust in mind: be honest about tradeoffs, avoid rushed changes, keep context durable, and build with love for the future people who will use the app.

## Latest Session Checkpoint

Last checkpoint: 2026-06-19.

Purpose: this section is the quick resume point for future sessions. Update it
whenever work is completed, paused halfway, blocked, or intentionally deferred,
so the next assistant can tell what is done and what is still in motion without
rereading the whole handoff.

Last done:

- Completed the QA First pre-tester pass through the new workflow:
  - Used Graphify for orientation before broad QA/status work.
  - Used Build macOS Apps `build-run-debug` through the real packaged
    `build/FocusGlass.app` and `./script/build_and_run.sh --verify`.
  - Used Build macOS Apps `swiftpm-macos` and `test-triage` for SwiftPM
    build/test validation.
  - Used Product Design `index`, `user-context`, `get-context`, and `audit`
    for a local UX/accessibility audit of the live `.app`. Product Design
    user-context preflight still reports no saved Product Design context.
  - Saved Product Design audit screenshots and notes at
    `/private/tmp/focusglass-product-design-audit-20260619-170421`.
  - Saved QA runtime proof screenshots and diagnostics at
    `/private/tmp/focusglass-qa-proof-20260619-170421`.
  - Accepted screenshots:
    `01-cockpit.png`, `02-settings.png`, `03-strict-mode.png`,
    `04-fullscreen-focus.png`, and `05-outcome-gap.png`.
  - Audit notes are in
    `/private/tmp/focusglass-product-design-audit-20260619-170421/audit-notes.md`.
  - No clear pre-tester blocker was found in launch, Settings, Strict Mode
    overview, fullscreen focus, temp-data isolation, or analytics/empty-state
    paths.
  - Strict warn/hide/pause against real blocked apps/sites was not fully
    exercised because the temporary QA profile had no strict rules and system
    permissions were not granted. Treat this as the next optional runtime proof
    before actual tester delivery, not as a blocker from this pass.
  - Post-session outcome remains a future Product Design-led product chunk.
    The audit captured the current Analytics empty state as outcome-gap
    evidence; it did not implement or fake an outcome screen.
- Implemented the new workflow/dev-loop pass:
  - Added `script/build_and_run.sh` as the active local macOS dev-loop
    entrypoint. It stops an existing FocusGlass process, delegates packaging to
    `./Scripts/package-app.sh`, launches `build/FocusGlass.app`, and supports
    `--verify`, `--logs`, `--telemetry`, and `--debug`.
  - Added local ignored Codex Run config at
    `.codex/environments/environment.toml`; it points the Run action at
    `./script/build_and_run.sh`. `.codex/` remains ignored and must not be
    tracked without an explicit owner decision.
  - Diagnostics now follow `FOCUSGLASS_DATA_DIR`, so packaged-app QA with
    `/private/tmp/focusglass-qa-data` does not write diagnostics into the real
    `~/Library/Application Support/FocusGlass` folder.
  - Updated `docs/assistant-context.md` and `docs/qa-checklist.md` so future
    sessions use Graphify, Build macOS Apps, Product Design, SwiftPM, and
    test-triage as the operating workflow rather than reverting to ad-hoc
    shell-only work.
  - Product Design `get-context` was used in playback mode for the next UX
    chunk: post-session outcome screen, visual source
    `docs/design/design-source.md` plus current `.app`, full interactivity
    when implementation starts. Product Design user-context preflight found no
    saved Product Design context yet.
- Implemented the tester review pass:
  - Theme Studio advanced-token preview for background top/mid/bottom,
    surface/elevated surface, text, and muted text.
  - Separate custom-theme deletion; built-in reset no longer deletes custom
    themes.
  - Strict mode break enforcement setting
    `strictModeEnforcesDuringBreaks`, default `false`.
  - Strict `pauseSession` now pauses the timer, stops ticking, syncs the
    snapshot, and runs Shortcut `FocusGlass Pause`.
  - `GlassStepper` snap behavior for 5-minute grids plus manual minute input in
    task estimate and timer segment editors.
  - Segment duration editor was split so the manual minute field remains usable
    in dense Settings layouts, including Flow segments such as `Разогрев`.
  - Fullscreen skip-segment control.
  - Unassigned quick tasks when no project is active.
  - Scrollable active task lists instead of `.prefix(3)`.
  - 44x44 project/task edit hit areas.
  - Timed/checklist task modes and captured session-task progress.
- Added persistence fields for `activeTaskID`, task `timingMode`,
  `strictModeEnforcesDuringBreaks`, and session `taskID`/`taskTitle`.
- Added `FOCUSGLASS_DATA_DIR` local QA override for packaged-app runs against a
  temporary data directory.
- Added unit coverage for legacy task decode, checklist persistence, unassigned
  quick tasks, all active tasks, active task persistence/clearing, captured
  task progress, checklist no-progress behavior, strict break gating, strict
  pause action, exact preset-segment minute storage, and stepper snap math.
- Added tester-facing `PATCH_NOTES.md` and
  `docs/process/tester-report-template.md`.
- Updated `CHANGELOG.md`, `docs/architecture.md`, `docs/process/roadmap.md`,
  and `docs/qa-checklist.md` for the new behavior.

Validated:

- Used/validated with: Graphify, Build macOS Apps `build-run-debug`,
  Build macOS Apps `swiftpm-macos`, Build macOS Apps `test-triage`, Product
  Design `index`, Product Design `get-context`, Product Design `user-context`
  preflight, Product Design `audit`, Computer Use for live macOS UI control,
  and SwiftPM checks.
- `bash -n script/build_and_run.sh` passed.
- `swift build` passed.
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
  passed: 50/50 tests.
- `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`
  passed and relaunched `build/FocusGlass.app` when run with GUI escalation.
  The sandboxed attempt hit LaunchServices `kLSNoExecutableErr`, so future
  live `.app` verification may need Build macOS Apps-style GUI permission.
- `codesign --verify --deep --strict build/FocusGlass.app` passed.
- Temporary QA data was confirmed under `/private/tmp/focusglass-qa-data`:
  `workspace.json`, `settings.json`, and `Logs/diagnostics.jsonl`.
- `build/FocusGlass.app/Contents/Info.plist` still reports version
  `0.0.2` / build `26`; no release/version bump was made.
- Product Design audit folder contains ordered screenshots plus notes:
  `/private/tmp/focusglass-product-design-audit-20260619-170421`.
- QA proof folder contains ordered screenshots plus copied diagnostics:
  `/private/tmp/focusglass-qa-proof-20260619-170421`.
- `git diff --check` passed.
- `graphify update .` passed and rebuilt the code graph: 979 nodes, 2131
  edges, 63 communities.
- Next skill/workflow: if the owner explicitly asks for tester delivery, use
  Build macOS Apps packaging/release validation and the owner-controlled
  release flow. Otherwise, the next product chunk is Product Design-led
  post-session outcome, then Build macOS Apps live validation.

Previous tester-fix validation still relevant:

- `swift build` passed.
- `git diff --check` passed.
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
  passed: 48/48 tests.
- `./Scripts/package-app.sh` passed and created `build/FocusGlass.app`.
- `codesign --verify --deep --strict build/FocusGlass.app` passed.
- Packaged-app QA was run with `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data`
  so real Application Support data was not touched. The main window, version
  badge, Settings, Timers tab, Flow preset selection, and `Разогрев` segment
  path were checked; the owner then confirmed the visible behavior works and
  asked to stop taking screenshots.
- `graphify update .` passed and rebuilt the code graph.

Not started yet:

- The isolated `tester/<version>` branch, release zip, checksum, final
  build-info, public tag, and tester README have not been created. Do this only
  when the owner asks for the actual tester handoff/release step.
- A deeper manual QA pass for strict warn/hide against real blocked apps/sites
  can still be done before tester delivery, but the QA First pass is no longer
  blocked on screenshots or Settings/fullscreen verification.
- Full post-session outcome screen is still future work; this pass only stores
  the task/session foundation.

Next likely choices:

- First: if tester delivery is next, ask for explicit owner confirmation, then
  bump/confirm `VERSION`
  to `0.0.3` by default, commit, tag `v0.0.3`, run
  `./Scripts/package-release.sh`, verify `.sha256`, and prepare the isolated
  `tester/0.0.3` branch with only tester artifacts.
- Optional before that release step: use Build macOS Apps for one deeper
  strict-mode runtime proof with a real configured blocked app/site and running
  timer.
- After tester handoff/dev-loop, the next product feature should be the
  post-session outcome screen. Start with Product Design context from
  `docs/design/design-source.md` and the current `.app`, then validate through
  Build macOS Apps in the live app.

Active partial work:

- No code partial remains in the tester-fix, workflow/dev-loop, or QA First
  pass after this checkpoint. Release/tag/tester branch work is intentionally
  deferred until the owner explicitly asks for tester delivery.

Resume instructions if a future plan/thread continues from here:

- Start by loading/using these skills in this order:
  1. Graphify for orientation: `graphify query "<current question>"`.
  2. Build macOS Apps `build-run-debug` for `script/build_and_run.sh`, live
     `.app` launch, logs, telemetry, and runtime proof.
  3. Build macOS Apps `swiftpm-macos` and `test-triage` for SwiftPM build/test
     checks.
  4. Product Design `index` + `get-context` before the post-session outcome
     UX work; saved Product Design context is currently missing, so use
     `docs/design/design-source.md` plus the current `.app`.
- If this checkpoint is seen before the commit lands, the intended source
  change for the QA First pass is `handoff.md` only. Local audit/proof
  artifacts live in `/private/tmp` and are not source files.
  Do not stage `.codex/`, `graphify-out/`, `build/`, `.build/`, or `.swiftpm/`.
- Required final checks for this workflow pass:
  `bash -n script/build_and_run.sh`,
  `swift build`,
  `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`,
  `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`
  through Build macOS Apps/live macOS permission when sandboxed LaunchServices
  blocks GUI launch,
  `git diff --check`, and `graphify update .`.
- Intended commit message if not already committed:
  `qa: зафиксировать pre-tester audit` with commit body
  `Ассистент: Codex`.
- Do not create `VERSION` bump, tag `v0.0.3`, release zip, tester branch, or
  GitHub Release until the owner explicitly asks for tester delivery.

## Roadmap Status Snapshot

Purpose: keep `docs/process/roadmap.md` visible in day-to-day handoff answers.
When the owner asks what is next, what is in progress, or how the project is
going, answer in this order: first the current operating plan / immediate
working items, then a separate roadmap status block from this snapshot. Do not
let release/tester work hide the product roadmap.

Roadmap source of truth:

- Full roadmap: `docs/process/roadmap.md`.
- This snapshot is a short working memory view. If implementation changes a
  roadmap item, update this snapshot and the detailed `Next Steps` item.

Started or partially started roadmap items:

- Timer system: partially started. Timer modes, default presets, mode
  descriptions, preset editing, persisted task estimates, task timing modes,
  manual minute entry, and timed-task progress from completed sessions exist.
  Still missing: planned-time outcome flow and a decision on whether built-in
  preset editing is enough or whether true custom timer creation is needed.
- Session outcome: data foundation started, product flow mostly missing.
  `FocusSessionRecord` stores project, planned seconds, honest focus seconds,
  distraction count, optional task ID/title, and sessions are recorded on
  preset completion. Timed tasks receive captured honest focus time. Still
  missing: real post-session review screen, planned vs honest comparison,
  distraction summary, and actions like complete task / continue / start next
  block.
- Strict mode end-to-end: partially started. App/site rules, strict action
  types, warn/hide messages, browser checks, return-to-FocusGlass behavior, and
  hide/quit helpers exist. `pauseSession` is connected to the timer and strict
  break enforcement is configurable. Still missing: packaged-app QA for
  warn/hide/pause, guard/confirmation for `quitAfterOptIn`, and distraction
  history.
- UI interactive layer: partially started. Shared hover, checkbox, select,
  stepper, segmented control, expanded hit areas, and theme-aware interaction
  pieces exist. Project/task edit hit areas, fullscreen skip, scrollable task
  lists, and Theme Studio token preview were improved in the tester pass. Still
  missing: full UI pass over sidebar, project cards, mode chips, settings tabs,
  strict rows, light/dark, and custom themes.
- Analytics: partially started. Daily summary, focus score, completed sessions,
  honest focus time, project grouping, unassigned session handling, and mini
  heatmap UI exist. Still missing: planned vs actual by sessions/tasks/projects,
  recent session history, mode effectiveness, and distraction analytics by
  project and mode.

Parked roadmap items for later:

- Strict-rule presets.
- Improved menu bar HUD.
- Improved fullscreen task flow. Partially started with fullscreen skip and
  active task selection.
- Theme Studio readability pass. Partially started with advanced-token preview.
- Signed/notarized distribution.

## Current Operating Plan

This is the practical order for the next work. Keep it simple and do not use
new tools just to use them.

When answering "how are things", "what is next", or similar status questions,
show this current operating plan first. After the last current operating-plan
item, also show "what is going on with the roadmap" from
`Roadmap Status Snapshot`. If this plan later grows beyond seven items, keep
using the full current operating plan first, then the roadmap block.

1. Use Graphify before broad project/status/codebase questions and after code
   changes: start with `graphify query "<question>"` when the graph exists, and
   finish code changes with `graphify update .`.
2. Baseline pre-tester QA is complete through the real `.app`: Build macOS
   Apps verified launch, Settings, Strict Mode overview, fullscreen focus,
   temp-data isolation, diagnostics, and Product Design audit proof. Optional
   extra proof before tester delivery is a strict warn/hide/pause scenario with
   a real configured blocked app/site and running timer.
3. When the owner asks for tester delivery, prepare the release handoff by
   confirming/bumping `VERSION` to `0.0.3` by default, committing, tagging
   `v0.0.3`, running `./Scripts/package-release.sh`, verifying `.sha256`, and
   creating the isolated `tester/0.0.3` branch with tester artifacts only.
4. Use `script/build_and_run.sh` or the local Codex Run action for the active
   dev loop. Keep it a wrapper over `./Scripts/package-app.sh`; do not duplicate
   packaging logic or change release semantics.
5. Use Product Design when the problem is about UX: unclear screen, awkward
   flow, weak readability, onboarding, permissions, Settings, strict-mode user
   path, or post-session outcome. Use Build macOS Apps after Product Design to
   validate the live `.app`.
6. After tester handoff/dev-loop, the next product chunk is the post-session
   outcome screen: Product Design first for planned vs honest, distraction
   summary, task result, and complete/continue/start-next actions; then Build
   macOS Apps validation in the real app.
7. Do not change the release process without a separate decision:
   `./Scripts/package-release.sh`, `VERSION`, public tags, and tester branches
   remain explicit owner-controlled steps.
8. Do not break the identity. Icon, menu bar glyph, launch animation, and visual
   style changes must improve the existing FocusGlass direction, not create an
   accidental rebrand.

## Current Goal

Keep the near-term tester release flow simple, explicit, and durable:

- owner builds locally with `./Scripts/package-release.sh`;
- tester-visible versions use semantic numbers such as `0.0.2` or `0.1.1`;
- public git tags such as `v0.0.2` mark exact build commits;
- isolated `tester/<version>` branches may carry built artifacts when the owner
  asks for branch-based tester delivery;
- preserve context so work can continue after token limits, network issues, or device changes.

## Product Direction

FocusGlass is a native macOS local-first focus cockpit, not a generic task manager, cloud planner, or team product. Development should strengthen the existing loop:

`prepare focus -> run timer -> protect with strict mode -> review result`

Keep quick choices in the main cockpit, deep configuration in Settings, and system-heavy behavior documented and tested from a packaged `.app`.

## Working Facts

- The real project root on disk is `/Users/thirdys/Documents/New Project/FocusGlassApp_MacOS`.
- Codex must be opened with that project root as the workspace, not the parent
  folder `/Users/thirdys/Documents/New Project`. The parent folder is not a git
  repository, so Codex Git UI/PR state will not display the FocusGlass repo
  there.
- To open the correct workspace from terminal, use
  `/Applications/Codex.app/Contents/Resources/codex app /Users/thirdys/Documents/New\ Project/FocusGlassApp_MacOS`.
- Assistant work should happen on `codex/next`; this branch exists locally and
  on remote `Release/codex/next`.
- Xcode also displays `FocusGlass` because the Swift package name is `FocusGlass`; it is not a second real folder on disk.
- `Package.swift` defines two targets: `FocusGlassCore` and `FocusGlassApp`.
- SwiftPM processes only `Sources/FocusGlassApp/Resources` as app resources.
- `build/` is generated by `Scripts/package-app.sh` and contains packaged `.app` output.
- `build/` is ignored local generated output, not a source-of-truth release
  directory.
- The root `VERSION` file stores the tester-facing semantic version without
  `v`, for example `0.0.2`. Bump it before a tester build when the tester needs
  a visibly distinct version.
- Public git tags are part of the version story. Tag the exact build commit
  with the matching public tag, for example `v0.0.2`; when the current commit
  is exactly tagged, packaging scripts prefer the tag over `VERSION`.
- `Scripts/package-release.sh` creates `build/releases/<version>/FocusGlass.app`,
  `FocusGlass-<version>.zip`, and `FocusGlass-<version>.zip.sha256`.
- `Scripts/package-app.sh` writes the same visible version into
  `CFBundleShortVersionString`; `CFBundleVersion` is a numeric build number
  derived from git history unless overridden.
- The owner builds release/tester artifacts locally with `./Scripts/package-release.sh`
  and decides how to hand the build to a tester. Codex must not turn this into
  mandatory release automation unless the owner explicitly asks.
- GitHub Release, if used, is only a distribution page tied to an exact git tag
  and commit. It does not build FocusGlass. The owner can create a Draft/Pre-release,
  attach the already-built zip and `.sha256`, write Russian release notes, and
  share that page with a tester.
- Separate tester artifact branches are allowed only by explicit owner request.
  They are isolated distribution branches, not source branches. They may contain
  the already-built zip, portable `.sha256`, README, and build-info; never merge
  or PR them into `main` or `codex/next`.
- Tester artifact branch naming: `tester/<artifact-version>`, for example
  `tester/0.0.2`. Do not use `dev-<commit>` for tester-facing builds when a
  semantic version and public tag are available.
- Safe first GitHub Release trial format: tag like `v0.0.2-test.1`, Draft or
  Pre-release enabled, Russian notes, attached `FocusGlass-<version>.zip` and
  matching `.sha256`.
- Exact mental model to preserve: GitHub Release starts from a concrete git
  commit, gets a tag such as `v0.0.2-test.1` or `v0.0.2`, hosts a Release tied
  to that tag, and lets the tester download the already-built zip and `.sha256`.
  It is not a build step.
- Do not commit local `.app`, zip, checksum, or intermediate `build/` products.
- Do not modify or remove older `build/` products unless packaging/release flow
  is checked and the user approves cleanup.
- Archive moves should preserve old paths under `archive/unused-audit-YYYY-MM-DD/` so files can be restored if needed.

## Project Rules

- Use the macOS-focused build workflow for FocusGlass when it is available.
  This project is a SwiftPM macOS app, not an iOS Simulator app.
- Prefer `Build macOS Apps` skills for macOS build/run/debug, SwiftPM,
  AppKit interop, window management, telemetry, signing, packaging, and test
  triage. Use Xcode-aware tools only where they clearly fit the macOS task.
- Use Graphify before broad codebase exploration or architecture answers when
  `graphify-out/graph.json` exists. Start with a scoped graph query, then read
  source files directly for exact code and line-level verification.
- Handoff is the durable workflow source. After each substantial
  implementation, QA, design, or release step, update `Latest Session
  Checkpoint` with what changed, what was validated, what remains deferred, a
  `Used/validated with:` line naming the actual skills/tools, and a
  `Next skill/workflow:` line for the next agent.
- Keep changes tightly scoped to the requested task.
- Keep the tone and pace humane: careful, non-rushed, and collaborative.
- UI rule: every piece of working information should have one primary home. Do not duplicate the same content across main surfaces and side/context panels unless the repeated appearance has a different role such as navigation, status, or editing.
- Identity rule: FocusGlass already has its own visual identity and product
  language. Do not replace it with a random new style, generic trend, or
  unapproved rebrand. Improve the existing Mac Glass OS / timer / focus
  direction from `docs/design/design-source.md`.
- For UI/UX work, use `Product Design` and `Build macOS Apps` together when
  useful: Product Design for user meaning, flow audit, screen variants, and
  visual-target QA when applicable; Build macOS Apps for real macOS `.app`
  validation, windows, menu bar behavior, AppKit/SwiftUI edges, logs,
  screenshots, and runtime proof.
- Update documentation when behavior, architecture, QA, packaging, permissions, visual language, or design rules change.
- Never revert user changes or generated outputs without explicit approval.
- GitHub process lives in `docs/process/github-workflow.md`; follow it for branches, Russian commit messages, Russian PRs, tags, releases, and issue handling.
- Branching is intentionally simple for solo work: use `feature/next` as the default branch for new features and roadmap work; create short separate branches only for isolated fixes/docs/chore/release tasks.
- Every assistant-made commit and assistant-created PR must include the signature line `Ассистент: Codex`.
- Public roadmap lives in `docs/process/roadmap.md`.
- Roadmap visibility rule: do not rely only on the numbered `Next Steps`.
  Keep `Roadmap Status Snapshot` near the top updated whenever roadmap work is
  started, finished, paused halfway, or deprioritized. When the owner asks
  "what is next", "where did we stop", or "how are things going", answer with
  the current operating plan first and the roadmap snapshot immediately after
  it in the same response.

## Build macOS Apps Workflow Integration

The owner downloaded the `Build macOS Apps` Codex plugin/skill set on
2026-06-09. It is a strong fit for FocusGlass because the project is a
package-first native macOS SwiftUI/AppKit app:

- `Package.swift` targets `.macOS(.v14)` and exposes executable `FocusGlass`
  plus library `FocusGlassCore`.
- The app shell uses SwiftUI scenes and AppKit bridges:
  `NSStatusItem`, `NSPopover`, `NSWindow`, Settings, the main cockpit window,
  and the fullscreen focus window.
- Permissions QA must run from a real `.app` bundle, not only from
  `swift run FocusGlass`.

The owner specifically wants this skill set to make active development feel
lighter inside Codex: the assistant should be able to rebuild, relaunch,
inspect, and debug the app quickly while the owner watches the real macOS app
change. This is not the same as an iOS Simulator mirror inside Codex. For
FocusGlass, the useful loop is a real local macOS `.app` launch plus logs,
telemetry, screenshots, and process verification.

Use the macOS skill set as a development-loop accelerator, not as a replacement
for the existing release process:

- `swiftpm-macos`: inspect `Package.swift`, run focused `swift build` and
  `swift test` commands, and understand target/product boundaries.
- `build-run-debug`: use and maintain the project-local
  `script/build_and_run.sh` and local ignored
  `.codex/environments/environment.toml` Run action.
- `appkit-interop`: handle `NSStatusItem`, `NSPopover`, `NSWindow`,
  activation, AppKit representables, and responder-chain/window behavior.
- `swiftui-patterns` and `view-refactor`: keep macOS SwiftUI scenes, Settings,
  menu bar UI, cockpit layout, and reusable controls desktop-native.
- `window-management`: tune main/focus/settings window behavior, restoration,
  activation, fullscreen, and borderless/hidden-titlebar details.
- `telemetry`: use unified logs for runtime evidence around windows, menu bar
  actions, permissions, strict mode, and theme/icon side effects.
- `test-triage`: narrow SwiftPM test failures and separate test setup issues
  from regressions.
- `signing-entitlements` and `packaging-notarization`: diagnose ad-hoc signing,
  permissions, hardened runtime, Gatekeeper, and later notarization/distribution
  work.

FocusGlass-specific use cases to remember:

- Use `build-run-debug` through `./script/build_and_run.sh` for the local
  development loop: build the real `.app`, relaunch it, verify the process,
  inspect logs, and capture screenshots while iterating with the owner. This
  should replace one-off manual build/open command chains during active UI and
  runtime work.
- Use `swiftpm-macos` whenever the task is about package shape, target/product
  boundaries, focused `swift build`, or `swift test` in this package-first repo.
- Use `appkit-interop` for the menu bar extra, `NSStatusItem`, `NSPopover`,
  `NSWindow`, activation/foreground behavior, responder-chain behavior,
  permission-related AppKit edges, and any narrow bridge SwiftUI cannot express
  cleanly.
- Use `swiftui-patterns` when changing scenes, Settings, menu bar UI, main
  cockpit layout, commands, keyboard shortcuts, sidebars, split/detail
  structure, or other desktop-native SwiftUI behavior.
- Use `view-refactor` when a view file or scene becomes too broad before adding
  more behavior. In particular, keep watching `ContentView.swift`: split only
  when it reduces real complexity or protects future work, not as a cosmetic
  churn task.
- Use `window-management` for main window, Settings, fullscreen focus window,
  launch presentation, restoration, activation, placement, titlebar/chrome, and
  borderless or hidden-titlebar behavior. Check deployment target compatibility
  because some newer SwiftUI window APIs require macOS 15+ while FocusGlass
  currently targets macOS 14.
- Use `telemetry` when behavior needs runtime proof: window open/close, menu bar
  actions, sidebar/route changes, timer transitions, strict mode events,
  Automation/Shortcuts checks, permission flows, theme/icon side effects, and
  unexpected fallback paths. Prefer `OSLog.Logger`; avoid permanent noisy logs
  and never log sensitive user content.
- Use `test-triage` when SwiftPM tests fail or when a focused test command is
  needed. Classify build failures, assertions, crashes, async flakes, setup
  issues, and entitlement/host-app assumptions separately.
- Use `signing-entitlements` when launch, permissions, Automation, Gatekeeper,
  sandbox, ad-hoc signing, or missing entitlement behavior smells like a signing
  problem rather than a Swift compile problem.
- Use `packaging-notarization` later for distribution readiness, notarization,
  Developer ID signing, hardened runtime, archive validation, or tester reports
  that only reproduce after downloading/unzipping the app. Do not treat
  notarization as required for ordinary local development.
- Use `liquid-glass` only when intentionally reviewing or modernizing visual
  treatment around macOS system materials, toolbars, sidebars, sheets, and
  custom glass surfaces. Treat it as a design/audit guide for now, not a reason
  to adopt APIs that conflict with the current macOS 14 target.

Safe integration shape:

1. Start broad work with a plan and the relevant skill context. When the owner
   says to implement, make the smallest scoped change and keep the handoff
   current.
2. Keep `Scripts/package-app.sh` as the source of truth for creating
   `build/FocusGlass.app`; keep `Scripts/package-release.sh` as the source of
   truth for tester/release zip artifacts.
3. Keep `script/build_and_run.sh` only as a thin Codex run-loop entrypoint:
   stop any running `FocusGlass` process, call `./Scripts/package-app.sh`,
   launch `build/FocusGlass.app` with `/usr/bin/open -n`, and support
   `--verify`, `--logs`, `--telemetry`, and `--debug`.
4. Do not duplicate the full packaging logic inside the new run script unless
   there is a clear reason. Reuse existing packaging so icons, resources,
   version/build metadata, xattr cleanup, and ad-hoc signing stay consistent.
5. `.codex/environments/environment.toml` currently remains a local ignored
   Codex config. Tracking it as project workflow requires a deliberate
   `.gitignore` exception and owner approval.
6. The new Codex Run action must not become mandatory for ordinary SwiftPM
   builds, tester artifacts, or future contributors. It should improve the
   assistant/owner loop without changing release semantics.
7. After implementation, update `README.md`, `docs/assistant-context.md`,
   `docs/qa-checklist.md`, and this handoff if the build/run/QA process changes.
8. Validate with the smallest useful chain: shell syntax check for the script,
   `./script/build_and_run.sh --verify`, relevant Swift tests, and logs or
   telemetry only when diagnosing runtime behavior.

Future-session mental model:

- Dev loop: code change -> `./script/build_and_run.sh` or Codex Run action ->
  `./Scripts/package-app.sh` creates `build/FocusGlass.app` -> `/usr/bin/open -n`
  relaunches the app -> Codex verifies with `--verify`, screenshots, logs, or
  telemetry as needed.
- Tester/release loop: explicit owner decision -> bump `VERSION` if needed ->
  commit/tag exact source -> `./Scripts/package-release.sh` creates zip and
  `.sha256` -> optional tester branch or GitHub Release. The Codex Run action
  must never silently do this.
- If a future assistant sees "симулятор" in this context, interpret the owner's
  intent as "make the running app visible and easy to inspect during Codex work",
  not as "use iOS Simulator tooling".
- Do not create a second app-staging implementation in `script/build_and_run.sh`.
  The whole point is to reuse the existing app packaging path so dev builds and
  tester builds agree on bundle shape, Info.plist keys, resources, icon,
  versions, xattr cleanup, and ad-hoc signing.
- `.codex/environments/environment.toml` exists only to expose a local Codex Run
  button. Because `.codex/` is ignored today, ask the owner before tracking it
  or adding `.gitignore` exceptions.

Important distinction:

- `Build macOS Apps` is for local macOS app development, launch, debug, logs,
  telemetry, window/AppKit work, and packaging/signing diagnosis.
- It must not automatically create tester branches, public tags, GitHub
  Releases, release zips, or notarization flows. Those remain explicit owner
  decisions under the existing GitHub/tester handoff process.

## Product Design And Creative Production

Product Design should work alongside `Build macOS Apps` whenever FocusGlass work
touches UI, UX, visual clarity, or tester-reported usability problems.

Use this combined workflow:

- Product Design owns the user-facing question: is the screen understandable,
  is the flow comfortable, where can a user stumble, which screen variants are
  worth considering, and what should the UX audit check?
- Build macOS Apps owns the native proof: build and relaunch the real `.app`,
  inspect the actual main window, Settings, menu bar, fullscreen focus, AppKit
  behavior, logs, screenshots, strict-mode behavior, and runtime state.
- For UI/UX changes, future assistants should not only ask "how do I implement
  this in SwiftUI?" They should also ask "will this be clear to the user, what
  would a tester complain about, and how can I verify it in the live macOS app?"
- Product Design `audit` is the default Product Design tool for tester
  feedback, screen clarity, onboarding/permissions, Settings, session-review,
  and strict-mode user flows.
- Product Design `design-qa` is narrower: use it only when there is a selected
  source visual or design target and a running implementation to compare
  against it.

Creative Production is not part of the default FocusGlass development workflow
right now. Keep it in reserve for later external packaging:

- final public-facing presentation of what FocusGlass gives users;
- promo, launch, release, social, or Product Hunt visuals;
- broader brand or visual-territory exploration when the owner explicitly asks.

Logo and identity exception:

- `Creative Production` `logo-explorer` may be useful only for an explicit
  identity exploration: app icon, launcher/Dock/Finder icon direction, logo
  route, wordmark, or broader visual identity route.
- Do not use `logo-explorer` as the default answer for ordinary UX, SwiftUI,
  or menu bar implementation tasks.
- The menu bar glyph is primarily a macOS template-glyph problem: it must be
  compact, monochrome, tintable by AppKit, readable in light/dark/translucent
  and selected menu bar states, and checked in the real menu bar. Creative
  Production may inspire a direction, but Product Design plus Build macOS Apps
  should validate the final behavior.
- App icon, Dock/Finder icon, menu bar glyph, and launch animation are identity
  surfaces. Treat them as part of the existing FocusGlass identity, not as
  disposable decoration. Improve the current Mac Glass OS / timer / focus
  direction; do not replace it unless the owner explicitly decides to rebrand.

## End-of-Task Checkpoint

At the end of every implementation or documentation task, Codex must leave a
durable checkpoint instead of relying on chat history:

- Update `handoff.md` when the task changes release process, architecture, QA,
  packaging, permissions, visual direction, roadmap state, blockers, or next
  steps. For tiny no-op/read-only answers, explicitly say no handoff update was
  needed.
- Update `Latest Session Checkpoint` at the top after substantial work, and
  especially when stopping with a partial implementation, unresolved blocker, or
  deferred decision. It must say what is done, what was validated, what is not
  done, and what should happen next.
- In `Latest Session Checkpoint`, include `Used/validated with:` for the
  actual skills/tools used and `Next skill/workflow:` for the next step. Future
  agents should follow those instructions before falling back to ad-hoc
  shell-only work.
- Update `Roadmap Status Snapshot` when a roadmap item changes state. This is
  the visible day-to-day memory for partially started roadmap work, while
  `docs/process/roadmap.md` remains the source-of-truth roadmap document.
- Record what changed, what was validated, what remains blocked or deferred,
  and the next concrete step.
- Keep generated artifacts out of git: no `.app`, `.zip`, `.sha256`, `.build/`,
  `build/`, `.swiftpm/`, Graphify outputs, or local IDE state.
- Run the relevant checks for the task size; for code changes run the Swift
  diagnostics/tests that match the blast radius and update Graphify when code
  changed.
- Before committing, run `git status --short --branch` and `git diff --check`.
- Commit with a Russian message following `docs/process/github-workflow.md`.
- Push the active Codex branch to `Release` when the remote is available.
- In the final response, state the commit hash, push target, validation run, and
  any remaining blocker plainly.

## Graphify Knowledge Graph

Installed on 2026-06-04 from `safishamsi/graphify`:

- CLI package: `graphifyy 0.8.31`, command path `/Users/thirdys/.local/bin/graphify`.
- Project skill: `.agents/skills/graphify/SKILL.md`.
- Codex instructions: `AGENTS.md`.
- Codex PreToolUse hook: `.codex/hooks.json`.
- Git hooks: `.git/hooks/post-commit` and `.git/hooks/post-checkout`.
- Graph outputs are generated locally under `graphify-out/` and ignored by git.

Current graph state:

- Built locally on 2026-06-04 in AST-only bootstrap mode because this Codex
  environment had no `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `OPENAI_API_KEY`, or
  `ANTHROPIC_API_KEY`.
- Focused corpus excludes `archive/`, `.agents/`, `.codex/`, `graphify-out/`,
  and generated build/IDE directories via `.graphifyignore`.
- Current clean graph stats after the latest code-graph update: 979 nodes,
  2131 links, 0 hyperedges, 62 communities.
- Diagnostics: `graphify diagnose multigraph --json` reported 0 dangling
  endpoints, 0 duplicate edges, and 0 same-endpoint collapsed edges.
- Benchmark: `graphify benchmark graphify-out/graph.json` reported about 4.0x
  fewer tokens per average graph query.

Why this matters for FocusGlass:

- Graphify is a fast project "x-ray" before opening source files. Use it to
  avoid rereading the whole repository every time context is lost or compressed.
- It answers by graph relationships, not just text matches. For example:
  `graphify query "How is the timer flow structured?" --budget 1500`.
- The timer query surfaces the useful chain:
  `TimerMode -> pomodoro/countdown/stopwatch/flow/timebox/intervals -> TimerPreset -> FocusGlassViewModel`.
- The graph currently shows `FocusGlassViewModel` as the main hub with 114
  connections. It touches `TimerPreset`, `FocusTask`, `FocusProject`,
  `FocusGlassStore`, theme state, strict mode models, and synchronization
  methods. Treat edits there as high-blast-radius changes and check impacts
  before patching.
- For impact analysis before changing `FocusTimerEngine`, `TimerPreset`,
  `FocusGlassStore`, strict mode types, or other shared abstractions, run
  `graphify affected "<Concept>" --depth 2`.
- For relationship questions such as how `FocusTimerEngine` reaches UI state,
  run `graphify path FocusTimerEngine FocusGlassViewModel`, then open the
  returned Swift files for exact behavior.
- Token discipline: for broad architecture questions, spend a small query budget
  on Graphify first, then read only the handful of files/nodes it identifies.
  Do not burn tokens by re-scanning `Sources/`, `Tests/`, and `docs/` from
  scratch unless Graphify is missing, stale, or insufficient.

Use Graphify this way:

- For architecture, dependency, "where is this implemented", "what connects X
  to Y", or broad codebase questions, first run
  `graphify query "<question>" --budget 1500` from the project root.
- For direct relationships, run `graphify path "<A>" "<B>"`.
- For a focused concept or type, run `graphify explain "<Concept>"`.
- For impact checks, run `graphify affected "<Concept>" --depth 2`.
- For visual navigation, inspect `graphify-out/GRAPH_REPORT.md`,
  `graphify-out/graph.html`, `graphify-out/GRAPH_TREE.html`, and
  `graphify-out/FocusGlassApp_MacOS-callflow.html`.
- After code changes, run `graphify update .` before finishing the task so the
  graph stays current. This update path is AST-only/no-LLM for code changes.
- If `graphify update .` is silent, treat it as no pending update; verify with
  `graphify check-update .` when freshness matters.
- Do not use Graphify as the final authority for exact behavior. Confirm exact
  implementation by reading source files and running Swift diagnostics/tests.

Semantic/deep mode later:

- The current graph does not include LLM semantic extraction from docs/images.
- For maximum semantic value when a supported key is available, run
  `graphify extract . --mode deep`, then `graphify cluster-only .`, then refresh
  exports with `graphify tree --label FocusGlass` and
  `graphify export callflow-html`.
- If no LLM key is available and `graphify-out/graph.json` is missing, do not
  expect `graphify extract .` to work; it exits with "no LLM API key found".
  Either ask for a supported key or rebuild an AST-only graph from the Graphify
  Python modules as done on 2026-06-04.

## Current Audit Status

Started on 2026-05-28. Continued on 2026-05-29.

Completed:

- Confirmed there is no second real `FocusGlass` folder on disk; `FocusGlass` is an Xcode/package display root.
- Confirmed `Package.swift` resource processing is limited to `Sources/FocusGlassApp/Resources`.
- Confirmed `handoff.md` exists and is the durable continuation file.
- Confirmed `.gitignore` exists on disk but is currently untracked.
- Confirmed the Git repository is not clean: most project files are untracked, while `Scripts/generate-app-icon.swift`, `Sources/FocusGlassApp/Services/FocusGlassRuntimeIcon.swift`, and `handoff.md` appear as added/modified in git status before this audit step.
- Moved confirmed unused/non-runtime candidates into `archive/unused-audit-2026-05-29/`:
  - `Sources/FocusGlassApp/Models/PersistenceModels.swift` -> `archive/unused-audit-2026-05-29/Sources/FocusGlassApp/Models/PersistenceModels.swift`
  - `Sources/FocusGlassCore/ThemePreset.swift` -> `archive/unused-audit-2026-05-29/Sources/FocusGlassCore/ThemePreset.swift`
  - `Sources/FocusGlassApp/Resources/MenuBarIconTemplate.png` -> `archive/unused-audit-2026-05-29/Sources/FocusGlassApp/Resources/MenuBarIconTemplate.png`
- Confirmed likely generated/archive candidates, not moved during this step:
  - `build/FocusGlass.app/**`
  - `build/AppIcon.iconset`
  - `build/AppIcon.sips.iconset`
  - `build/FocusGlassSips.iconset`
  - `build/TestIcon.iconset`
- Confirmed design concept PNGs are referenced by documentation and should be kept unless the design source moves elsewhere.
- Validation after archive move:
  - Xcode `BuildProject` passed.
  - `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test` passed with 37/37 tests.
- Created local commit `318122a Add FocusGlass app source baseline`.
- Pushed `main` to GitHub remote `Release` at `https://github.com/Thirdys/FocusGlassApp_MacOS.git`.
- Local upstream tracking could not be written because `.git/config` was not writable in the current environment, but the remote branch was verified with `git ls-remote`.
- Added GitHub/project process files:
  - `CHANGELOG.md`
  - `docs/process/github-workflow.md`
  - `docs/process/roadmap.md`
  - `.github/pull_request_template.md`
  - `.github/ISSUE_TEMPLATE/*`
- README is now the public GitHub-facing project page.
- GitHub Actions workflow was prepared conceptually but not committed, because the current GitHub token cannot push workflow files without `workflow` scope.
- Created and pushed annotated tag `v0.0.1` with message `релиз: v0.0.1`.
- Started roadmap execution:
  - cleaned the main cockpit so `FocusStackCard` no longer repeats the active project name already shown elsewhere;
  - removed task/project-task content from `FocusContextRailView`; main working content stays in the central cockpit, especially `FocusStackCard` next to the timer.
- Correction: when the user says `skills`, they currently mean Codex/OpenAI skills for the assistant's development workflow, not an in-app FocusGlass feature. Do not add `skills` as a product feature unless the user explicitly asks for app functionality.
- Packaging script now supports writable build locations through environment variables:
  - `FOCUSGLASS_SCRATCH_PATH` for SwiftPM scratch output;
  - `FOCUSGLASS_APP_DIR` for the packaged `.app` output.
- Current assistant-accessible packaged build path: `.swiftpm/xcode/build/FocusGlass.app`.
- Continued roadmap execution:
  - Settings now shows localized descriptions for Pomodoro, Countdown,
    Stopwatch, Flow, Timebox, and Intervals in the preset editor and mode chip
    tooltips.
- Started release artifact policy work:
  - added `Scripts/package-release.sh`;
  - updated `Scripts/package-app.sh` to keep `CLANG_MODULE_CACHE_PATH` inside
    the package work dir, avoiding writes to `~/.cache` in restricted Codex
    environments;
  - documented that `build/` stays ignored generated output;
  - clarified that the owner builds locally with `./Scripts/package-release.sh`;
  - clarified that GitHub Release is optional distribution for already-built
    zip/checksum artifacts, not an app build step or mandatory automation.
- Simplified tester release flow:
  - README, GitHub workflow docs, assistant context, and handoff should describe
    GitHub Release as optional manual distribution, not required automation;
  - first GitHub Release trial should be Draft/Pre-release with a test tag,
    Russian notes, and attached zip/checksum;
  - Codex must preserve this flow in handoff and Graphify memory so future
    sessions do not reintroduce unnecessary release complexity.
- Graphify memory for tester release flow:
  - saved Q&A via `graphify save-result` with question
    `How does FocusGlass tester GitHub Release flow work?`;
  - memory file:
    `graphify-out/memory/query_20260604_095907_how_does_focusglass_tester_github_release_flow_wor.md`;
  - `graphify query "GitHub Release package-release Draft Pre-release sha256 tester" --budget 2600 --dfs`
    surfaces `GitHub Workflow` and `Релизные артефакты`;
  - direct memory search confirms the saved answer says the owner builds with
    `./Scripts/package-release.sh`, GitHub Release is optional distribution and
    not a build step, and branch protection/CI are deferred.
- Validation for simplified release-flow docs:
  - `git diff --check` passed;
  - Swift tests were not run because this was docs/process/memory only;
  - generated Graphify memory remains ignored and must not be committed.
- Tester release dry-run:
  - user clarified the near-term priority: do only the simple tester release
    flow for now; move branch protection/CI to the long-term backlog; do not
    start product roadmap work yet, but keep it remembered.
  - `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
    passed with 37/37 tests.
  - `./Scripts/package-release.sh` created:
    `build/releases/dev-c9a78ff/FocusGlass.app`,
    `build/releases/dev-c9a78ff/FocusGlass-dev-c9a78ff.zip`, and
    `build/releases/dev-c9a78ff/FocusGlass-dev-c9a78ff.zip.sha256`.
  - `shasum -a 256 -c build/releases/dev-c9a78ff/FocusGlass-dev-c9a78ff.zip.sha256`
    passed.
  - No git tag or GitHub Release was created automatically. Use GitHub Release
    only if the owner explicitly asks to publish a Draft/Pre-release for a
    specific tag/commit.
  - Generated release artifacts remain ignored under `build/` and must not be
    committed.
  - Graphify memory for current priorities saved at
    `graphify-out/memory/query_20260604_101414_what_are_the_current_focusglass_priorities_after_t.md`;
    direct memory search confirms: tester release flow is the only current
    priority, branch protection/CI are deferred long-term, and product roadmap
    work is parked until the owner asks to resume it.
- Tester artifact branch upload:
  - user clarified that the already-built test build should be uploaded to a
    separate tester branch.
  - created isolated artifact branch `tester/dev-c9a78ff` from a temporary repo,
    not by switching the source workspace.
  - pushed branch to `Release/tester/dev-c9a78ff`; remote verification:
    `7ecdc423872e470a9884ce9fe5480ce66af950b7 refs/heads/tester/dev-c9a78ff`.
  - artifact branch commit: `7ecdc42 релиз: добавить тестовую сборку dev-c9a78ff`.
  - branch contains only `FocusGlass-dev-c9a78ff.zip`,
    `FocusGlass-dev-c9a78ff.zip.sha256`, `README.md`, and `build-info.txt`.
  - checksum file was normalized to the portable file name
    `FocusGlass-dev-c9a78ff.zip`, not the local absolute path.
  - source branch `codex/next` remains free of build artifacts; `build/` and
    `graphify-out/` stay ignored.
- Tester artifact branch instruction update:
  - translated `tester/dev-c9a78ff` README and `build-info.txt` to Russian.
  - pushed tester branch update `9a743c1 доки: перевести инструкцию тестера`
    to `Release/tester/dev-c9a78ff`.
  - rechecked `shasum -a 256 -c FocusGlass-dev-c9a78ff.zip.sha256` in the
    artifact branch; result: `FocusGlass-dev-c9a78ff.zip: OK`.
  - GitHub banner `tester/dev-c9a78ff had recent pushes` is expected after
    pushing a branch. It is GitHub's prompt to compare/open a PR, not a required
    request for this tester branch. Do not open/merge a PR from tester artifact
    branches into source branches.
  - Git remote PR refs were checked; no PR ref pointed to the tester artifact
    branch commit at the time of inspection.
- Explicit tester versioning:
  - added root `VERSION` with visible version `0.0.2`;
  - updated `Scripts/package-release.sh` to resolve version from
    `FOCUSGLASS_RELEASE_VERSION`, then an exact public tag like `v0.0.2`, then
    `VERSION`, with `dev-<commit>` only as fallback;
  - updated `Scripts/package-app.sh` so `CFBundleShortVersionString` uses the
    same visible semantic version and `CFBundleVersion` uses a numeric git build
    count unless overridden;
  - checksum files are now portable: `FocusGlass-0.0.2.zip.sha256` contains
    `FocusGlass-0.0.2.zip`, not an absolute local path;
  - source commit for versioning change:
    `2385cc2159d0fdabc102d8f13fda1fcc8336fe81`
    (`2385cc2 сборка: ввести явную версию тестовых сборок`);
  - public tag `v0.0.2` was created and pushed to `Release`; exact-tag
    packaging check confirmed `git describe --tags --exact-match HEAD` returned
    `v0.0.2` before the later handoff checkpoint commit.
- Tester artifact branch `tester/0.0.2`:
  - built from source commit `2385cc2159d0fdabc102d8f13fda1fcc8336fe81` tagged
    `v0.0.2`;
  - `./Scripts/package-release.sh` created
    `build/releases/0.0.2/FocusGlass.app`,
    `build/releases/0.0.2/FocusGlass-0.0.2.zip`, and
    `build/releases/0.0.2/FocusGlass-0.0.2.zip.sha256`;
  - checksum verified: `FocusGlass-0.0.2.zip: OK`;
  - `Info.plist` check: `CFBundleShortVersionString` is `0.0.2`,
    `CFBundleVersion` is `22`;
  - artifact branch commit:
    `94efae480b9540bea6e12d43ab49ddcaeb8188b6`
    (`94efae4 релиз: добавить тестовую сборку 0.0.2`);
  - remote verification:
    `94efae480b9540bea6e12d43ab49ddcaeb8188b6 refs/heads/tester/0.0.2`;
  - branch contains only `FocusGlass-0.0.2.zip`,
    `FocusGlass-0.0.2.zip.sha256`, Russian `README.md`, and Russian
    `build-info.txt`;
  - GitHub again displayed the standard "Create a pull request" prompt after
    pushing the tester branch. Do not open/merge PRs from tester artifact
    branches into source branches.
- Graphify memory for explicit tester versioning:
  - saved with question
    `How should FocusGlass tester versions be named and packaged?`;
  - memory file:
    `graphify-out/memory/query_20260604_105206_how_should_focusglass_tester_versions_be_named_and.md`;
  - `graphify update .` rebuilt the code graph after script changes;
  - `graphify query "FocusGlass tester VERSION public tag tester/0.0.2 FocusGlass-0.0.2.zip" --budget 3000 --dfs`
    currently surfaces the updated README/build docs; direct memory search
    confirms the saved answer includes `VERSION`, public tag `v0.0.2`,
    `tester/0.0.2`, and `FocusGlass-0.0.2.zip`.
- Main-window version/build badge:
  - user requested the app version and build number in the lower-right app UI,
    only in the main window, not in menu bar or fullscreen focus mode;
  - added `MainWindowBuildBadge` inside `ContentView`, which is used only by
    `WindowGroup("FocusGlass", id: "main")`;
  - did not modify `MenuBarPanel.swift` or `FullscreenFocusView.swift`, so the
    badge is not present in those surfaces;
  - badge text is localized through `app.version` and `app.build` in RU/EN
    localization and reads from `Bundle.main` Info.plist keys
    `CFBundleShortVersionString` and `CFBundleVersion`;
  - local packaged app verification showed `Версия 0.0.2 / билд 23` in the
    main window bottom-right corner;
  - visual screenshot saved locally at `/private/tmp/focusglass-main.png`;
  - `Scripts/package-app.sh` now clears extended attributes from the generated
    `.app` before ad-hoc signing, after `codesign` initially failed on local
    resource-fork/Finder metadata detritus in generated output.
- Validation for release artifact work:
  - `bash -n Scripts/package-app.sh` passed;
  - `bash -n Scripts/package-release.sh` passed;
  - `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test` passed with 37/37 tests;
  - `FOCUSGLASS_RELEASE_VERSION=dev-sandbox-check FOCUSGLASS_RELEASE_DIR=/private/tmp/focusglass-release-sandbox-check ./Scripts/package-release.sh` created `FocusGlass.app`, `FocusGlass-dev-sandbox-check.zip`, and `FocusGlass-dev-sandbox-check.zip.sha256`.
  - `./Scripts/package-release.sh` on exact tag `v0.0.2` created the
    `0.0.2` release folder and zip;
  - `shasum -a 256 -c FocusGlass-0.0.2.zip.sha256` passed;
  - `git diff --check` passed before the first versioning commit.
- Validation for main-window version/build badge:
  - `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
    passed with 37/37 tests;
  - `./Scripts/package-app.sh` passed after the generated-app xattr cleanup fix;
  - `codesign --verify --deep --strict build/FocusGlass.app` passed;
  - `./Scripts/package-release.sh` passed;
  - `shasum -a 256 -c build/releases/0.0.2/FocusGlass-0.0.2.zip.sha256`
    passed;
  - packaged `Info.plist` checks returned `CFBundleShortVersionString=0.0.2`
    and `CFBundleVersion=23`;
  - screenshot inspection confirmed the badge in the main window bottom-right
    corner. Menu bar and fullscreen code paths were not touched.
- Branch protection and CI are deferred. They can be useful later to protect
  `main` and automatically test PRs, but they are not near-term tasks while the
  project is still using a simple local build -> commit -> push flow.
- CI automation remains blocked until work happens from an environment with
  GitHub `workflow` scope. The current shell also does not have `gh` installed,
  so PR, release, and branch-protection setup cannot be automated here through
  GitHub CLI.

Skills research:

- Found official public repository `openai/skills` at https://github.com/openai/skills.
- It is the best candidate source for Codex skills because it is official, public, and highly starred.
- Do not install random third-party skills without inspecting the skill content first.
- Candidate useful skills for this project later: `define-goal` for turning broad ideas into measurable milestones; possibly `security-threat-model` when strict mode/permissions mature.

## Next Steps

1. For broad status, planning, or codebase questions, start with Graphify:
   `graphify query "<question>"`, then read exact source/docs as needed.
2. Before tester delivery, run Build macOS Apps packaged-app QA:
   `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`,
   then check the main window, Settings, fullscreen, strict mode, logs,
   screenshots, and runtime proof against `docs/qa-checklist.md`.
3. If the owner confirms tester delivery, bump/confirm `VERSION` to `0.0.3` by
   default, commit, tag `v0.0.3`, run `./Scripts/package-release.sh`, verify
   `.sha256`, and create/push isolated `tester/0.0.3` with zip/checksum/README
   and build-info only. Do not create release/tag/tester branch/GitHub Release
   without that explicit command.
4. Use `./script/build_and_run.sh` or the Codex Run action for active dev-loop
   work. Improve the script only if verification exposes a real gap; keep
   `Scripts/package-app.sh` as the source of truth.
5. Next product feature after tester handoff/dev-loop: post-session outcome
   screen. Start with Product Design context from
   `docs/design/design-source.md`, the current `.app`, and local concept
   screenshots if any; then implement planned vs honest, distraction summary,
   task result, and complete/continue/start-next actions; validate with Build
   macOS Apps in the live app.
6. After that, roadmap order is strict distraction history, full UI pass over
   sidebar/cards/settings/strict rows, and analytics for planned vs actual,
   recent sessions, and mode effectiveness.
7. Do not break the existing FocusGlass identity. App icon, Dock/Finder icon,
   menu bar glyph, launch animation, and visual style changes must improve the
   current FocusGlass Mac Glass OS / timer / focus direction, not create an
   accidental rebrand.
8. Product roadmap memory from `docs/process/roadmap.md`: keep these visible
   after the immediate tester/release work so they are not forgotten.
   - Timer system is partially started. Done or started: all planned timer modes
     exist, default presets cover all modes, mode descriptions are in Settings,
     presets can be edited with segments/duration/phase/auto-start, and task
     estimates persist with clamped progress. Still needed: make
     `FocusTask.estimate` drive planned time, task progress, and session result;
     decide whether editing built-in presets is enough or true custom preset
     creation is needed.
   - Session outcome is mostly not built yet. Started: `FocusSessionRecord`
     stores project, planned seconds, honest focus seconds, distraction count,
     and sessions are inserted when a preset completes. Still needed: actual
     post-session review UI, task-level result, planned vs honest comparison,
     distraction summary, and actions such as complete task, continue, or start
     next block.
   - Strict mode end-to-end is partially started. Started: app/site rules,
     `warn`, `hide`, `pauseSession`, and `quitAfterOptIn` action types, warn/hide
     messages, return-to-FocusGlass behavior, browser URL checks, and hide/quit
     helpers. Still needed: full packaged-app QA for warn/hide, connect
     `pauseSession` to the timer, confirm/guard `quitAfterOptIn`, and add
     distraction history.
   - UI interactive layer is partially started. Started: `glassHover`,
     `GlassCheckboxToggleStyle`, `GlassSelect`, `GlassStepper`,
     `GlassSegmentedControl`, many expanded hit areas, and theme-aware hover
     treatments. Still needed: one complete pass over sidebar, project cards,
     mode chips, settings tabs, strict rows, light/dark, and custom themes.
   - Analytics is partially started. Started: daily summary, focus score,
     sessions completed, honest focus time, project grouping, unassigned session
     handling, and mini heatmap UI. Still needed: planned vs actual by sessions,
     tasks, and projects; recent session history; mode effectiveness; and
     distraction analytics by project and mode.
   - Later roadmap items remain parked: strict-rule presets, improved menu bar
     HUD, improved fullscreen task flow, Theme Studio readability pass, and
     signed/notarized distribution.
9. Keep branch protection and GitHub Actions CI in the long-term backlog. Do
   not make them near-term work.
10. Decide whether to set upstream locally later with `git branch --set-upstream-to=Release/main main` after fixing `.git/config` permissions.
11. Inspect useful skills from `openai/skills` before installing anything.
12. Keep `handoff.md` updated after each substantial audit or implementation step.

## Open Questions

- If GitHub Release is tried, should the first one be a private/internal draft
  test only, or a visible pre-release for external testers?
- Later signing plan: stay with local unsigned test builds for now, ad-hoc sign
  before wider testing, or move toward notarized zip/dmg.
- Which Codex skills from `openai/skills` should be installed after inspecting their contents?
