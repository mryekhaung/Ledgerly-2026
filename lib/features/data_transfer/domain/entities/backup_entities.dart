/// Strategy to use when restoring a backup into an existing database.
enum RestoreMode {
  /// Appends missing categories, settings, and transactions without destroying existing data.
  merge,

  /// Completely wipes current categories and transactions, replacing them with the backup data.
  overwrite,
}

/// Metadata header for a Ledgerly backup archive.
class BackupMetadata {
  const BackupMetadata({
    required this.version,
    required this.exportedAtUtcMillis,
    required this.appVersion,
    required this.categoryCount,
    required this.transactionCount,
  });

  final int version;
  final int exportedAtUtcMillis;
  final String appVersion;
  final int categoryCount;
  final int transactionCount;
}

/// Result returned after restoring a backup.
class RestoreResult {
  const RestoreResult({
    required this.categoriesRestored,
    required this.transactionsRestored,
    required this.settingsRestored,
    required this.mode,
  });

  final int categoriesRestored;
  final int transactionsRestored;
  final int settingsRestored;
  final RestoreMode mode;
}
