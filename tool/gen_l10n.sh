#!/usr/bin/env bash
#
# Regenerate lib/l10n/generated without the flutter tool.
#
# `flutter gen-l10n` dies on this machine with "CreateFile failed 231 (All pipe
# instances are busy)" during its version check, before reaching the generator.
# This compiles tool/gen_l10n.dart inside the flutter_tools package (the only
# place `package:flutter_tools/...` resolves) and runs it against this repo.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_ROOT="${FLUTTER_ROOT:-C:/sdks/flutter_windows_3.38.2-stable/flutter}"
TOOLS_DIR="$FLUTTER_ROOT/packages/flutter_tools"
DART="$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart.exe"
STAGED="$TOOLS_DIR/bin/gen_l10n_local.dart"

if [ ! -d "$TOOLS_DIR" ]; then
  echo "error: flutter_tools not found at $TOOLS_DIR" >&2
  exit 1
fi

cp "$REPO_ROOT/tool/gen_l10n.dart" "$STAGED"
trap 'rm -f "$STAGED"' EXIT

cd "$TOOLS_DIR"
"$DART" run "$STAGED" "$REPO_ROOT"
