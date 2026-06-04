#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${FOCUSGLASS_RELEASE_VERSION:-}" ]]; then
  VERSION="$FOCUSGLASS_RELEASE_VERSION"
elif git -C "$ROOT_DIR" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "$ROOT_DIR" describe --tags --exact-match)"
elif git -C "$ROOT_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
  VERSION="dev-$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
else
  VERSION="dev-$(date +%Y%m%d%H%M%S)"
fi

RELEASE_DIR="${FOCUSGLASS_RELEASE_DIR:-$ROOT_DIR/build/releases/$VERSION}"
APP_DIR="$RELEASE_DIR/FocusGlass.app"
PACKAGE_WORK_DIR="${FOCUSGLASS_PACKAGE_WORK_DIR:-$RELEASE_DIR/work}"
SCRATCH_PATH="${FOCUSGLASS_SCRATCH_PATH:-$ROOT_DIR/.swiftpm/release-build}"
ZIP_PATH="$RELEASE_DIR/FocusGlass-$VERSION.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

mkdir -p "$RELEASE_DIR"

FOCUSGLASS_APP_DIR="$APP_DIR" \
FOCUSGLASS_PACKAGE_WORK_DIR="$PACKAGE_WORK_DIR" \
FOCUSGLASS_SCRATCH_PATH="$SCRATCH_PATH" \
  "$ROOT_DIR/Scripts/package-app.sh"

rm -f "$ZIP_PATH" "$CHECKSUM_PATH"

if command -v ditto >/dev/null 2>&1; then
  ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
elif command -v zip >/dev/null 2>&1; then
  (cd "$RELEASE_DIR" && zip -qry "$ZIP_PATH" "FocusGlass.app")
else
  echo "Neither ditto nor zip is available to create the release archive." >&2
  exit 1
fi

shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "Created $ZIP_PATH"
echo "Created $CHECKSUM_PATH"
