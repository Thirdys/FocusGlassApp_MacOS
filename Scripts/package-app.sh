#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${FOCUSGLASS_CONFIGURATION:-debug}"
SCRATCH_PATH="${FOCUSGLASS_SCRATCH_PATH:-}"
APP_DIR="${FOCUSGLASS_APP_DIR:-$ROOT_DIR/build/FocusGlass.app}"
PACKAGE_WORK_DIR="${FOCUSGLASS_PACKAGE_WORK_DIR:-$(dirname "$APP_DIR")}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$PACKAGE_WORK_DIR/AppIcon.iconset"
GENERATED_ICON="$PACKAGE_WORK_DIR/AppIcon.icns"
SOURCE_ICON="$ROOT_DIR/Sources/FocusGlassApp/Resources/AppIcon.icns"

BUILD_ARGS=(
  build
  --disable-sandbox
  --package-path "$ROOT_DIR"
  -c "$CONFIGURATION"
)

if [[ -n "$SCRATCH_PATH" ]]; then
  BUILD_ARGS+=(--scratch-path "$SCRATCH_PATH")
  BUILD_DIR="$SCRATCH_PATH/$CONFIGURATION"
else
  BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
fi

swift "${BUILD_ARGS[@]}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$PACKAGE_WORK_DIR"
cp "$BUILD_DIR/FocusGlass" "$MACOS_DIR/FocusGlass"
if [[ -d "$BUILD_DIR/FocusGlass_FocusGlassApp.bundle" ]]; then
  cp -R "$BUILD_DIR/FocusGlass_FocusGlassApp.bundle" "$RESOURCES_DIR/"
fi

swift "$ROOT_DIR/Scripts/generate-app-icon.swift" "$ICONSET_DIR"
if ! iconutil -c icns "$ICONSET_DIR" -o "$GENERATED_ICON" 2>/dev/null; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$ICONSET_DIR/icon_512x512@2x.png" "$GENERATED_ICON" <<'PY'
import sys
from PIL import Image

source, output = sys.argv[1], sys.argv[2]
image = Image.open(source)
image.save(
    output,
    sizes=[(16, 16), (32, 32), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)]
)
PY
  fi
fi

if [[ -f "$GENERATED_ICON" ]]; then
  cp "$GENERATED_ICON" "$RESOURCES_DIR/AppIcon.icns"
else
  cp "$SOURCE_ICON" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>FocusGlass</string>
  <key>CFBundleIdentifier</key>
  <string>local.focusglass.app</string>
  <key>CFBundleName</key>
  <string>FocusGlass</string>
  <key>CFBundleDisplayName</key>
  <string>FocusGlass</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHumanReadableCopyright</key>
  <string>Personal local build</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>FocusGlass использует Automation, чтобы проверять активные вкладки браузера и запускать Shortcuts во время полноэкранного строгого фокуса.</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "Created $APP_DIR"
