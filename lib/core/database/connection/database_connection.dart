import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'in_memory_unsupported.dart'
    if (dart.library.io) 'in_memory_native.dart'
    as platform;

/// Opens the on-device database file.
///
/// `drift_flutter`'s `driftDatabase` resolves the platform itself (native SQLite
/// on iOS/Android/desktop, WASM/IndexedDB on web) behind its own conditional
/// imports, so this wrapper adds no `dart:io` of our own and the web build keeps
/// working (`docs/Conventions.md` §1).
QueryExecutor openOnDeviceDatabase({String name = 'ledgerly'}) {
  return driftDatabase(name: name);
}

/// Opens a throwaway **in-memory** database — for DAO tests and the migration
/// harness.
///
/// In-memory means the schema is built from scratch on every open, so a test is
/// never polluted by a leftover file and `onCreate` always runs.
///
/// Native-only: it is behind a conditional import because the web build has no
/// `NativeDatabase`. The web variant throws a clear error rather than failing to
/// compile. Tests run on the Dart VM, so that branch never executes in CI.
///
/// Lives in `lib/` rather than `test/` so widget and integration tests share one
/// entry point and cannot drift apart.
QueryExecutor openInMemoryDatabase() => platform.openInMemory();
