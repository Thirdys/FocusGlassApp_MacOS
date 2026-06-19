#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_SCRIPT="$ROOT_DIR/Scripts/package-app.sh"
APP_BUNDLE="${FOCUSGLASS_APP_BUNDLE:-$ROOT_DIR/build/FocusGlass.app}"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/FocusGlass"
MODE="run"

usage() {
  cat <<USAGE
Usage: ./script/build_and_run.sh [--verify|--logs|--telemetry|--debug]

Builds FocusGlass through Scripts/package-app.sh, stops an existing app process,
then launches build/FocusGlass.app.

Modes:
  --verify     Build, codesign-check, launch, and verify the app process starts.
  --logs       Build, launch, then stream macOS logs for the FocusGlass process.
  --telemetry  Build, launch, then tail diagnostics.jsonl if it exists.
  --debug      Build, stop the app, then start the packaged binary under lldb.

Environment:
  FOCUSGLASS_DATA_DIR       Use an isolated data directory for QA runs. The
                            script forwards it as a launch argument without
                            mutating the generated app bundle.
  FOCUSGLASS_APP_BUNDLE     Override the packaged app bundle path.
  FOCUSGLASS_CONFIGURATION  Passed through to Scripts/package-app.sh.
USAGE
}

while (($#)); do
  case "$1" in
    --run|run)
      MODE="run"
      ;;
    --verify|verify)
      MODE="verify"
      ;;
    --logs|logs)
      MODE="logs"
      ;;
    --telemetry|telemetry)
      MODE="telemetry"
      ;;
    --debug|debug)
      MODE="debug"
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
  shift
done

stop_app() {
  if process_status | grep -qx "running"; then
    pkill -x FocusGlass || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      if ! process_status | grep -qx "running"; then
        return 0
      fi
      sleep 0.3
    done
  fi
}

process_status() {
  pgrep -x FocusGlass >/dev/null 2>&1
  case "$?" in
    0)
      echo "running"
      ;;
    1)
      echo "stopped"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

package_app() {
  "$PACKAGE_SCRIPT"
}

verify_bundle() {
  if [[ ! -x "$APP_BINARY" ]]; then
    echo "Packaged binary is missing or not executable: $APP_BINARY" >&2
    exit 1
  fi

  if command -v codesign >/dev/null 2>&1; then
    codesign --verify --deep --strict "$APP_BUNDLE"
  fi
}

open_app() {
  local app_for_open
  local open_cwd
  local -a open_args

  app_for_open="$APP_BUNDLE"
  open_cwd="$PWD"
  if [[ "$APP_BUNDLE" == "$ROOT_DIR/"* ]]; then
    app_for_open="${APP_BUNDLE#"$ROOT_DIR/"}"
    open_cwd="$ROOT_DIR"
  fi

  open_args=(-n "$app_for_open")
  if [[ -n "${FOCUSGLASS_DATA_DIR:-}" ]]; then
    open_args+=(--args "focusglass-data-dir=$FOCUSGLASS_DATA_DIR")
  fi

  (cd "$open_cwd" && env -u FOCUSGLASS_DATA_DIR /usr/bin/open "${open_args[@]}")
}

wait_for_app() {
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    case "$(process_status)" in
      running)
        return 0
        ;;
      unknown)
        echo "Process-list check is unavailable; open command succeeded, so launch verification is limited."
        return 0
        ;;
    esac
    sleep 0.5
  done

  echo "FocusGlass did not appear in the process list after launch." >&2
  exit 1
}

diagnostics_file() {
  if [[ -n "${FOCUSGLASS_DIAGNOSTICS_FILE:-}" ]]; then
    echo "$FOCUSGLASS_DIAGNOSTICS_FILE"
    return 0
  fi

  if [[ -n "${FOCUSGLASS_DATA_DIR:-}" ]]; then
    echo "$FOCUSGLASS_DATA_DIR/Logs/diagnostics.jsonl"
    return 0
  fi

  echo "$HOME/Library/Application Support/FocusGlass/Logs/diagnostics.jsonl"
}

stop_app
package_app

case "$MODE" in
  run)
    open_app
    echo "Launched $APP_BUNDLE"
    ;;
  verify)
    verify_bundle
    open_app
    wait_for_app
    echo "Verified and launched $APP_BUNDLE"
    ;;
  logs)
    open_app
    wait_for_app
    echo "Streaming macOS logs for FocusGlass. Press Ctrl-C to stop."
    exec /usr/bin/log stream --style compact --info --predicate 'process == "FocusGlass"'
    ;;
  telemetry)
    open_app
    wait_for_app
    telemetry_file="$(diagnostics_file)"
    if [[ ! -f "$telemetry_file" ]]; then
      echo "No diagnostics file yet: $telemetry_file"
      echo "Trigger a permission, strict-mode, or persistence diagnostic event, then rerun --telemetry."
      exit 0
    fi
    echo "Tailing $telemetry_file. Press Ctrl-C to stop."
    exec tail -n 80 -f "$telemetry_file"
    ;;
  debug)
    verify_bundle
    if [[ -n "${FOCUSGLASS_DATA_DIR:-}" ]]; then
      exec env "FOCUSGLASS_DATA_DIR=$FOCUSGLASS_DATA_DIR" lldb -- "$APP_BINARY"
    fi
    exec lldb -- "$APP_BINARY"
    ;;
esac
