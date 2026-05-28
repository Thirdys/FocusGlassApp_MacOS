# FocusGlass

FocusGlass is a native macOS focus timer for deep work: menu bar control,
full-window planning and analytics, fullscreen focus mode, strict focus
protection, local-first data, and RU/EN localization.

## Current implementation

- Swift Package with a native SwiftUI macOS executable product.
- Testable timer engine and analytics core.
- Split local JSON-backed persistence for projects, tasks, sessions, themes,
  timer presets, distraction rules, and recent analytics.
- Menu bar extra, main cockpit window, settings window, and fullscreen focus
  window.
- Shared Theme Studio for the main window, menu bar panel, and fullscreen focus
  mode, with editable local JSON-backed theme profiles.
- Local design source under `docs/design` so Figma remains optional.

## Requirements

- macOS 14 or newer.
- Full Xcode is recommended for packaging and app debugging. The current
  machine has Swift CLI tools, but `xcodebuild` requires a full Xcode install.
- SwiftData is intentionally deferred until full Xcode is available. The
  installed Command Line Tools package cannot load `SwiftDataMacros`, so this
  build uses a local JSON store while preserving the planned local-first model
  boundaries.

## Build

```sh
swift build
swift test
swift run FocusGlass
```

`swift run FocusGlass` launches the app as a raw SwiftPM executable. That is
useful for quick UI checks, but macOS notification APIs require a real `.app`
bundle, so notification permission checks are disabled in that mode.

To create a simple local `.app` bundle after building:

```sh
./Scripts/package-app.sh
```

## Documentation map

- `docs/assistant-context.md` is the first-read implementation map for future
  assistant sessions.
- `docs/architecture.md` tracks storage, migrations, permissions, strict mode,
  themes, and services.
- `docs/product-context.md` records product intent, scope, and documentation
  upkeep rules.
- `docs/design/design-source.md` records the visual and UX source of truth.
- `docs/qa-checklist.md` tracks automated and manual verification.

When behavior changes, update the relevant docs in the same change. The docs
are treated as part of the implementation, not as optional notes.
