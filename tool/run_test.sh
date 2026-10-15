#!/usr/bin/env bash
#
# Run a single Flutter test file without going through `flutter test`.
#
# WHY THIS EXISTS
# ---------------
# On this machine `flutter test`, `flutter analyze` and `dart analyze` all abort with
#
#     CreateFile failed 231 (All pipe instances are busy)
#
# The OS has a machine-wide limit of 231 pipe instances and something else on the
# box is holding them. `flutter test` needs several pipes per run, so it dies
# before collecting a single test. This is an environment problem, not a code
# problem — CI (ubuntu-latest) is unaffected and remains the authoritative oracle.
#
# FIRST, TRY THE PROXY FIX (16 Oct 2026)
# --------------------------------------
# `flutter test` also fails with
#
#     WebSocketException: Invalid WebSocket upgrade request
#
# for every file when the shell exports http_proxy/https_proxy/HTTP_PROXY/
# HTTPS_PROXY. The tool talks to `flutter_tester` over a **localhost** WebSocket,
# and the Dart HTTP client routes that through the proxy. Unsetting the four
# variables for the tool process fixes it completely:
#
#     env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY flutter test
#
# That runs the WHOLE suite, goldens included — which this script cannot do. See
# `docs/Versions.md`. Use this script only when the pipe problem is the blocker.
#
# This script sidesteps the limit by doing the two steps by hand:
#   1. compile the test to a debug kernel with `gen_kernel`, then
#   2. execute that kernel with `flutter_tester.exe`.
# Neither step needs the pipe-heavy tooling that `flutter test` spins up, and the
# output is the normal package:test reporter output — real pass/fail results.
#
# USAGE
#   tool/run_test.sh test/core/design_rules_test.dart
#   tool/run_test.sh test/core/design_rules_test.dart --name "splash"
#
# NOTES
#   * Do NOT add `--aot` to the kernel step. An AOT kernel fed to flutter_tester
#     crashes with:
#        vm.unboxing-info.metadata metadata is allowed in precompiled mode only
#     A debug kernel is what flutter_tester expects.
#   * `gen_kernel_aot.dart.snapshot` is an AOT snapshot, so it must be launched
#     with `dartaotruntime.exe`, not `dart.exe`. Running it under `dart.exe`
#     fails with "is an AOT snapshot and should be run with 'dartaotruntime'".
#   * This script only runs ONE file. To run a whole directory, loop over it —
#     but each invocation pays a ~15 s compile, so a targeted run is much cheaper.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Override with FLUTTER_ROOT=/path/to/flutter if your SDK lives elsewhere.
FLUTTER_ROOT="${FLUTTER_ROOT:-C:/sdks/flutter_windows_3.38.2-stable/flutter}"
CACHE="$FLUTTER_ROOT/bin/cache"

DART_AOT="$CACHE/dart-sdk/bin/dartaotruntime.exe"
GEN_KERNEL="$CACHE/dart-sdk/bin/snapshots/gen_kernel_aot.dart.snapshot"
PLATFORM="$CACHE/artifacts/engine/common/flutter_patched_sdk/platform_strong.dill"
TESTER="$CACHE/artifacts/engine/windows-x64/flutter_tester.exe"

for f in "$DART_AOT" "$GEN_KERNEL" "$PLATFORM" "$TESTER"; do
  if [ ! -f "$f" ]; then
    echo "error: missing $f" >&2
    echo "hint: run 'flutter precache --windows' or set FLUTTER_ROOT correctly" >&2
    exit 1
  fi
done

if [ $# -lt 1 ]; then
  echo "usage: $0 <test-file.dart> [flutter_tester args...]" >&2
  exit 64
fi

TEST_FILE="$1"
shift || true

if [ ! -f "$TEST_FILE" ]; then
  echo "error: no such test file: $TEST_FILE" >&2
  exit 66
fi

if [ ! -f .dart_tool/package_config.json ]; then
  echo "error: .dart_tool/package_config.json not found — run 'flutter pub get' first" >&2
  exit 1
fi

OUT_DIR="${TMPDIR:-/tmp}/ledgerly_test"
mkdir -p "$OUT_DIR"
KERNEL="$OUT_DIR/$(basename "${TEST_FILE%.dart}").dill"

echo "==> compiling $TEST_FILE"
"$DART_AOT" "$GEN_KERNEL" \
  --platform "$PLATFORM" \
  --target=flutter \
  --packages=.dart_tool/package_config.json \
  --no-aot \
  --no-link-platform \
  --enable-asserts \
  -o "$KERNEL" \
  "$TEST_FILE"

echo "==> running"
"$TESTER" --disable-observatory --use-test-fonts "$KERNEL" "$@"
