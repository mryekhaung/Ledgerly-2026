import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/uuid.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/data_transfer/data/json/backup_json_codec.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';

/// Local data source performing SQLite operations for data transfer.
class DataTransferLocalDataSource {
  DataTransferLocalDataSource({
    required this.db,
    this.clock = const Clock(),
    this.jsonCodec = const BackupJsonCodec(),
  });

  final AppDatabase db;
  final Clock clock;
  final BackupJsonCodec jsonCodec;

  /// Fetches active categories.
  Future<List<Category>> getActiveCategories() {
    return (db.select(db.categories)..where((c) => c.deletedAt.isNull())).get();
  }

  /// Fetches transactions matching [filter] for export.
  Future<List<Transaction>> getTransactionsForExport(
    ExportFilter filter,
  ) async {
    final query = db.select(db.transactions)
      ..where((t) {
        Expression<bool> predicate = t.deletedAt.isNull();

        if (filter.customStartDate != null) {
          predicate =
              predicate & t.date.isBiggerOrEqualValue(filter.customStartDate!);
        }
        if (filter.customEndDate != null) {
          predicate =
              predicate & t.date.isSmallerOrEqualValue(filter.customEndDate!);
        }
        if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
          predicate = predicate & t.categoryId.isIn(filter.categoryIds!);
        }

        return predicate;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return query.get();
  }

  /// Executes an import in a single atomic database transaction.
  Future<ImportResult> executeImport({
    required ImportPreview preview,
    required ImportOptions options,
  }) async {
    return db.transaction(() async {
      final existingCategories = await getActiveCategories();
      final categoryNameToId = <String, String>{
        for (final c in existingCategories) c.name.toLowerCase(): c.id,
      };

      var createdCategoriesCount = 0;
      var importedCount = 0;
      var skippedDuplicatesCount = 0;

      final now = clock.nowUtcMillis();

      for (final row in preview.rows) {
        if (!row.isValid) continue;

        if (row.isDuplicate && options.skipDuplicates) {
          skippedDuplicatesCount++;
          continue;
        }

        final targetCategoryName =
            (row.categoryName != null && row.categoryName!.trim().isNotEmpty)
            ? row.categoryName!.trim()
            : options.defaultCategoryName;

        var categoryId = categoryNameToId[targetCategoryName.toLowerCase()];

        if (categoryId == null) {
          if (options.autoCreateCategories) {
            categoryId = await db.categoriesDao.insert(
              name: targetCategoryName,
              iconKey: targetCategoryName == options.defaultCategoryName
                  ? 'folder'
                  : 'tag',
              colorValue: 0xFF4A90E2,
              kind: row.direction ?? 'expense',
              nowUtcMillis: now,
            );
            categoryNameToId[targetCategoryName.toLowerCase()] = categoryId;
            createdCategoriesCount++;
          } else {
            categoryId = existingCategories.isNotEmpty
                ? existingCategories.first.id
                : null;
          }
        }

        if (categoryId == null) continue;

        final date = row.date != null
            ? LocalDate.fromPacked(row.date!) ??
                  LocalDate.fromDateTime(DateTime.now())
            : LocalDate.fromDateTime(DateTime.now());

        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: Value(generateUuid()),
                categoryId: categoryId,
                amountMinor: row.amountMinor ?? 0,
                currency: (row.currency ?? options.defaultCurrency)
                    .toLowerCase(),
                direction: row.direction ?? 'expense',
                date: date,
                note: Value(row.note),
                createdAt: now,
                updatedAt: now,
              ),
            );

        importedCount++;
      }

      return ImportResult(
        importedCount: importedCount,
        skippedDuplicatesCount: skippedDuplicatesCount,
        createdCategoriesCount: createdCategoriesCount,
      );
    });
  }

  /// Exports full database snapshot to a JSON backup string.
  Future<String> createFullBackupPayload() async {
    final settings = await db.appSettingsDao.readAll();
    final categories = await db.select(db.categories).get();
    final transactions = await db.select(db.transactions).get();

    final categoriesJson = categories
        .map(
          (c) => <String, dynamic>{
            'id': c.id,
            'name': c.name,
            'iconKey': c.iconKey,
            'colorValue': c.colorValue,
            'kind': c.kind,
            'sortOrder': c.sortOrder,
            'isDefault': c.isDefault,
            'isArchived': c.isArchived,
            'createdAt': c.createdAt,
            'updatedAt': c.updatedAt,
            'deletedAt': c.deletedAt,
          },
        )
        .toList();

    final transactionsJson = transactions
        .map(
          (t) => <String, dynamic>{
            'id': t.id,
            'categoryId': t.categoryId,
            'accountId': t.accountId,
            'amountMinor': t.amountMinor,
            'currency': t.currency,
            'direction': t.direction,
            'date': t.date.value,
            'note': t.note,
            'createdAt': t.createdAt,
            'updatedAt': t.updatedAt,
            'deletedAt': t.deletedAt,
          },
        )
        .toList();

    return jsonCodec.encode(
      settings: settings,
      categories: categoriesJson,
      transactions: transactionsJson,
      exportedAtUtcMillis: clock.nowUtcMillis(),
    );
  }

  /// Restores a full backup from parsed JSON object.
  Future<RestoreResult> restoreFullBackup(
    Map<String, dynamic> backupData,
    RestoreMode mode,
  ) async {
    return db.transaction(() async {
      if (mode == RestoreMode.overwrite) {
        await db.delete(db.transactions).go();
        await db.delete(db.categories).go();
        await db.delete(db.appSettings).go();
      }

      var settingsRestored = 0;
      var categoriesRestored = 0;
      var transactionsRestored = 0;

      // Restore settings
      final settings = backupData['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        for (final entry in settings.entries) {
          await db.appSettingsDao.put(
            key: entry.key,
            value: entry.value.toString(),
          );
          settingsRestored++;
        }
      }

      // Restore categories
      final categoriesList = backupData['categories'] as List<dynamic>?;
      if (categoriesList != null) {
        for (final item in categoriesList) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id'] as String?;
          final name = item['name'] as String?;
          final iconKey = item['iconKey'] as String? ?? 'tag';
          final colorValue = item['colorValue'] as int? ?? 0xFF4A90E2;
          final kind = item['kind'] as String? ?? 'expense';
          final sortOrder = item['sortOrder'] as int? ?? 0;
          final isDefault = item['isDefault'] as bool? ?? false;
          final isArchived = item['isArchived'] as bool? ?? false;
          final createdAt = item['createdAt'] as int? ?? clock.nowUtcMillis();
          final updatedAt = item['updatedAt'] as int? ?? clock.nowUtcMillis();
          final deletedAt = item['deletedAt'] as int?;

          if (id == null || name == null) continue;

          await db
              .into(db.categories)
              .insertOnConflictUpdate(
                CategoriesCompanion(
                  id: Value(id),
                  name: Value(name),
                  iconKey: Value(iconKey),
                  colorValue: Value(colorValue),
                  kind: Value(kind),
                  sortOrder: Value(sortOrder),
                  isDefault: Value(isDefault),
                  isArchived: Value(isArchived),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                  deletedAt: Value(deletedAt),
                ),
              );
          categoriesRestored++;
        }
      }

      // Restore transactions
      final transactionsList = backupData['transactions'] as List<dynamic>?;
      if (transactionsList != null) {
        for (final item in transactionsList) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id'] as String?;
          final categoryId = item['categoryId'] as String?;
          final accountId = item['accountId'] as String?;
          final amountMinor = item['amountMinor'] as int? ?? 0;
          final currency = item['currency'] as String? ?? 'mmk';
          final direction = item['direction'] as String? ?? 'expense';
          final dateVal = item['date'] as int?;
          final note = item['note'] as String?;
          final createdAt = item['createdAt'] as int? ?? clock.nowUtcMillis();
          final updatedAt = item['updatedAt'] as int? ?? clock.nowUtcMillis();
          final deletedAt = item['deletedAt'] as int?;

          if (id == null || categoryId == null || dateVal == null) continue;
          final localDate =
              LocalDate.fromPacked(dateVal) ??
              LocalDate.fromDateTime(DateTime.now());

          await db
              .into(db.transactions)
              .insertOnConflictUpdate(
                TransactionsCompanion(
                  id: Value(id),
                  categoryId: Value(categoryId),
                  accountId: Value(accountId),
                  amountMinor: Value(amountMinor),
                  currency: Value(currency.toLowerCase()),
                  direction: Value(direction),
                  date: Value(localDate),
                  note: Value(note),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                  deletedAt: Value(deletedAt),
                ),
              );
          transactionsRestored++;
        }
      }

      return RestoreResult(
        categoriesRestored: categoriesRestored,
        transactionsRestored: transactionsRestored,
        settingsRestored: settingsRestored,
        mode: mode,
      );
    });
  }
}
