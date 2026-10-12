import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Native implementation of `openInMemory()` for `database_connection.dart`.
///
/// Selected when `dart:io` is available (iOS, Android, desktop, and the Dart VM
/// that runs tests). Web resolves `in_memory_unsupported.dart` instead, because
/// the web build has no `NativeDatabase`.
///
/// `NativeDatabase.memory()` is a private, on-heap SQLite instance — nothing is
/// written to disk, so a test cannot leak state into the next run.
QueryExecutor openInMemory() => NativeDatabase.memory();
