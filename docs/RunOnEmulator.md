# Run on an emulator — handoff

Everything that can be generated inside the agent sandbox already is. Two things
cannot run here, for one documented reason (`docs/Versions.md`): Dart cannot spawn
child processes under the sandbox token, because `CreateNamedPipeW` with
`nMaxInstances = -1` returns `ERROR_INVALID_PARAMETER (87)` and that is the value
Dart's Windows launcher passes.

That covers `build_runner`, `analyze`, `test`, and `flutter run` itself. It also
kills a booted emulator the moment its launching shell exits. So these steps are
yours to run — in your own terminal, where `flutter` works normally.

## Current state

| Artifact | State |
|---|---|
| `lib/l10n/generated/app_localizations{,_en,_ja,_my}.dart` | ✅ generated and committed (73/73/73 parity) |
| `lib/core/database/**/*.g.dart` (4 files) | ❌ **not generated** — `build_runner` has never run |
| `pubspec.lock`, `.dart_tool/package_config.json` | ✅ resolved (106 packages) |
| Emulator `YK_-_Pixel_9_Pro` | ✅ AVD exists (`android-36.1`, `x86_64`, `google_apis_playstore`); reaches WHPX and boots the guest. **Not currently running** — start it with step 1. |

## Step 1 — boot the emulator (separate terminal, leave it running)

`YK_-_Pixel_9_Pro` is an **AVD name**, not a device id. It only appears to
`flutter devices` *after* the emulator is running. `flutter run -d YK_-_Pixel_9_Pro`
on its own fails with `No supported devices found with name or id matching`, and
`adb devices` stays empty — that is expected, not a bug.

```sh
emulator -avd YK_-_Pixel_9_Pro
```

If `emulator` is not on your `PATH`:

```sh
"$LOCALAPPDATA/Android/Sdk/emulator/emulator.exe" -avd YK_-_Pixel_9_Pro
```

Or let Flutter launch it for you:

```sh
flutter emulators                 # lists AVDs
flutter emulators --launch YK_-_Pixel_9_Pro
```

## Step 2 — wait for boot (second terminal)

```sh
adb wait-for-device
adb shell getprop sys.boot_completed   # poll until it prints 1
flutter devices                        # now shows emulator-5554
```

## Step 3 — generate and run

```sh
cd ~/AndroidStudioProjects/ledgerly

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # the missing .g.dart files
flutter gen-l10n                                           # idempotent; already up to date
flutter run -d emulator-5554
```

Use `emulator-5554` (or omit `-d` entirely and pick from the list) — the AVD name
also works once it is running, but the device id is unambiguous.

`./scripts/codegen.sh` now does the middle two in one step.

## If `build_runner` reports errors in `lib/core/database/`

That is the expected first-run risk, and the reason the Drift roadmap item is still
`◐` rather than `☑` (`docs/Roadmap.md`). `drift_dev` has never validated the
`@TableIndex` / `@DriftDatabase` / `@DriftAccessor` annotations. The table and DAO
signatures were checked against a hand-written replica of the generated code, and
the emitted SQL was asserted textually, but the analyzer has not seen the real
generated output. Send me the output and I will fix it.

## Before committing

```sh
dart format --output=none --set-exit-if-changed .   # clean as of this handoff
flutter analyze --fatal-infos --fatal-warnings      # zero-warning policy
flutter test                                        # 4 suites need the .g.dart files
```

CI now runs a `codegen-check` job before `analyze` and `test`, so a stale or
missing generated file fails the build instead of silently shipping.
