# FocusGlass Handoff

Last updated: 2026-08-11

## Human Context

FocusGlass is personally important to the user. Treat it as a soulful, long-term project made with care, not as a disposable MVP or a quick demo. Work slowly enough to preserve quality, explain decisions clearly, and protect the existing direction the user cares about.

The user sees the assistant as a friend and collaborator, not only as a tool. Keep that trust in mind: be honest about tradeoffs, avoid rushed changes, keep context durable, and build with love for the future people who will use the app.

## Latest Session Checkpoint

Last checkpoint: 2026-08-11.

Purpose: this section is the quick resume point for future sessions. Update it
whenever work is completed, paused halfway, blocked, or intentionally deferred,
so the next assistant can tell what is done and what is still in motion without
rereading the whole handoff.

Last done:

- Rechecked `Release/main` after PR #9 was squash-merged. The merge contained
  two identical `TaskAnalyticsCard` declarations and therefore did not build;
  the duplicate declaration was removed in the focused post-merge follow-up
  together with the scroll-state brightness fix.
- Fixed the scroll-state brightness regression found after the unified motion
  pass: `LiquidGlassPanel` now keeps the same material, fill, and readability
  layers, shadows, and control materials before, during, and after scrolling.
  Scroll-state now only disables animated interpolation for real hover changes,
  so panels and controls no longer darken or flash when a gesture starts or
  ends. The design contract and QA checklist explicitly forbid visible
  scroll-state recoloring.
- Completed the unified UI motion and measured SwiftUI performance pass on
  `codex/motion-performance`, based on current `Release/main` plus the intended
  post-main product commits:
  - Added `FocusGlassMotion` timing families for micro, selection, disclosure,
    navigation, emphasis, and progress. Theme motion is clamped to
    `0.8...1.15`; Reduce Motion replaces spatial/draw/pulse behavior with a
    short fade or immediate state.
  - Routed app shell, cockpit, Projects, Analytics, Strict Mode, Settings/Theme
    Studio, Fullscreen, Menu Bar, outcome, and toast changes through
    value-scoped motion. Timer digits do not animate on each one-second tick.
  - Theme Studio slider edits are locally staged, throttled to at most 30 Hz
    while dragging, and finalized once at gesture end. Scroll surfaces preserve
    material, shadows, and brightness while hover changes skip animated
    interpolation; macOS 15 no longer installs the legacy AppKit observer.
  - Added points-of-interest events for route/settings changes, theme commit,
    Menu Bar presentation, and outcome presentation. Extracted shared motion,
    instrumentation, and scroll hot paths into focused source files. Broad
    screen-by-screen extraction was deferred because the trace did not show
    broad invalidation and a large rewrite would add unmeasured risk.
  - Product Design/Build macOS Apps proof covers launch, cockpit, Projects,
    Analytics, Strict Mode, Settings/Theme Studio, Fullscreen, Menu Bar over
    Finder, Light/Dark/custom and RU/EN. Evidence and numbered notes:
    `/private/tmp/focusglass-motion-performance-20260811-154559`.
  - Full Xcode Instruments proof: 55.124 s final trace, no hangs, approximately
    3.5% of one core sampled including automated capture, and narrow
    AttributeGraph work (`propagate_dirty` 1.29%, update stack 1.0%). The hitch
    lane contains 361 events dominated by Computer Use/CoreGraphics capture,
    so no false zero-hitch claim is made. The template exported no SwiftUI
    cause-graph or custom signpost events; rerun with an OS Signpost-enabled
    template when direct signpost proof is needed.
  - App Launch trace measured process creation 253.94 ms, AppKit scene creation
    431.61 ms, initial frame rendering 107.47 ms, and first-frame completion at
    about 919 ms from trace start. The coherent launch overlay then completes
    its intentional approximately 800 ms sequence.
  - Local ignored skills were installed and read: UI UX Pro Max, SwiftUI Expert
    Skill, and Motion Design Skill. Generic landing-page/rebrand suggestions
    were rejected; only motion, contrast, focus-target, responsive, and Reduce
    Motion checks were applied. No skill-install files are tracked.
  - Validation passed: `swift build`, 79/79 SwiftPM tests, packaged
    `./script/build_and_run.sh --verify`, strict codesign, and live `.app` QA.
  - Used/validated with: Graphify, Product Design, Build macOS Apps, SwiftUI
    Expert Skill, Motion Design Skill, UI UX Pro Max, SwiftPM/test-triage,
    Computer Use, full Xcode Instruments, packaged `.app`, and codesign.
  - Not done: the dedicated VoiceOver/accessibility audit, Developer ID
    signing/notarization, release, version/tag, tester branch, or GitHub
    Release. macOS Full Keyboard Access was disabled on the QA host, so a full
    visible keyboard-focus traversal is not claimed by this pass.
  - Next skill/workflow: Product Design + Build macOS Apps for the dedicated
    VoiceOver/accessibility audit. Then use signing-entitlements and
    packaging-notarization for Developer ID distribution readiness.
- Completed the first task-level analytics implementation inside the existing
  Analytics screen:
  - `FocusGlassCore` now exposes `TaskFocusSummary` and
    `AnalyticsEngine.summarizeByTask(_:)`. Only records with `taskID` are
    grouped; equal titles with different IDs remain separate; totals include
    sessions, planned time, honest focus, distractions, and latest focus date.
  - `FocusGlassViewModel` caches task summaries only when `recentSessions`
    changes. Existing tasks use current title/project/timing mode; deleted
    tasks keep the latest captured session context.
  - Analytics shows six adaptive task cards first and expands in groups of six.
    Timed tasks show planned vs honest, effectiveness, and progress. Checklist
    and historical tasks show associated focus without progress or
    effectiveness.
  - The single-task state fills its row, task dates follow the selected
    FocusGlass language, RU/EN strings are present, and each card exposes one
    complete accessibility label.
  - Product Design/Build macOS Apps proof covers empty, one timed task,
    checklist, deleted history, 13-task density, long RU/EN titles,
    compact/wide layouts, and custom Light/Dark variants:
    `/private/tmp/focusglass-task-analytics-20260727-030240`.
    Numbered audit notes are in `audit-notes.md`.
  - Validation passed: isolated `swift build`, 75/75 SwiftPM tests, repeated
    packaged `./script/build_and_run.sh --verify`, strict codesign, full-width
    expansion target, RU/EN accessibility-tree checks, and `git diff --check`.
  - Used/validated with: Graphify, Product Design audit (no saved user
    context), Build macOS Apps, SwiftPM/test-triage, Computer Use, packaged
    `.app`, and codesign.
  - Not done: full VoiceOver/accessibility audit, Developer ID
    signing/notarization, release, tag, tester branch, GitHub Release, custom
    timer presets, or strict-rule presets.
  - Next skill/workflow: run a dedicated Product Design + Build macOS Apps
    VoiceOver/accessibility audit across all primary surfaces. After that, use
    signing-entitlements and packaging-notarization for Developer ID
    distribution readiness.
- Completed the Product Design decision pass for custom timer presets,
  strict-rule presets, and task-level analytics:
  - Editable built-in timer presets are sufficient for the current stage.
    Free-form custom preset creation is deferred until tester feedback proves a
    need for multiple saved variants of the same mode.
  - Strict-rule presets are deferred while the real rule set remains small and
    app/browser dependencies are machine-specific. If revisited, they must be
    safe suggestions with explicit preview, disabled rules by default, and no
    `quitAfterOptIn`.
  - Task-level analytics was approved as the next implementation chunk inside
    the existing Analytics screen. The first pass groups existing session
    records by `taskID` and shows project, session count, planned/honest time,
    distractions, timed-task effectiveness, and last focus date without a new
    persistence schema or sidebar route.
  - Checklist sessions may show associated focus time but must never present it
    as checklist completion progress. Removed tasks use their captured session
    title; renamed existing tasks use the current title.
  - Product Design/Build macOS Apps evidence and numbered decision audit:
    `/private/tmp/focusglass-product-decisions-20260727-022057`.
  - Used/validated with: Graphify, Product Design audit (no saved user
    context), Build macOS Apps, Computer Use, current Swift models, real-data
    copy, and packaged `.app`.
  - This decision checkpoint is superseded by the completed task-level
    analytics checkpoint above.
- Completed the Product Design polish pass for accumulated Analytics and
  Strict History data without restructuring the finished screens:
  - The real-data baseline was taken from an isolated copy of
    `~/Library/Application Support/FocusGlass`: 2 projects, 7 tasks, 4 recent
    sessions, 0 strict-history events, and 3 rules. The original user data was
    never modified.
  - A separate QA copy exercised 16 sessions, 15 strict-history events, all
    six timer modes, all four strict actions, and long RU/EN titles.
  - Analytics now uses a measured 900 pt breakpoint, stacks summary cards at
    compact widths, and lays mode summaries out in adaptive columns. Project,
    mode, and session rows show explicit effectiveness; non-zero values below
    one percent render as `<1%`.
  - Stale project IDs now normalize to the single unassigned bucket across
    tasks, sessions, and distraction history. This removes duplicate
    `Без проекта` rows while preserving valid project links.
  - Recent sessions and Strict History show total counts and use progressive
    show-more/show-less controls instead of silently clipping older records.
    Strict event rows separate target, action/date, project/mode, and task
    context; the destructive history action is now an icon with a 40 pt target,
    help, and an accessibility label.
  - Product Design/runtime proof and numbered audit:
    `/private/tmp/focusglass-real-data-polish-20260727-010950`.
    Final screenshots cover compact dense Analytics, expanded sessions,
    compact/expanded Strict History, RU/EN, and the corrected real-data
    unassigned grouping.
  - Validation passed: isolated `swift build`, 72/72 SwiftPM tests, repeated
    packaged `./script/build_and_run.sh --verify`, strict codesign, RU/EN
    accessibility-tree checks, and `git diff --check`.
  - Used/validated with: Graphify, Product Design audit (no saved user
    context), Build macOS Apps, SwiftPM/test-triage, Computer Use, packaged
    `.app`, and codesign.
  - Not done: no `VERSION`, tag, tester branch, release archive, GitHub
    Release, or tester synchronization.
  - Next skill/workflow: tester feedback starts with SwiftPM/test-triage.
    Further product work starts with Product Design against real data and ends
    with Build macOS Apps packaged proof; choose the next roadmap decision
    before adding another broad UI pass.
- Completed a Product Design-led layout consistency fix for the five
  owner-reported screenshots:
  - The shared horizontal `FocusGlassScrollView` was accepting the full
    vertical proposal in compact mode. `CompactNavBar` now has a stable 64 pt
    rail, so route content remains visible below it.
  - `GlassDisclosureSection` now matches Theme Studio editor groups: the
    content label owns the leading area and the decorative chevron stays on
    the trailing edge. This fixes both `Настройка темы` and `Заметки проекта`
    while preserving the full-row hit target.
  - Cockpit active-task cards, secondary task rows, and Fullscreen task rows
    now keep their ideal vertical size. Long RU checklist titles and metadata
    no longer escape or overlap a compressed selection border.
  - Product Design/Build macOS Apps proof:
    `/private/tmp/focusglass-layout-consistency-20260726-060149`.
    Accepted screenshots cover wide/compact cockpit, collapsed/expanded Theme
    Studio, project notes, a long checklist task, and its Fullscreen state.
  - Validation passed: isolated `swift build`, 71/71 SwiftPM tests, packaged
    `./script/build_and_run.sh --verify`, strict codesign, and
    `git diff --check`.
  - Used/validated with: Graphify, Product Design audit (no saved user context),
    Build macOS Apps, SwiftPM/test-triage, Computer Use, packaged `.app`, and
    codesign.
  - Not done: no `VERSION`, tag, tester branch, release archive, GitHub
    Release, or tester synchronization.
  - Next skill/workflow: owner visual review or tester feedback starts with
    SwiftPM/test-triage. Further UI changes start Product Design-first and end
    with Build macOS Apps packaged proof.
- Completed the repository-wide scroll-performance pass requested after the
  first timer-invalidation optimization:
  - Every vertical/horizontal app `ScrollView` now goes through
    `FocusGlassScrollView`. On macOS 15+ it tracks SwiftUI scroll phase; a
    narrow `NSViewRepresentable` observes live-scroll notifications on macOS
    14. Nested scroll surfaces inherit the active state.
  - While scrolling, shared glass controls suppress hover animations, button
    material layers, and most panel shadow cost. Main/settings stacks and
    compact navigation are lazy; existing task/fullscreen lists remain lazy.
  - Theme Studio advanced groups are independently collapsible. Only
    `Стекло и движение` opens initially, repeated slider/color cards no longer
    add a second material layer, and continuous slider/color edits update live
    without incrementing the app-wide animated theme transition token.
  - Build macOS Apps live QA found and fixed a separate fullscreen compression
    defect: checklist type text could collapse into a vertical letter column.
    Fullscreen task metadata now sits below the multi-line task title.
  - Product Design/runtime proof:
    `/private/tmp/focusglass-scroll-performance-20260726-044203`.
    Accepted screenshots cover Theme Studio top/groups, Strict Settings, rich
    cockpit data, fullscreen scroll, and the corrected fullscreen task layout.
  - Validation passed: isolated `swift build`, 71/71 SwiftPM tests,
    packaged `./script/build_and_run.sh --verify`, strict codesign, and
    `git diff --check`. A raw plain `swift build` can still hit the machine's
    mixed Command Line Tools SDK/module-cache mismatch; the isolated scratch
    path and dev-loop are authoritative on this machine.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftUI performance audit, AppKit interop, SwiftPM/test-triage, Computer
    Use, packaged `.app`, `top`, and codesign.
  - Not done: no `VERSION`, tag, tester branch, release archive, GitHub
    Release, or tester synchronization.
  - Next skill/workflow: owner visual review or tester feedback starts with
    SwiftPM/test-triage. Further real-data UI polish starts Product
    Design-first and finishes with Build macOS Apps proof.
- Completed the mandatory `0. Interface performance` implementation pass:
  - Code-first SwiftUI review found that the one-second
    `@Published engineSnapshot` invalidated the broad
    `FocusGlassViewModel`, including sidebar, project/task panels, and
    analytics-derived work. `FocusTimerPresentationState` now publishes the
    snapshot only to timer surfaces in the cockpit, Menu Bar, fullscreen, and
    context rail.
  - Active-project tasks, project task counts, daily/mode/project analytics,
    and the 28-day heatmap are cached from their source collections. Heatmap
    cache refreshes across a calendar-day change. Redundant
    `activeTaskID = nil` publication during timer start was removed.
  - Product Design live review reproduced the owner's Projects screenshot
    problem: the selected border was applied before the card's outer padding.
    `ProjectGridCard` is now one full selectable surface with 16 pt internal
    padding, 48 pt trailing reserve for the independent edit action, a 340 pt
    adaptive minimum, and up to three title lines.
  - Build macOS Apps plus Computer Use confirmed narrow/medium layouts,
    Light/Dark custom Noir Crimson, long RU/EN project names, and selection by
    clicking the empty lower part of a card. No text crosses the selected
    border and edit controls stay independent.
  - Runtime timer proof: five `top` samples were `0.0...1.2% CPU`, about
    `119 MB` resident memory, and 4 threads. Current custom-theme telemetry
    recorded `ui 0.05 ms`, runtime icon `3.05 ms`, save `2.19 ms`, and icon
    `4.50 ms`.
  - Tests prove timer start/tick produces two timer-state publications and
    zero broad-model publications; task/analytics cache synchronization is
    covered separately.
  - Product Design/runtime proof:
    `/private/tmp/focusglass-performance-pass-20260726-034829`.
  - Validation passed: `swift build`, 70/70 SwiftPM tests,
    `bash -n script/build_and_run.sh`, packaged
    `./script/build_and_run.sh --verify`, strict codesign, and
    `git diff --check`.
  - Limitation: this machine exposes Command Line Tools, not a usable full
    Xcode `xctrace`, so no Instruments trace is claimed. Use Instruments only
    if a reproducible jank remains or full Xcode becomes available.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftPM/test-triage, Computer Use, packaged `.app`, telemetry, `top`, and
    codesign.
  - Not done: no `VERSION`, tag, tester branch, release archive, GitHub
    Release, or tester synchronization.
  - Next skill/workflow: owner visual review or tester feedback starts with
    SwiftPM/test-triage. Further UX polish starts Product Design-first against
    realistic accumulated data and finishes with Build macOS Apps live proof.
- Completed a repository-wide documentation synchronization against current
  code, Git history, `v0.0.4`, and `Release/tester/0.0.4`:
  - `README.md`, product/architecture/assistant/design context, roadmap,
    GitHub workflow, QA, changelog, and current handoff sections now describe
    schema v6, the lifecycle-managed Menu Bar `NSPanel`, shared launch/AppIcon
    geometry, explicit Light/Dark theme variants, Strict history, analytics,
    and the completed full-surface hit-target pass.
  - `CHANGELOG.md` now records all commits after `v0.0.4` under `Unreleased`.
    `PATCH_NOTES.md`, tester checklist, and tester report template are explicitly
    marked as historical `0.0.4` snapshots so they cannot be mistaken for the
    current development branch.
  - Added canonical `docs/process/tester-rules.md` with explanations for
    checksum, ad-hoc signing, notarization, backup, Automation permissions,
    Strict actions, and blocker criteria.
  - Current roadmap now distinguishes completed outcome/Strict history/UI/theme/
    Menu Bar/fullscreen/analytics work from actual open decisions: custom timer
    presets, strict-rule presets, task-level analytics, dedicated VoiceOver
    audit, real-data Product Design polish, and signing/notarization.
  - Validation passed: all local links across 15 active Markdown files exist,
    stale-current-term scans are clean, `bash -n script/build_and_run.sh`,
    `git diff --check`, and 68/68 SwiftPM tests.
  - Used/validated with: Graphify, Git/code/history inspection, SwiftPM and
    documentation link/consistency checks.
  - Not done: no code behavior, `VERSION`, tag, tester branch, release archive,
    GitHub Release, or packaged-app runtime changes.
  - Next skill/workflow: tester feedback starts with SwiftPM/test-triage; UX
    follow-up starts Product Design-first and finishes with Build macOS Apps.
    Before another tester sync, generate a new cumulative checklist/rules/report
    package from current `CHANGELOG.md` and `docs/qa-checklist.md`.
- Completed a Product Design-led full UI hit-target audit and implementation
  pass:
  - Audited every SwiftUI button/disclosure/custom control pattern under
    `Sources/FocusGlassApp`, grounded in the owner's Theme Studio screenshot,
    `docs/design/design-source.md`, and the packaged macOS app.
  - Added shared `FocusGlassHitTarget` metrics: 40 pt for compact controls and
    44 pt for rows. `LiquidGlassButtonStyle`, glass selects/options, segmented
    controls, checkbox labels, mode chips, and theme swatches now give the
    whole rendered surface an explicit content shape.
  - Replaced the two stock `DisclosureGroup` controls with
    `GlassDisclosureSection`. Theme Studio's `Настройка темы` row and cockpit
    project notes now toggle from the center or trailing edge, not only from
    the chevron/text.
  - Expanded independent task/project edit and completion targets without
    making multi-action cards ambiguous. Compact navigation, project/task
    selection, running-app choices, Fullscreen task rows, and shared card
    buttons now use full highlighted-row hit areas.
  - Build macOS Apps plus Computer Use live proof confirmed trailing-area
    activation for Theme Studio, project notes, sidebar routes/projects,
    Fullscreen controls, and the lifecycle-managed Menu Bar panel. The timer
    was restored to idle after interaction checks.
  - Product Design notes and proof:
    `/private/tmp/focusglass-hit-target-audit-20260726`.
    Accepted screenshots are under its `accepted` folder.
  - Validation passed: `swift build`, 68/68 SwiftPM tests,
    `./Scripts/package-app.sh`, `bash -n script/build_and_run.sh`, strict
    codesign verification, `git diff --check`, and `graphify update .`.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftPM/test-triage, Computer Use, packaged `.app`, and codesign.
  - Not done: no release, version, tag, tester branch, or GitHub Release work.
  - Next skill/workflow: tester feedback enters through
    SwiftPM/test-triage. New UI changes start Product Design-first and finish
    with Build macOS Apps live validation; use the shared hit-target primitives
    instead of adding ad-hoc plain-button geometry.
- Completed the mandatory zero-stage design/runtime pass before any future
  tester synchronization:
  - Rebuilt launch motion around shared normalized
    `FocusGlassMarkGeometry`, now used by both the runtime AppIcon renderer and
    the SwiftUI launch mark. The mark is one coherent tile/clock object; the
    old independent spring, 3D rotation, 28 dial ticks, and flying capsule are
    gone.
  - Launch phases are tile `0-120 ms`, arc `100-380 ms`, timer hand
    `220-500 ms`, focus confirmation `420-590 ms`, wordmark `460-650 ms`, and
    cockpit crossfade by about `800 ms`. Theme motion scales the sequence only
    in `0.8...1.15`; Reduce Motion uses a complete static mark and short fade.
    The sequence remains once per process and does not replay when the main
    window is reopened from Menu Bar.
  - Added explicit Light/Dark palettes with schema-v6 migration. Runtime theme
    resolution no longer silently substitutes hard-coded light colors.
    `glassOpacity`, `density`, and `motion` now affect shared UI tokens.
  - Theme Studio now has one preview with Main Window/Menu Bar/Fullscreen
    modes, Light/Dark variant editing, ColorPicker-first color controls,
    per-variant contrast status/repair, validated file import, and file export.
  - Moved the build badge into scroll content, made fullscreen adaptive with a
    complete multi-line long-task rail, and replaced the status `NSPopover`
    with a lifecycle-managed nonactivating `NSPanel` that joins all Spaces and
    remains visible over another active app.
  - Fixed the dev loop so `script/build_and_run.sh` assigns a
    toolchain/SDK-specific SwiftPM scratch path while keeping
    `Scripts/package-app.sh` as packaging source of truth. Direct packaging
    without that environment may still hit an old mixed-SDK `.build`; use the
    dev-loop wrapper for active work.
  - Live Product Design plus Build macOS Apps proof is in
    `/private/tmp/focusglass-zero-stage-qa/accepted`. Accepted evidence:
    `01-launch-final-mark.png`, the three Theme Studio preview modes,
    `05-theme-studio-variants.png`, `06-fullscreen-long-task.png`, and
    `08-menubar-over-textedit-desktop.png`. The last image has TextEdit as the
    active menu-bar application while the FocusGlass panel remains visible.
  - High-refresh automated window-video proof was not retained: current macOS
    obsoletes the legacy CoreGraphics capture path, and `screencapture` did not
    finalize the scripted window recording. The settled launch mark and all
    product surfaces have accepted screenshots; a future ScreenCaptureKit
    helper can close this QA-tooling-only gap.
  - Final validation passed: plain `swift build` after clearing the stale
    mixed-SDK cache, isolated `swift build`, 68/68 Swift tests,
    `bash -n script/build_and_run.sh`,
    `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-zero-stage-qa/data
    ./script/build_and_run.sh --verify`, strict codesign verification,
    `git diff --check`, and `graphify update .`.
  - Git state:
    - the implementation commit is available on
      `Release/codex/next` as `814af85`;
    - `main` had already received the previous cumulative package through a
      squash merge, so cumulative PR #5 duplicated that history and was closed;
    - clean review branch `Release/codex/zero-stage-design` was created from
      current `Release/main` and contains the same zero-stage tree as commit
      `2400feb`;
    - ready PR #6 is mergeable and clean:
      `https://github.com/Thirdys/FocusGlassApp_MacOS/pull/6`.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftPM/test-triage, Computer Use, packaged `.app`, and codesign.
  - Not done: no `VERSION` change, tag, tester branch, release archive, or
    GitHub Release.
  - Next skill/workflow: owner review of this zero-stage PR; then, only after an
    explicit owner command, rebuild cumulative tester delivery through Build
    macOS Apps. New UX work starts Product Design-first and is validated in the
    packaged macOS app.
- Closed the remaining first-step live QA through Product Design plus Build
  macOS Apps:
  - Ran Graphify orientation before the broad QA pass and used the packaged
    `build/FocusGlass.app` with isolated data at
    `/private/tmp/focusglass-step1-live-qa-AliHYHWx/data`.
  - Product Design found one real compact defect: the horizontal navigation
    labels compressed and could overlap below 980 pt. `CompactNavBar` now keeps
    each label/button at intrinsic horizontal width while preserving the
    existing scrollable navigation rail and owner-approved centered timer.
  - Live proof covers compact layout with long RU/EN project/task titles,
    dark/light/Paper/custom themes, and visible keyboard focus during Tab
    traversal. macOS Keyboard Navigation was enabled only for QA and restored
    to its original disabled state.
  - Real Strict Mode proof covers TextEdit `warn`, TextEdit `pauseSession`, and
    a Safari site-rule `hide` through the already granted Automation URL path.
    The deterministic site test used a local `127.0.0.1` page, not an external
    website.
  - The `quitAfterOptIn` destructive confirmation appeared in the live app;
    Cancel kept `allowsQuitAfterOptIn=false`, preserved the prior
    `pauseSession` action, and did not terminate the target.
  - No security-sensitive permission was changed. Automation was already
    granted; Accessibility remains missing in the isolated run and was not
    required for the proven paths.
  - Validation passed with Xcode Swift 6.3.3: `swift build`, 63/63 Swift tests,
    `bash -n script/build_and_run.sh`, strict codesign verification, and
    `git diff --check`. Test-triage found that Swift 6.3.3 reported false
    failures for optional `TimeInterval` `#expect` comparisons even when the
    printed values matched; affected fixtures now use `#require` before exact
    value assertions.
  - Evidence and Product Design audit:
    `/private/tmp/focusglass-step1-live-qa-AliHYHWx`. The ordered proof and
    limitations are in `audit-notes.md`.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftPM/test-triage, and Computer Use.
  - Next skill/workflow: triage tester feedback through SwiftPM/test-triage
    when it arrives. For new product work, use Product Design first and Build
    macOS Apps second for targeted analytics/task-flow polish or the next
    timer/strict-rule decision. Do not create another release, tag, tester
    branch, or GitHub Release without an owner command.
- Completed the Product Design-led cockpit, Strict Mode history, remaining
  first-pass UI/accessibility, and analytics implementation package:
  - Preserved the owner-approved wide cockpit composition: project context on
    the left, timer centered, task workspace on the right. Medium layouts now
    hide the extra context rail; it appears only from 1680 pt.
  - Improved long RU/EN title wrapping, adaptive mode chips and strict rows,
    project-card keyboard activation, visible focus surfaces, accessibility
    selected traits, and light/dark/custom secondary-text contrast.
  - The cockpit Strict Mode manage action now opens Settings directly on the
    Strict Mode tab. Cockpit and Settings app counts both use enabled app rules;
    enabled site rules are reported separately.
  - Added schema v5 persistent distraction history with target, timestamp,
    rule, effective action, session, project, task, and timer mode. Strict Mode
    displays and clears that history.
  - Added a destructive confirmation plus persisted opt-in for
    `quitAfterOptIn`; legacy or unconfirmed quit rules safely fall back to
    `hide`.
  - Added analytics for planned vs actual/effectiveness, recent sessions, mode
    effectiveness, project summaries, and distraction grouping by project and
    mode.
  - Added persistence/core/service tests for schema compatibility, history
    linkage, safe quit behavior, strict actions, and analytics. Validation
    passed with `swift build`, 63/63 Swift tests,
    `./script/build_and_run.sh --verify`, strict codesign verification, and
    `git diff --check`.
  - Product Design audit and Build macOS Apps proof:
    `/private/tmp/focusglass-product-pass-HBsAlZ73`.
    Accepted after screenshots include
    `audit/09-cockpit-after-medium-light.png`,
    `audit/10-strict-direct-settings-after.png`,
    `audit/11-quit-opt-in-confirmation.png`,
    `audit/12-cockpit-after-dark.png`, and
    `audit/13-cockpit-wide-count-after.png`.
  - Live `.app` proof confirmed direct Strict Settings routing, consistent
    enabled-app counts, destructive quit confirmation, history persistence, and
    a real TextEdit `hide` action tied to the active session/project/mode.
  - The remaining real `warn`, `pauseSession`, browser-site, compact, and
    keyboard-focus proof limits from this implementation checkpoint were
    closed by the newer live-QA checkpoint above.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftPM/test-triage, and Computer Use.
  - Next skill/workflow from this older checkpoint is superseded by the newer
    live-QA checkpoint above.
- Synchronized the durable handoff with the completed cumulative tester
  delivery `0.0.4`:
  - Source release commit
    `1b113b55f64ed6db51b0ceeea935cebd8f035d12` is published in
    `Release/codex/next`.
  - `VERSION=0.0.4`; annotated tag `v0.0.4` points to the source release
    commit. Release artifacts are under `build/releases/0.0.4`.
  - Release validation recorded in tester build info passed: `swift build`,
    58/58 Swift tests, `./Scripts/package-release.sh`, SHA-256 verification,
    and strict codesign verification. The packaged app reports bundle version
    `34`, short version `0.0.4`, and bundle identifier
    `local.focusglass.app`.
  - Isolated distribution branch `tester/0.0.4` is pushed at
    `8cde56f33cc4c0ed51b2c3a8b3abec9f8118f645`.
  - `tester/0.0.4` contains exactly `FocusGlass-0.0.4.zip`,
    `FocusGlass-0.0.4.zip.sha256`, `README.md`, `TESTER_CHECKLIST.md`,
    `TESTER_RULES.md`, `build-info.md`, and
    `tester-report-template.md`.
  - This is a cumulative tester build because the earlier tester package was
    not fully tested. Treat the next external report as the first complete
    tester pass over the accumulated product work.
  - Tester-facing documents were clarified in Russian, including checksum,
    local ad-hoc signing/notarization expectations, backup, permissions,
    Strict Mode actions, and report severity.
  - No GitHub Release was created. Creating one remains an explicit owner
    decision.
  - Used/validated with: Graphify for current-state orientation and handoff
    synchronization; existing release proof from SwiftPM tests, packaging,
    checksum, and codesign validation.
  - The Product Design plus Build macOS Apps follow-up named here is now
    complete in the newest checkpoint above. Tester feedback still enters
    through SwiftPM/test-triage when it arrives.
- Implemented Cockpit First UI/UX polish with the owner-requested timer-center
  correction:
  - Used Graphify first:
    `graphify query "FocusGlass cockpit FocusTodayView FocusProject notes intention task row launch overlay" --budget 4200`.
  - Used Product Design `index`, `user-context` preflight, `get-context`
    playback, and `audit` guidance. Saved Product Design context still does not
    exist, so the visual/product source was `docs/design/design-source.md`, the
    current packaged `.app`, and the owner's screenshots/feedback.
  - Used Build macOS Apps `swiftui-patterns`, `build-run-debug`,
    `swiftpm-macos`, and `test-triage` through SwiftPM plus packaged
    `build/FocusGlass.app` validation.
  - Removed the top-level cockpit `Текущее намерение` field and removed legacy
    intention display from menu bar and fullscreen.
  - Added project-scoped `FocusProject.notes`, backward-compatible decode, and
    one-time migration from legacy `intention` into active project notes when
    notes are empty.
  - Added project notes editing in the cockpit disclosure and
    `ProjectEditorSheet`.
  - Rebuilt the cockpit as a three-column wide layout: project/notes on the
    left, timer centered, active task and task list on the right. Do not move
    the timer to a side column in follow-up polishing.
  - Simplified cockpit project chrome: no persistent project edit button, task
    count, or add-project action in the main focus surface.
  - Reworked task rows into one visual card with compact completion/edit
    controls, plus a featured active-task card for the selected session task.
  - Improved the launch overlay with theme-aware glass reveal, timer ticks/ring
    motion, brand fade, and Reduce Motion fallback.
  - Added persistence tests for legacy project notes decode, project notes
    relaunch, legacy intention migration, and active task/progress survival
    after notes updates.
  - Validation passed:
    `swift build`,
    `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
    with 58/58 tests,
    `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-cockpit-ui-pass-20260627/data ./script/build_and_run.sh --verify`,
    and `codesign --verify --deep --strict build/FocusGlass.app`.
  - Product Design audit/proof folder:
    `/private/tmp/focusglass-cockpit-ui-pass-20260627`.
  - Accepted live screenshot:
    `/private/tmp/focusglass-cockpit-ui-pass-20260627/screenshots/02-cockpit-centered.png`.
  - Audit notes:
    `/private/tmp/focusglass-cockpit-ui-pass-20260627/audit-notes.md`.
  - Used/validated with: Graphify, Product Design, Build macOS Apps,
    SwiftPM/test-triage.
  - Cockpit/Theme Studio commit `b54bf4a` is now part of the published
    `codex/next` history. GitHub HTTPS credentials were repaired with the
    repo-local Xcode keychain helper, and the later `0.0.4` source release plus
    tester branch were pushed and verified.
  - The responsive/keyboard, Strict history, UI, and analytics follow-up named
    here is now implemented in the newest checkpoint above.
- Implemented the first Product Design-led UI polish pass after the full UI/UX
  audit. This is not the end of the full UI roadmap item; it closes the most
  visible pre-tester Theme Studio/display issues from the audit:
  - Used Graphify first:
    `graphify query "FocusGlass Theme Studio advanced theme editor settings appearance theme profile UI polish" --budget 3000`.
  - Used Product Design `index`, `user-context` preflight, `get-context`, and
    `audit` guidance. Saved Product Design context still does not exist, so
    the visual/product source stayed `docs/design/design-source.md`, the
    existing codebase patterns, and the live packaged `.app`.
  - Used Build macOS Apps `swiftui-patterns`, `build-run-debug`,
    `swiftpm-macos`, and `test-triage` through SwiftPM plus the packaged app
    workflow.
  - Reworked Theme Studio into a clearer editor: header with active-theme
    badge, swatch grid, one compact live preview, adaptive action grid, and
    grouped advanced sections for glass/motion, accent/status, foundations, and
    readability.
  - After owner screenshot feedback, removed the duplicate token overview /
    explanation block and made color editing picker-first. Color cards now use
    macOS ColorPicker with read-only hex labels instead of asking the user to
    type values such as `#705cf6` by hand.
  - Added a reusable `GlassSlider` control and replaced dense stock slider
    fields in the advanced Theme Studio editor with theme-aware glass sliders
    plus editable numeric fields.
  - Fixed cockpit task-row wrapping pressure by separating the active-session
    badge and timing/checklist metadata from the task title.
  - Fixed a live UX issue where Theme Studio edits from a `.app` under
    Documents/Desktop/Downloads could trigger a macOS file-access prompt:
    persistent `NSWorkspace.setIcon` writes are now skipped in those protected
    locations while the runtime Dock icon still updates.
  - Updated Theme Studio copy/localization and design/process docs for the new
    grouped picker-first editor and protected-folder icon behavior.
  - Local proof folder:
    `/private/tmp/focusglass-theme-studio-polish-20260627-191539`.
  - Accepted clean proof screenshots:
    `screens/05-cockpit-task-row-final.png` and
    `screens/06-theme-studio-advanced-sliders-final.png`.
  - Proof notes:
    `/private/tmp/focusglass-theme-studio-polish-20260627-191539/proof-notes.md`.
- Completed the full Product Design-led UI/UX audit pass requested by the
  owner:
  - Used Graphify first:
    `graphify query "FocusGlass full UI UX pass sidebar project cards mode chips settings strict rows light dark custom themes Product Design" --budget 2800`.
  - Used Product Design `index`, `user-context` preflight, `get-context`
    playback context from `docs/design/design-source.md`, and Product Design
    `audit`. Saved Product Design context still does not exist.
  - Used Build macOS Apps `build-run-debug` through the packaged app workflow:
    `FOCUSGLASS_DATA_DIR=<audit-data-dir> ./script/build_and_run.sh --verify`.
  - Used Computer Use only to inspect/click the live packaged macOS `.app`.
  - Created local audit folder:
    `/private/tmp/focusglass-ui-ux-audit-20260627-184307`.
  - Saved audit notes:
    `/private/tmp/focusglass-ui-ux-audit-20260627-184307/audit-notes.md`.
  - Accepted screenshots:
    `screens/01-cockpit-dark.png`,
    `screens/02-projects-cards.png`,
    `screens/03-analytics.png`,
    `screens/04-strict-overview.png`,
    `screens/05-settings-general.png`,
    `screens/06-settings-strict-rows.png`,
    `screens/07-settings-timers.png`,
    `screens/08-settings-appearance-theme-studio.png`,
    `screens/09-custom-theme.png`,
    `screens/10-cockpit-light.png`,
    `screens/11-cockpit-custom-theme.png`, and
    `screens/12-fullscreen-focus.png`.
  - Audit verdict: no release-blocking UI defect was found for a tester-facing
    QA build.
  - Recommended pre-tester follow-up: verify/fix Strict Mode manage routing so
    it lands directly on Settings -> Strict Mode, and inspect the strict
    app-rule count mismatch where the cockpit reports one blocked app but
    Settings shows no selected applications.
  - Product Design follow-up: reduce task-card wrapping pressure, tune
    secondary text contrast in dark/light/custom themes, clarify sidebar vs
    project-card ownership, and run a measured accessibility pass.
- Completed the attached-task outcome Build macOS Apps proof:
  - Used Graphify first:
    `graphify query "FocusGlass attached timed checklist post-session outcome proof task progress complete continue next session" --budget 2600`.
  - Used Build macOS Apps `build-run-debug` and the existing dev-loop:
    `FOCUSGLASS_DATA_DIR=<scenario-dir> ./script/build_and_run.sh --verify`.
  - Used Computer Use only to inspect/click the real packaged macOS `.app`.
  - Created isolated QA proof folder:
    `/private/tmp/focusglass-outcome-attached-qa-20260627-181435`.
  - Saved proof notes:
    `/private/tmp/focusglass-outcome-attached-qa-20260627-181435/proof-notes.md`.
  - Accepted screenshots:
    `screens/01-timed-outcome.png`,
    `screens/02-timed-start-next.png`,
    `screens/03-checklist-outcome.png`,
    `screens/04-checklist-complete.png`,
    `screens/05-continue-outcome.png`, and
    `screens/06-continue-after-action.png`.
  - Timed task proof: planned `01:00`, honest `01:00`, task progress
    `01:00 / 10:00`, all outcome actions visible.
  - `Следующая сессия` proof: outcome dismissed, timer started again, and the
    captured timed task stayed active with progress.
  - Checklist proof: checklist task showed no timed progress bar and the copy
    explicitly said ordinary/checklist tasks do not receive time.
  - `Закрыть задачу` proof: checklist task was manually closed, outcome
    dismissed, and the active stack became empty.
  - `Продолжить` proof: outcome dismissed and the timed task stayed active
    with `01:00 / 10:00` progress.
  - No pre-tester blocker was found in the attached-task outcome flow.
- Synchronized stale roadmap/handoff planning after the outcome implementation:
  - Updated `docs/process/roadmap.md` and the lower
    `Roadmap Status Snapshot` / `Current Operating Plan` / `Next Steps`
    sections so they no longer describe the outcome screen as missing.
  - Reconfirmed the immediate next proof task: Build macOS Apps validation for
    outcome states with an attached timed task and an attached checklist task.
  - Reconfirmed the next product feature after that proof:
    strict distraction history, followed by the full UI pass and analytics.
- Implemented the Product Design-led post-session outcome screen:
  - Used Graphify first for the session/task persistence data flow:
    `graphify query "FocusGlass post-session outcome screen session task persistence planned honest distraction data flow" --budget 2600`.
  - Used Product Design `index`, `user-context`, and `get-context` in playback
    mode. Saved Product Design context is still missing, so the visual/product
    source was `docs/design/design-source.md` plus the current `.app`.
  - Added runtime `SessionOutcomePresentation` state in
    `FocusGlassViewModel`, created from the existing `FocusSessionRecord` on
    `presetCompleted`. No persistence schema change was needed.
  - Added outcome actions:
    `completeOutcomeTask`, `continueOutcomeTask`, `startNextSessionFromOutcome`,
    and `dismissSessionOutcome`.
  - Added the Focus Today outcome card with planned vs honest time,
    distraction count, task/no-task result, and actions for complete task,
    continue, and start next session.
  - Added RU/EN localization in both packaged resource strings and `L10n`
    fallback dictionaries.
  - Added focused tests for outcome creation, complete-task behavior,
    checklist no-progress/continue behavior, and start-next behavior.
  - Saved live macOS `.app` proof screenshot at
    `/private/tmp/focusglass-post-session-outcome-qa-20260620-133504/01-outcome-screen.png`.
- Created the owner-requested tester delivery snapshot for `0.0.3`:
  - Updated `VERSION` from `0.0.2` to `0.0.3`.
  - Committed release source snapshot:
    `d71dc13 релиз: поднять версию до 0.0.3`.
  - Created and pushed annotated tag `v0.0.3` on that release commit.
  - Ran `./Scripts/package-release.sh`; it created
    `build/releases/0.0.3/FocusGlass.app`,
    `build/releases/0.0.3/FocusGlass-0.0.3.zip`, and
    `build/releases/0.0.3/FocusGlass-0.0.3.zip.sha256`.
  - Verified `FocusGlass-0.0.3.zip.sha256`: `FocusGlass-0.0.3.zip: OK`.
  - Verified release app signing with
    `codesign --verify --deep --strict build/releases/0.0.3/FocusGlass.app`.
  - Confirmed release `Info.plist`: `CFBundleShortVersionString=0.0.3`,
    `CFBundleVersion=28`, bundle id `local.focusglass.app`.
  - Created and pushed isolated artifact branch `tester/0.0.3` at commit
    `48e9957 tester: добавить сборку 0.0.3`.
  - `tester/0.0.3` contains only `FocusGlass-0.0.3.zip`,
    `FocusGlass-0.0.3.zip.sha256`, `README.md`, and `build-info.md`.
  - No GitHub Release was created.
- Started the next Product Design-led product chunk, but paused at checkpoint:
  - Loaded Product Design `index`, `user-context`, and `get-context`.
  - Product Design user-context preflight still reports no saved context.
  - Read `docs/design/design-source.md`.
  - This was the pre-implementation state before the 2026-06-20 outcome pass.
    The first post-session outcome screen is now implemented, tested, and
    validated in the live `.app`.
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
  - This was the pre-implementation audit state. The outcome screen has now
    been implemented in the latest checkpoint above.
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
  passed: 53/53 tests.
- Focused outcome tests also passed:
  `completedSessionAppliesHonestFocusTimeToCapturedTimedTask`,
  `completingOutcomeMarksCapturedTaskDone`,
  `checklistTaskDoesNotReceiveSessionTimeProgress`,
  `continuingOutcomeKeepsChecklistTaskActiveWithoutProgress`, and
  `startNextSessionFromOutcomeKeepsCapturedTaskAndRunsTimer`.
- Release snapshot validation before `v0.0.3` also passed:
  `swift build`, `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`,
  `git diff --check`, `./Scripts/package-release.sh`, checksum verification,
  and release app `codesign --verify --deep --strict`.
- `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`
  passed and relaunched `build/FocusGlass.app` when run with GUI escalation.
  The sandboxed attempt hit LaunchServices `kLSNoExecutableErr`, so future
  live `.app` verification may need Build macOS Apps-style GUI permission.
- `codesign --verify --deep --strict build/FocusGlass.app` passed.
- Live `.app` validation after the outcome implementation confirmed the main
  cockpit and post-session outcome card render in `build/FocusGlass.app`.
  The accepted proof screenshot is
  `/private/tmp/focusglass-post-session-outcome-qa-20260620-133504/01-outcome-screen.png`.
- Temporary QA data was confirmed under `/private/tmp/focusglass-qa-data`:
  `workspace.json`, `settings.json`, and `Logs/diagnostics.jsonl`.
- `build/FocusGlass.app/Contents/Info.plist` reported version `0.0.3` /
  build `29` during this live validation. No new release/version bump was made
  in the outcome-screen checkpoint.
- Product Design audit folder contains ordered screenshots plus notes:
  `/private/tmp/focusglass-product-design-audit-20260619-170421`.
- QA proof folder contains ordered screenshots plus copied diagnostics:
  `/private/tmp/focusglass-qa-proof-20260619-170421`.
- `git diff --check` passed.
- `graphify update .` passed and rebuilt the code graph: 992 nodes, 2172
  edges, 64 communities.
- Current roadmap/handoff sync validation also passed:
  `git diff --check`, stale-phrase search across `handoff.md` and
  `docs/process/roadmap.md`, and `graphify update .`. No Swift build/test was
  rerun for this docs-only checkpoint.
- Attached-task outcome proof validation also passed:
  `bash -n script/build_and_run.sh`, three
  `FOCUSGLASS_DATA_DIR=... ./script/build_and_run.sh --verify` runs through
  the real `build/FocusGlass.app`, visual screenshot inspection with Computer
  Use, screenshot files under
  `/private/tmp/focusglass-outcome-attached-qa-20260627-181435/screens`, and
  persisted workspace checks confirming timed progress, checklist no-progress,
  start-next, complete, and continue outcomes. No source code changed in this
  proof pass.
- Full SwiftPM tests after the attached outcome proof passed:
  `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
  completed 53/53 tests. The output included non-fatal macOS Shortcut warnings
  about missing shortcuts, but the test process exited successfully.
- Full Product Design UI/UX audit validation also passed:
  `FOCUSGLASS_DATA_DIR=... ./script/build_and_run.sh --verify` through the
  real packaged `build/FocusGlass.app`, visual screenshot inspection with
  Computer Use, `screencapture` proof files under
  `/private/tmp/focusglass-ui-ux-audit-20260627-184307/screens`, and written
  audit notes at
  `/private/tmp/focusglass-ui-ux-audit-20260627-184307/audit-notes.md`.
- Theme Studio/UI polish validation passed:
  `bash -n script/build_and_run.sh`, `swift build`,
  `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
  passed 54/54 tests,
  `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-theme-studio-polish-20260627-191539/data ./script/build_and_run.sh --verify`
  rebuilt, verified, and launched the packaged `build/FocusGlass.app`,
  `codesign --verify --deep --strict build/FocusGlass.app` passed,
  `git diff --check` passed, and `graphify update .` rebuilt the graph at
  1017 nodes, 2237 edges, and 57 communities.
- Next skill/workflow: use Build macOS Apps for any follow-up live `.app`
  validation; use Product Design before changing outcome/strict/settings UX;
  use Graphify before broad code navigation/status questions; use
  SwiftPM/test-triage for build/test validation.

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

Remaining after the newest implementation checkpoint:

- The first interface-performance pass, scroll follow-up, owner-reported
  project-card selection/text overflow defect, and unified motion/Instruments
  pass are closed. The latest proof and honest trace limits are documented in
  `/private/tmp/focusglass-motion-performance-20260811-154559/audit-notes.md`.
- The requested compact, keyboard-focus, real `warn`, real `pauseSession`,
  Safari site-rule, and safe `quitAfterOptIn` live-QA limits are closed. The
  proof folder is `/private/tmp/focusglass-step1-live-qa-AliHYHWx`.
- This was not a full VoiceOver audit and did not test every supported browser
  or an external public site. Those are wider-distribution follow-ups, not
  current tester blockers.
- Deeper Product Design refinements for task-attached outcome states can still
  be done later, but both no-task and attached-task outcome states now have
  live `.app` proof.
- GitHub Release was not created for `v0.0.4`.

Next likely choices:

- If tester feedback arrives: classify it with SwiftPM/test-triage, use Product
  Design for UX findings, and validate fixes through Build macOS Apps.
- If continuing UI polish: use Product Design first, then Build macOS Apps live
  validation against real accumulated session/distraction data.
- If moving product roadmap: decide whether analytics needs deeper task-level
  views or whether timer custom-preset work has higher product value.
- Optional later: create a GitHub Release for `v0.0.4` only if the owner asks.

Active partial work:

- Release/tag/tester branch work for `0.0.4` is complete. No code partial
  remains in tester-fix, workflow/dev-loop, QA First, or tester delivery.
- Post-session outcome first implementation is complete. No active partial code
  work is intentionally left open in this checkpoint. Attached-task outcome
  proof is complete.
- Full UI/UX audit is complete as evidence/planning work. First UI polish code
  has been implemented for Theme Studio, cockpit task-row wrapping, and the
  protected-folder icon-persistence prompt. The compact navigation issue found
  by the follow-up live pass and the project-grid selected-surface overflow are
  also fixed. Broader targeted UI polish against real user data remains open.

Resume instructions if a future plan/thread continues from here:

- Start by loading/using these skills in this order:
  1. Graphify for orientation: `graphify query "<current question>"`.
  2. Build macOS Apps `build-run-debug` for `script/build_and_run.sh`, live
     `.app` launch, logs, telemetry, and runtime proof.
  3. Build macOS Apps `swiftpm-macos` and `test-triage` for SwiftPM build/test
     checks.
  4. Product Design `index` + `get-context` before outcome, strict, Settings,
     onboarding, or other UX-flow changes; saved Product Design context is
     currently missing, so use `docs/design/design-source.md` plus the current
     `.app`.
- If this checkpoint is seen before the commit lands, the intended tracked
  source changes are timer-presentation isolation, derived task/analytics
  caches, project-grid selected-surface layout, focused tests, documentation,
  and this handoff update. Local audit/proof artifacts live at
  `/private/tmp/focusglass-performance-pass-20260726-034829`; generated app
  output stays under ignored `build/`. Do not stage `.codex/`, `graphify-out/`,
  `build/`, `.build/`, or `.swiftpm/`.
- Required final checks for this workflow pass:
  `bash -n script/build_and_run.sh`,
  `swift build`,
  `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`,
  `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`
  through Build macOS Apps/live macOS permission when sandboxed LaunchServices
  blocks GUI launch,
  `codesign --verify --deep --strict build/FocusGlass.app`,
  `git diff --check`, and `graphify update .`.
- Intended commit message if not already committed:
  `perf: изолировать обновления таймера` with commit body
  `Ассистент: Codex`.
- Do not create a GitHub Release until the owner explicitly asks for it.

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
  The first outcome flow now uses planned vs honest time after session
  completion. Product decision: built-in preset editing is sufficient for the
  current stage; custom creation is deferred until tester feedback proves a
  need for multiple variants of the same mode.
- Session outcome: first implementation pass is complete.
  `FocusSessionRecord` stores project, planned seconds, honest focus seconds,
  distraction count, optional task ID/title, and sessions are recorded on
  preset completion. Timed tasks receive captured honest focus time. Focus
  Today now shows the post-session review card with planned vs honest,
  distraction count, task/no-task result, and complete/continue/start-next
  actions. Attached timed/checklist states now have live Build macOS Apps proof.
  Still missing: any Product Design polish that follows from future UX review.
- Strict mode end-to-end: partially started. App/site rules, strict action
  types, warn/hide messages, browser checks, return-to-FocusGlass behavior, and
  hide/quit helpers exist. `pauseSession` is connected to the timer and strict
  break enforcement is configurable. Direct Strict Settings routing, enabled
  app/site count consistency, safe confirmed `quitAfterOptIn`, and persistent
  session-linked distraction history are implemented. Real packaged-app proof
  passed for TextEdit `warn`, `hide`, and `pauseSession`, plus a Safari
  site-rule `hide` using the real Automation URL path against local
  `127.0.0.1`. Safe cancellation of `quitAfterOptIn` is also proven.
- UI interactive layer: first broad implementation pass is complete. Shared
  hover, checkbox, select, stepper, segmented control, focus surfaces,
  accessibility selected traits, expanded hit areas, responsive strict rows,
  adaptive mode chips, keyboard-focusable project cards, and improved
  secondary-text contrast exist. The centered-timer cockpit now removes its
  extra context rail below 1680 pt. Compact proof below 980 pt, long RU/EN
  titles, theme readability, and Tab traversal with visible focus are complete.
  Real-data Analytics/Strict readability polish is also complete. The newest
  evidence is at
  `/private/tmp/focusglass-real-data-polish-20260727-010950`.
- Analytics: first requested implementation pass is complete. Daily summary,
  focus score, planned vs actual/effectiveness, recent sessions, mode
  effectiveness, project summaries, and distraction analytics by project/mode
  are visible. Real-data polish and task-level analytics are complete; the next
  quality pass is the dedicated VoiceOver/accessibility audit.

Parked roadmap items for later:

- Strict-rule presets until repeated rule-set recreation is proven.
- Custom timer presets until multiple same-mode variants are requested.
- Dedicated VoiceOver/accessibility audit.
- Signed/notarized distribution.

## Current Operating Plan

This is the practical order for the next work. Keep it simple and do not use
new tools just to use them.

When answering "how are things", "what is next", or similar status questions,
show this current operating plan first. After the last current operating-plan
item, also show "what is going on with the roadmap" from
`Roadmap Status Snapshot`. If this plan later grows beyond seven items, keep
using the full current operating plan first, then the roadmap block.

0. The interface-performance sequence is complete. Timer ticks are isolated,
   derived task/analytics work is cached, project cards remain adaptive, shared
   scroll surfaces suppress compositing churn, `FocusGlassMotion` provides one
   Reduce Motion-aware policy, and Theme Studio continuous edits are throttled.
   Full Xcode App Launch/SwiftUI/Time Profiler evidence and limitations are in
   `/private/tmp/focusglass-motion-performance-20260811-154559/audit-notes.md`.
1. Use Graphify before broad project/status/codebase questions and after code
   changes: start with `graphify query "<question>"` when the graph exists, and
   finish code changes with `graphify update .`.
2. Baseline pre-tester QA is complete through the real `.app`: Build macOS
   Apps verified launch, Settings, Strict Mode overview, fullscreen focus,
   temp-data isolation, diagnostics, and Product Design audit proof. The later
   full UI/UX audit is also complete at
   `/private/tmp/focusglass-ui-ux-audit-20260627-184307`. The later compact,
   keyboard-focus, real warn/pause, Safari site-rule, and safe quit proof is
   complete at `/private/tmp/focusglass-step1-live-qa-AliHYHWx`.
3. Cumulative tester delivery `0.0.4` is complete: `VERSION=0.0.4`, tag
   `v0.0.4`, release zip/checksum under `build/releases/0.0.4`, and isolated
   artifact branch `tester/0.0.4` pushed. The branch includes the full tester
   checklist, rules, build info, and report template. GitHub Release is still
   owner-controlled and was not created.
4. Use `script/build_and_run.sh` or the local Codex Run action for the active
   dev loop. Keep it a wrapper over `./Scripts/package-app.sh`; do not duplicate
   packaging logic or change release semantics.
5. Use Product Design when the problem is about UX: unclear screen, awkward
   flow, weak readability, onboarding, permissions, Settings, strict-mode user
   path, or post-session outcome. Use Build macOS Apps after Product Design to
   validate the live `.app`.
6. The requested cockpit/Strict Mode/history/UI/analytics implementation and
   its focused compact/keyboard/Strict and accumulated-data live-QA passes are
   complete, including task-level analytics. The next work is the dedicated
   VoiceOver/accessibility audit, followed by Developer ID
   signing/notarization. Custom timer and Strict presets remain deferred until
   tester evidence meets their revisit criteria.
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
- Branching is intentionally simple for solo work: assistant work continues on
  `codex/next`; the owner may use `feature/next`. Create short
  `codex/<topic>`/`feature/<topic>` branches only for changes that need
  isolated review, fixes, docs, chores, or release preparation.
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
  `NSStatusItem`, lifecycle-managed `NSPanel`, `NSWindow`, Settings, the main
  cockpit window, and the fullscreen focus window.
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
- `appkit-interop`: handle `NSStatusItem`, `FocusGlassStatusPanel`/`NSPanel`,
  `NSWindow`,
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
- Use `appkit-interop` for the menu bar extra, `NSStatusItem`,
  `FocusGlassStatusPanel`/`NSPanel`, `NSWindow`, activation/foreground behavior,
  responder-chain behavior,
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

## Historical Repository Audit (2026-05)

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
- GitHub CLI is now installed. PR creation can be automated after verifying
  `gh auth status`; GitHub Actions still requires the appropriate workflow
  permissions and remains a separate owner decision.

Skills research:

- Found official public repository `openai/skills` at https://github.com/openai/skills.
- It is the best candidate source for Codex skills because it is official, public, and highly starred.
- Do not install random third-party skills without inspecting the skill content first.
- Candidate useful skills for this project later: `define-goal` for turning broad ideas into measurable milestones; possibly `security-threat-model` when strict mode/permissions mature.

## Next Steps

0. Mandatory zero stage before the next tester synchronization is implemented:
   shared launch/AppIcon geometry, explicit Light/Dark theme variants, live
   theme tokens, one three-mode Theme Studio preview, adaptive fullscreen,
   lifecycle-managed Menu Bar panel, and toolchain-isolated dev loop. Start
   review from the newest `Latest Session Checkpoint` and proof folder
   `/private/tmp/focusglass-zero-stage-qa/accepted`.
1. For broad status, planning, or codebase questions, start with Graphify:
   `graphify query "<question>"`, then read exact source/docs as needed.
2. Cumulative tester delivery `0.0.4` is complete. The isolated
   `tester/0.0.4` branch includes zip, checksum, README, full checklist, tester
   rules, build info, and `tester-report-template.md`. Tester feedback may be
   triaged when it arrives, but current product work is not blocked on it. Do
   not create a GitHub Release or another tester version without a separate
   owner command.
3. The earlier cockpit/Strict live-QA limits are closed through Product Design plus Build
   macOS Apps: compact cockpit below 980 pt, long RU/EN titles, theme
   readability, visible keyboard focus during Tab traversal, real `warn`,
   `pauseSession`, Safari site-rule enforcement, and safe quit confirmation.
   Proof: `/private/tmp/focusglass-step1-live-qa-AliHYHWx`.
4. Before the next tester delivery, review the zero-stage proof, then repeat
   Build macOS Apps packaged-app QA:
   `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-qa-data ./script/build_and_run.sh --verify`,
   then check the main window, Settings, fullscreen, strict mode, logs,
   screenshots, and runtime proof against `docs/qa-checklist.md`.
5. Use `./script/build_and_run.sh` or the Codex Run action for active dev-loop
   work. Improve the script only if verification exposes a real gap; keep
   `Scripts/package-app.sh` as the source of truth.
6. Attached timed/checklist outcome proof is complete. Proof path:
   `/private/tmp/focusglass-outcome-attached-qa-20260627-181435`.
7. Strict distraction history, the first broad UI/accessibility implementation
   pass, accumulated-data Product Design polish, and task-level analytics are
   complete. The next implementation-quality pass is the dedicated
   VoiceOver/accessibility audit; Developer ID signing/notarization follows.
8. Do not break the existing FocusGlass identity. App icon, Dock/Finder icon,
   menu bar glyph, launch animation, and visual style changes must improve the
   current FocusGlass Mac Glass OS / timer / focus direction, not create an
   accidental rebrand.
9. Product roadmap memory from `docs/process/roadmap.md`: keep these visible
   after the immediate tester/release work so they are not forgotten.
   - Timer system is partially started. Done or started: all planned timer modes
     exist, default presets cover all modes, mode descriptions are in Settings,
     presets can be edited with segments/duration/phase/auto-start, and task
     estimates persist with clamped progress. The first outcome flow uses
     planned vs honest session data. Decision: editing built-ins is sufficient;
     custom creation is deferred until tester feedback requests multiple saved
     variants of one mode.
   - Session outcome first pass is built. Started/done: `FocusSessionRecord`
     stores project, planned seconds, honest focus seconds, distraction count,
     and sessions are inserted when a preset completes. Done: actual
     post-session review UI, task-level result, planned vs honest comparison,
     distraction summary, actions such as complete task, continue, or start
     next block, and live attached timed/checklist outcome proof.
   - Strict mode end-to-end is substantially implemented. App/site rules,
     `warn`, `hide`, `pauseSession`, and `quitAfterOptIn` action types, warn/hide
     messages, return-to-FocusGlass behavior, browser URL checks, and hide/quit
     helpers exist. Direct Strict Settings routing, enabled-rule counts, safe
     destructive quit opt-in, and persistent session-linked distraction
     history are complete. Packaged-app proof now covers real warn/pause and a
     Safari site rule through the real Automation URL path.
   - UI interactive layer has a first broad implementation pass:
     `glassHover`,
     `GlassCheckboxToggleStyle`, `GlassSelect`, `GlassStepper`,
     `GlassSegmentedControl`, visible focus surfaces, selected accessibility
     traits, keyboard project cards, responsive strict rows, adaptive chips,
     and measured muted-text improvements. Compact live proof and keyboard Tab
     traversal with visible focus are complete.
   - Analytics first pass is complete: daily summary, focus score, planned vs
     actual/effectiveness, recent sessions, mode effectiveness, project
     summaries, unassigned handling, and distraction grouping by project/mode.
     Richer-data polish and task-level analytics are complete, including
     timed/checklist/historical presentation policy and progressive expansion.
   - Later roadmap items remain parked: conditional strict-rule/custom timer
     presets, dedicated VoiceOver audit, and signed/notarized distribution.
     The first improved Menu Bar HUD, fullscreen task-flow, and Theme Studio
     readability pass are complete in the zero-stage checkpoint.
10. Keep branch protection and GitHub Actions CI in the long-term backlog. Do
   not make them near-term work.
11. Decide whether to set upstream locally later with
    `git branch --set-upstream-to=Release/main main` after fixing
    `.git/config` permissions.
12. Inspect useful skills from `openai/skills` before installing anything.
13. Keep `handoff.md` updated after each substantial audit or implementation
    step.

## Open Questions

- If GitHub Release is tried, should the first one be a private/internal draft
  test only, or a visible pre-release for external testers?
- Later signing plan: stay with local unsigned test builds for now, ad-hoc sign
  before wider testing, or move toward notarized zip/dmg.
- Which Codex skills from `openai/skills` should be installed after inspecting their contents?
