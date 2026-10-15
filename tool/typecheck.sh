#!/usr/bin/env bash
#
# Compile-only type check for LIBRARY files (files with no `main()`) — the
# sibling of `tool/run_test.sh`, for the other half of the same problem.
#
# WHY THIS EXISTS
# ---------------
# `flutter analyze` and `dart analyze` both die on this machine with
#
#     CreateFile failed 231 (All pipe instances are busy)
#
# (see the header of `tool/run_test.sh` for the full story). That leaves no way
# to catch a type error before pushing, so CI becomes the only feedback loop and
# every mistake costs a full CI round-trip.
#
# This script compiles a library with `gen_kernel` and reports the type errors,
# without needing the pipe-heavy tooling.
#
# HOW TO READ THE RESULT
# ----------------------
# Two shapes of input, two shapes of success:
#
#   * **A test file** (has `main()`): the compiler exits 0 and writes a kernel.
#   * **A library** (no `main()`): the compiler exits 254, writes NO kernel, and
#     prints `<path>: Error: No 'main' method found.` — **that line is the
#     success signal**, not a problem.
#
# In both cases, any OTHER `Error:` line is a real problem.
#
# TWO FALSE-PASS TRAPS THIS SCRIPT GUARDS AGAINST
# -----------------------------------------------
# Both of these were hit for real while burning down the design debt, and both
# reported "clean" on a file that CI then rejected:
#
#   1. **Anchoring the error pattern.** The compiler formats errors as
#      `path:line:col: Error: message`, so `grep '^Error:'` matches *nothing* —
#      not even a genuine `Method not found`. The pattern here is unanchored.
#   2. **A compiler crash looks like success.** A wrong `--platform` dill makes
#      the compiler print `Unhandled exception` and no `Error:` lines at all,
#      which is indistinguishable from a clean library if you only grep for
#      errors. So neither a kernel nor a "No 'main' method found" line is
#      treated as a pass here.
#
# Usage:
#   tool/typecheck.sh lib/features/x/presentation/pages/y_page.dart
#   tool/typecheck.sh $(git diff --name-only -- 'lib/**/*.dart')
#
# Exit code is 0 only when every file type-checked.
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Override with FLUTTER_ROOT=/path/to/flutter if your SDK lives elsewhere.
FLUTTER_ROOT="${FLUTTER_ROOT:-C:/sdks/flutter_windows_3.38.2-stable/flutter}"
CACHE="$FLUTTER_ROOT/bin/cache"

DART_AOT="$CACHE/dart-sdk/bin/dartaotruntime.exe"
GEN_KERNEL="$CACHE/dart-sdk/bin/snapshots/gen_kernel_aot.dart.snapshot"
# NOTE: the `common` path, not `windows-x64`. The windows-x64 platform dill makes
# the compiler crash with "Can't find dart:_compact_hash".
PLATFORM="$CACHE/artifacts/engine/common/flutter_patched_sdk/platform_strong.dill"

for f in "$DART_AOT" "$GEN_KERNEL" "$PLATFORM"; do
  if [ ! -f "$f" ]; then
    echo "error: missing $f" >&2
    echo "hint: run 'flutter precache --windows' or set FLUTTER_ROOT correctly" >&2
    exit 1
  fi
done

if [ $# -lt 1 ]; then
  echo "usage: $0 <library-or-test.dart> [more.dart ...]" >&2
  exit 64
fi

if [ ! -f .dart_tool/package_config.json ]; then
  echo "error: .dart_tool/package_config.json not found — run 'flutter pub get' first" >&2
  exit 1
fi

OUT_DIR="${TMPDIR:-/tmp}/ledgerly_typecheck"
mkdir -p "$OUT_DIR"

status=0
for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "MISSING $f"
    status=1
    continue
  fi

  kernel="$OUT_DIR/$(basename "${f%.dart}").dill"
  rm -f "$kernel"

  log="$("$DART_AOT" "$GEN_KERNEL" \
    --platform "$PLATFORM" \
    --target=flutter \
    --packages=.dart_tool/package_config.json \
    --no-aot \
    --no-link-platform \
    --enable-asserts \
    -o "$kernel" \
    "$f" 2>&1)"

  if printf '%s' "$log" | grep -q 'Unhandled exception'; then
    echo "CRASH  $f"
    printf '%s\n' "$log" | head -4
    status=1
    continue
  fi

  # Unanchored: the line reads `<path>:<line>:<col>: Error: <message>`.
  errors="$(printf '%s\n' "$log" | grep -E 'Error:' | grep -v "No 'main' method found")"
  if [ -n "$errors" ]; then
    echo "ERRORS $f"
    printf '%s\n' "$errors"
    status=1
    continue
  fi

  # Success is either a written kernel (has `main()`) or the expected
  # "No 'main' method found" line (a library). Neither means it was not checked.
  if [ -f "$kernel" ] || printf '%s' "$log" | grep -q "No 'main' method found"; then
    echo "OK     $f"
  else
    echo "SUSPECT $f — neither a kernel nor a \"No 'main' method found\" line"
    printf '%s\n' "$log" | head -6
    status=1
  fi
done

exit "$status"
