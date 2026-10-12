import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a UUIDv4 for a new row's primary key.
///
/// Passed to Drift's `clientDefault`, which runs in Dart rather than SQLite, so
/// the id is created on the device — the app can insert a full row while offline
/// and never needs a server round-trip to learn its own primary key
/// (`docs/Architecture.md` ADR #3).
///
/// A top-level function (not a closure) so Drift can reference it in generated
/// code without capturing state.
String generateUuid() => _uuid.v4();
