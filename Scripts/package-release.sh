#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"

read_version_file() {
  [[ -f "$VERSION_FILE" ]] || return 1
  awk '
    {
      sub(/\r$/, "")
      sub(/^[[:space:]]+/, "")
      sub(/[[:space:]]+$/, "")
      if ($0 != "" && $0 !~ /^#/) {
        print
        exit
      }
    }
  ' "$VERSION_FILE"
}

normalize_version_label() {
  local value="$1"
  value="${value#v}"
  printf '%s' "$value"
}

if [[ -n "${FOCUSGLASS_RELEASE_VERSION:-}" ]]; then
  VERSION="$(normalize_version_label "$FOCUSGLASS_RELEASE_VERSION")"
elif git -C "$ROOT_DIR" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(normalize_version_label "$(git -C "$ROOT_DIR" describe --tags --exact-match)")"
else
  VERSION_FROM_FILE="$(read_version_file || true)"
  if [[ -n "$VERSION_FROM_FILE" ]]; then
    VERSION="$(normalize_version_label "$VERSION_FROM_FILE")"
  elif git -C "$ROOT_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
    VERSION="dev-$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
  else
    VERSION="dev-$(date +%Y%m%d%H%M%S)"
  fi
fi

if [[ ! "$VERSION" =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]]; then
  echo "Invalid release version '$VERSION'. Use a label like 0.0.2 or 0.0.2-test.1." >&2
  exit 1
fi

APP_VERSION="${FOCUSGLASS_APP_VERSION:-$VERSION}"
APP_VERSION="${APP_VERSION#v}"
APP_VERSION="${APP_VERSION%%[-+]*}"

RELEASE_DIR="${FOCUSGLASS_RELEASE_DIR:-$ROOT_DIR/build/releases/$VERSION}"
APP_DIR="$RELEASE_DIR/FocusGlass.app"
PACKAGE_WORK_DIR="${FOCUSGLASS_PACKAGE_WORK_DIR:-$RELEASE_DIR/work}"
SCRATCH_PATH="${FOCUSGLASS_SCRATCH_PATH:-$ROOT_DIR/.swiftpm/release-build}"
ZIP_PATH="$RELEASE_DIR/FocusGlass-$VERSION.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

mkdir -p "$RELEASE_DIR"

FOCUSGLASS_APP_DIR="$APP_DIR" \
FOCUSGLASS_APP_VERSION="$APP_VERSION" \
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

(cd "$RELEASE_DIR" && shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$CHECKSUM_PATH")")

echo "Created $ZIP_PATH"
echo "Created $CHECKSUM_PATH"
