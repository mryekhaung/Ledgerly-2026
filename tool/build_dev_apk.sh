#!/usr/bin/env bash
#
# Builds and installs the dev APK, working around the two environment problems
# documented in docs/Roadmap.md (Phase 0) and .workbuddy-ai/memory:
#
#   1. `flutter build apk` spawns `gradlew.bat`, which hits this box's
#      named-pipe ceiling ("CreateFile failed 231 (All pipe instances are
#      busy.)"). Gradle itself is fine, so we drive it directly from `android/`.
#   2. The Flutter Gradle plugin's `gen_localizations` target shells out to
#      `dart format`, which is another spawn. The localizations are already
#      generated and committed, so we hide `l10n.yaml` for the duration of the
#      build — `GenerateLocalizationsTarget.canSkip` returns true when it is
#      absent — then restore it.
#
# Run from the project root:  ./tool/build_dev_apk.sh
#
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

FLUTTER_ROOT="${FLUTTER_ROOT:-C:/sdks/flutter_windows_3.38.2-stable/flutter}"
ANDROID_SDK="${ANDROID_SDK_ROOT:-C:/Users/yinmy/AppData/Local/Android/Sdk}"
ADB="$ANDROID_SDK/platform-tools/adb.exe"

# INITIAL_ROUTE is deliberately NOT set: a dev build must boot on the calendar
# so the new AdaptiveNav bar is visible. `AppEnvironment.initialRouteFromDartDefine`
# ignores the define in prod builds.
DART_DEFINES="RkxVVFRFUl9BUFBfRkxBVk9SPWRldg=="

echo "==> Clearing any half-written incremental state"
# A failed `--incremental --initialize-from-dill` run leaves a 0-byte app.dill,
# which makes the next attempt fail for an unrelated reason.
rm -rf .dart_tool/flutter_build

echo "==> Building (gen_localizations skipped)"
mv l10n.yaml .l10n.yaml.buildskip
restore_l10n() { mv .l10n.yaml.buildskip l10n.yaml 2>/dev/null || true; }
trap restore_l10n EXIT

(cd android && ./gradlew.bat -q \
  -Ptarget-platform=android-x64 \
  -Ptarget=lib/main.dart \
  -Pbase-application-name=android.app.Application \
  "-Pdart-defines=$DART_DEFINES" \
  -Pdart-obfuscation=false \
  -Ptrack-widget-creation=true \
  -Ptree-shake-icons=false \
  "-Pflutter.androidSdkRoot=$ANDROID_SDK" \
  assembleDevDebug)

restore_l10n

APK="build/app/outputs/flutter-apk/app-dev-debug.apk"
echo "==> Built $APK"

echo "==> Installing on emulator-5554"
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"
"$ADB" install -r "$APK"

echo "==> Launching"
# The package carries the `.dev` applicationId suffix, but the activity class is
# the `namespace` (no suffix): com.yk.ledgerly.MainActivity. Getting this wrong
# yields `Error type 3 / Activity class does not exist`.
"$ADB" shell monkey \
  -p com.yk.ledgerly.dev \
  -c android.intent.category.LAUNCHER 1 >/dev/null

echo "==> Done. The app should now boot on the calendar with the nav bar."
echo
echo "NOTE (fixed 2026-10-12): \`flutter run -d emulator-5554\` now works too."
echo "      The old 'Gradle build failed to produce an .apk file' was caused by"
echo "      AGP 9 naming a flavor build's APK after the flavor while the tool"
echo "      (\`flutter run\` with no --flavor) looks for the flavorless name."
echo "      android/app/build.gradle.kts now pins outputFileName and emits an"
echo "      app-<buildType>.apk alias into build/app/outputs/flutter-apk/, so"
echo "      both \`flutter run\` and \`flutter run --flavor dev\` resolve an APK."
echo "      This script is kept because it is still useful when the box is at"
echo "      the named-pipe ceiling (see the header above)."
