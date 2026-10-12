#!/usr/bin/env bash
#
# Generates every checked-in artifact that is derived from source.
#
#   1. Drift's `.g.dart` files, after changing anything under `lib/core/database/`
#      — a table, a column, a `@DriftAccessor`, or `@DriftDatabase`.
#   2. `lib/l10n/generated/app_localizations*.dart`, after changing any ARB file.
#
# Both sets of outputs are **committed**, so a forgotten run shows up as a CI
# failure (job `codegen-check`) rather than as a broken checkout.
#
# Usage:  ./scripts/codegen.sh          # one-shot build
#         ./scripts/codegen.sh --watch  # rebuild on save while developing
#         ./scripts/codegen.sh --l10n-only
set -euo pipefail

# Prefer the pinned SDK so codegen output matches CI byte-for-byte.
if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
  DART=(fvm dart)
else
  FLUTTER=(flutter)
  DART=(dart)
fi

cd "$(dirname "$0")/.."

"${FLUTTER[@]}" pub get

run_l10n() {
  "${FLUTTER[@]}" gen-l10n
  # gen-l10n's own formatting pass is cosmetic; make the output canonical here.
  "${DART[@]}" format lib/l10n/generated/
}

case "${1:-}" in
  --watch)
    run_l10n
    "${DART[@]}" run build_runner watch --delete-conflicting-outputs
    ;;
  --l10n-only)
    run_l10n
    ;;
  *)
    "${DART[@]}" run build_runner build --delete-conflicting-outputs
    run_l10n
    ;;
esac
