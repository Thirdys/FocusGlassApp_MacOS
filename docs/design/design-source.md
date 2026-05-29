# FocusGlass Design Source

Figma is optional for this project. If edit access is available, the selected
concept can be moved into Figma and refined there. If Figma is unavailable or
only view access is available, these local concept images and tokens are the
source of truth.

## Concept Screens

- `docs/design/concepts/main-window.png` - primary app cockpit.
- `docs/design/concepts/menu-bar-panel.png` - compact menu bar flow.
- `docs/design/concepts/fullscreen-focus.png` - distraction-free focus mode.

## Visual System

- Style: Mac Glass OS, native SwiftUI, premium but operational.
- Background: graphite glass or true light system background, not beige.
- Materials: layered LiquidGlass with material blur, directional top-left light,
  subtle top specular lines, inner readability scrims, dual edge strokes, and
  soft ambient shadows. Controls use the same glass language with pressed-state
  depth changes.
- Radius: 8-22 depending on surface; repeated cards stay compact.
- Typography: system SF family, clear timer numerals, small controls with
  deliberate font sizes.
- Icons: SF Symbols for UI controls plus a compact custom menu bar mark. The
  menu bar status item uses an AppKit template glyph so macOS can tint it for
  light, dark, translucent, and selected menu bar states.
- The app icon should read as a clear FocusGlass timer: a rounded glass tile,
  simple clock face, focus dot, and one theme-aware progress arc. It must not
  read as a prohibited application badge; avoid slash/prohibition metaphors and
  surreal layered lens geometry for the launcher icon.
- Accent presets: Graphite Glass, Aurora, Forest, Solar, Midnight.
- Theme Studio: the same token set drives the main window, menu bar panel, and
  fullscreen focus mode. Editable tokens include background stops, glass
  opacity, menu glass opacity, fullscreen glow, ring colors, text colors,
  heatmap colors, strict status color, highlight color, highlight alpha, radius,
  borders, shadow depth, density, and motion.

## Current Screen Model

- Main cockpit: quick preset chips and intention at the top; active project
  selector on the left of the timer; project task stack on the right; analytics
  below. The right context rail must not repeat the active project card or the
  project task stack.
- Menu bar: compact glass HUD with preset/time header, progress rail, intention
  row, one primary timer action, strict-mode switch/status, and a bottom toolbar
  for fullscreen, reset, skip, and opening the main app.
- Settings: calm tabbed surface with General, Timers, Strict Mode, Access, and
  Appearance tabs. The selected tab gets a short summary below the rail so the
  sections read as tasks, not a bare label strip. Main settings controls use
  FocusGlass glass controls rather than stock macOS picker/stepper/textfield
  styling.
- Fullscreen focus: large timer, optional intention/task rail, segment rail,
  compact localized strict warning, and hover-only controls while running.

## Quality Rules

- The app opens directly into the usable cockpit, not a landing page.
- The focus screen opens as macOS fullscreen, contains only focus-critical
  information, and does not show the old shield mark in the top bar.
- While the timer is running, fullscreen play/pause/reset/close controls are
  hidden until the pointer enters the top hover zone. During idle, paused, or
  completed states, controls remain visible.
- Menu bar controls must be usable without opening the full app.
- Fullscreen focus mode must use the same glass system as the main cockpit, not
  a separate generic dark screen.
- The working screen uses quick mode chips only. Deep preset editing lives in
  Settings. Reset and skip controls must use distinct icons: reset is
  `arrow.counterclockwise`, skip is `forward.end.fill`.
- Each piece of working information must have one primary home. Do not duplicate
  the same project, task, timer, analytics, permission, or strict-mode content in
  multiple visible areas unless the second appearance has a clearly different
  purpose such as navigation, status, or editing.
- The active project selector belongs on the left side of the main timer. The
  active project's tasks belong on the right side. Do not duplicate the active
  project summary or project tasks in the right context rail.
- Project and task editing happens in sheets, not inline inside dense cards.
  Task estimate controls use minute presets plus a compact stepper.
- Empty states must be paired with explicit primary actions in the surrounding
  surface, such as create project, add task, or configure mode.
- Permission UX is soft: notification prompt once on app-bundle launch,
  Accessibility/Automation/Login Items through clear user buttons, and
  Automation hooks as an interactive Shortcuts check surface with access status
  and explicit run actions.
- Permission rows show explicit states: granted, needs request, unavailable
  outside `.app`, or unknown until the user returns from system settings.
- Permission errors are shown in Russian/English in the active card and written
  to diagnostics with actionable context.
- Settings uses calm tabs: General, Timers, Strict Mode, Access, and Appearance.
  Advanced color controls are collapsed by default.
- Settings should use `GlassSegmentedControl`, `GlassSelect`, `GlassStepper`,
  and `GlassTextFieldStyle` for common controls. Long labels must use
  `lineLimit(1)`, `minimumScaleFactor`, sensible widths, and tooltips so RU/EN
  values do not become unreadable.
- Buttons, chips, segmented options, select triggers/options, sidebar routes,
  and compact icon actions use the theme-driven hover glass treatment. Hover
  must stay legible across FocusGlass themes and macOS light/dark appearance.
- Checkbox toggles use the FocusGlass glass checkbox treatment. Pointer targets
  follow the full highlighted route/card surface, not only the visible label.
- The main active project chooser uses the same `GlassSelect` language as
  Settings, including theme-aware hover states.
- Menu bar UI is a compact HUD with one primary timer action and a small bottom
  toolbar, not a stack of nested cards in a square panel. The shell should read
  as one floating glass surface with subtle internal section treatments.
- Strict mode settings include editable app rules and site rules. Site blocking
  hides the browser and returns the user to fullscreen focus instead of closing
  tabs.
- Strict mode protection runs while the timer is active. Warn returns to
  FocusGlass and shows a warning without hiding the target; Hide returns to
  FocusGlass and hides the matched app/browser. Fullscreen uses the bottom
  inline warning, while normal mode uses a toast.
- RU and EN strings must fit without clipping.
- The app icon should remain readable at small sizes: one simple timer face,
  one focus dot, one accent progress arc, no prohibition slash, no layered visual
  clutter. Runtime Dock icon adapts to the selected effective light/dark theme
  and persists best-effort through `NSWorkspace.setIcon`; Finder `.icns` stays a
  neutral static fallback generated from the same geometry. The menu bar mark is
  a compact AppKit template timer glyph, not the full rounded app icon or app
  title.
- Figma absence must not lower the design bar; screenshot comparison against
  these concepts remains required.

## Known Design Caveats

- Advanced Theme Studio currently uses SwiftUI `Slider` controls. If the goal
  becomes fully custom controls everywhere, introduce a `GlassSlider` before
  replacing those controls.
