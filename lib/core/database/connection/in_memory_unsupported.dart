import 'package:drift/drift.dart';

/// Fallback for `openInMemory()` when neither `dart:io` nor a native SQLite
/// binding is available — in practice, the web build.
///
/// A conditional import needs a default branch to be valid, so this file exists
/// to make `database_connection.dart` compile everywhere. It throws rather than
/// returning a broken executor: needing an in-memory database on web is a
/// programming error, and a clear failure beats a confusing query error later.
///
/// Never reached in CI — tests run on the Dart VM and select `in_memory_native`.
QueryExecutor openInMemory() => throw UnsupportedError(
  'An in-memory Drift database requires a native SQLite binding and is not '
  'available on web. Use openOnDeviceDatabase() for the web/WASM path.',
);
