import 'dart:convert';

import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/data_transfer/data/csv/csv_codec.dart';
import 'package:ledgerly/features/data_transfer/data/datasources/data_transfer_local_datasource.dart';
import 'package:ledgerly/features/data_transfer/data/deduplication/deduplication_engine.dart';
import 'package:ledgerly/features/data_transfer/data/json/backup_json_codec.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/backup_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/export_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/entities/import_entities.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';

/// Implementation of [DataTransferRepository].
class DataTransferRepositoryImpl implements DataTransferRepository {
  const DataTransferRepositoryImpl(
    this._local, {
    this.csvCodec = const CsvCodec(),
    this.backupJsonCodec = const BackupJsonCodec(),
  });

  final DataTransferLocalDataSource _local;
  final CsvCodec csvCodec;
  final BackupJsonCodec backupJsonCodec;

  @override
  Future<Result<ExportData>> exportTransactions(ExportFilter filter) =>
      guardResult(() async {
        final categories = await _local.getActiveCategories();
        final categoryIdToName = <String, String>{
          for (final c in categories) c.id: c.name,
        };

        final transactions = await _local.getTransactionsForExport(filter);

        var totalIncome = 0;
        var totalExpense = 0;
        var defaultCurrency = 'MMK';

        if (transactions.isNotEmpty) {
          defaultCurrency = transactions.first.currency.toUpperCase();
        }

        for (final t in transactions) {
          if (t.direction.toLowerCase() == 'income') {
            totalIncome += t.amountMinor;
          } else {
            totalExpense += t.amountMinor;
          }
        }

        final nowStr = LocalDate.fromDateTime(DateTime.now())
            .toString()
            .replaceAll('-', '');
        final filename =
            'ledgerly_export_$nowStr.${filter.format.fileExtension}';

        String content;

        if (filter.format == ExportFormat.csv) {
          final table = <List<String>>[
            ['Date', 'Category', 'Amount', 'Currency', 'Direction', 'Note'],
          ];

          for (final t in transactions) {
            final catName = categoryIdToName[t.categoryId] ?? 'General';
            final amountDec = _formatAmountDecimal(t.amountMinor, t.currency);
            table.add([
              t.date.toString(),
              catName,
              amountDec,
              t.currency.toUpperCase(),
              t.direction,
              t.note ?? '',
            ]);
          }

          content = csvCodec.encode(table);
        } else {
          final list = transactions.map((t) {
            final catName = categoryIdToName[t.categoryId] ?? 'General';
            return <String, dynamic>{
              'id': t.id,
              'date': t.date.toString(),
              'category': catName,
              'amountMinor': t.amountMinor,
              'amount': _formatAmountDecimal(t.amountMinor, t.currency),
              'currency': t.currency.toUpperCase(),
              'direction': t.direction,
              'note': t.note ?? '',
            };
          }).toList();

          content = const JsonEncoder.withIndent('  ').convert(list);
        }

        return ExportData(
          content: content,
          format: filter.format,
          filename: filename,
          recordCount: transactions.length,
          totalIncomeMinor: totalIncome,
          totalExpenseMinor: totalExpense,
          currencyCode: defaultCurrency,
        );
      });

  @override
  Future<Result<ImportPreview>> parseImportData({
    required String content,
    required ImportFormat format,
    ImportColumnMapping? customMapping,
  }) => guardResult(() async {
    final existingCategories = await _local.getActiveCategories();
    final existingCategoryNames = existingCategories
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    final recentTxns = await _local.getTransactionsForExport(
      const ExportFilter(rangePreset: ExportRangePreset.allTime),
    );

    final catIdToName = <String, String>{
      for (final c in existingCategories) c.id: c.name,
    };

    final deduplicationEngine = DeduplicationEngine();
    for (final t in recentTxns) {
      deduplicationEngine.registerExisting(
        date: t.date.value,
        amountMinor: t.amountMinor,
        currency: t.currency,
        direction: t.direction,
        categoryName: catIdToName[t.categoryId],
        note: t.note,
      );
    }

    if (format == ImportFormat.csv) {
      return _parseCsv(
        content: content,
        existingCategoryNames: existingCategoryNames,
        deduplicationEngine: deduplicationEngine,
        customMapping: customMapping,
      );
    } else {
      return _parseJson(
        content: content,
        existingCategoryNames: existingCategoryNames,
        deduplicationEngine: deduplicationEngine,
      );
    }
  });

  @override
  Future<Result<ImportResult>> executeImport({
    required ImportPreview preview,
    required ImportOptions options,
  }) => guardResult(() async {
    return _local.executeImport(preview: preview, options: options);
  });

  @override
  Future<Result<String>> createFullBackup() => guardResult(() async {
    return _local.createFullBackupPayload();
  });

  @override
  Future<Result<RestoreResult>> restoreFullBackup({
    required String backupJson,
    required RestoreMode mode,
  }) => guardResult(() async {
    final decoded = backupJsonCodec.decode(backupJson);
    return _local.restoreFullBackup(decoded, mode);
  });

  ImportPreview _parseCsv({
    required String content,
    required Set<String> existingCategoryNames,
    required DeduplicationEngine deduplicationEngine,
    ImportColumnMapping? customMapping,
  }) {
    final rawRows = csvCodec.decode(content);
    if (rawRows.isEmpty) {
      return const ImportPreview(
        format: ImportFormat.csv,
        headers: [],
        rows: [],
        mapping: ImportColumnMapping({}),
        newCategoryNames: [],
      );
    }

    final headers = rawRows.first;
    final mapping = customMapping ?? _inferColumnMapping(headers);

    final parsedRows = <ParsedImportRow>[];
    final newCategoryNames = <String>{};

    for (var r = 1; r < rawRows.length; r++) {
      final cells = rawRows[r];
      if (cells.every((c) => c.trim().isEmpty)) continue;

      int? dateVal;
      String? categoryName;
      int? amountMinor;
      String? currency;
      String? direction;
      String? note;

      for (var col = 0; col < cells.length; col++) {
        final fieldType = mapping.getField(col);
        final cellVal = cells[col].trim();
        if (cellVal.isEmpty) continue;

        switch (fieldType) {
          case ImportFieldType.date:
            dateVal = _parseDateString(cellVal);
            break;
          case ImportFieldType.category:
            categoryName = cellVal;
            break;
          case ImportFieldType.amount:
            amountMinor = _parseAmountString(cellVal);
            break;
          case ImportFieldType.currency:
            currency = cellVal.toUpperCase();
            break;
          case ImportFieldType.direction:
            direction = _parseDirection(cellVal);
            break;
          case ImportFieldType.note:
            note = cellVal;
            break;
          case ImportFieldType.ignore:
            break;
        }
      }

      direction ??= 'expense';
      currency ??= 'MMK';

      final isValid = dateVal != null && amountMinor != null && amountMinor > 0;
      final errorMessage = !isValid
          ? (dateVal == null ? 'Invalid date' : 'Invalid amount')
          : null;

      final isDup =
          isValid &&
          deduplicationEngine.isDuplicate(
            date: dateVal,
            amountMinor: amountMinor,
            currency: currency,
            direction: direction,
            categoryName: categoryName,
            note: note,
          );

      if (isValid && !isDup) {
        deduplicationEngine.registerImported(
          date: dateVal,
          amountMinor: amountMinor,
          currency: currency,
          direction: direction,
          categoryName: categoryName,
          note: note,
        );

        if (categoryName != null &&
            categoryName.isNotEmpty &&
            !existingCategoryNames.contains(categoryName.toLowerCase())) {
          newCategoryNames.add(categoryName);
        }
      }

      parsedRows.add(
        ParsedImportRow(
          rowIndex: r,
          rawValues: cells,
          date: dateVal,
          categoryName: categoryName,
          amountMinor: amountMinor,
          currency: currency,
          direction: direction,
          note: note,
          isValid: isValid,
          errorMessage: errorMessage,
          isDuplicate: isDup,
        ),
      );
    }

    return ImportPreview(
      format: ImportFormat.csv,
      headers: headers,
      rows: parsedRows,
      mapping: mapping,
      newCategoryNames: newCategoryNames.toList(),
    );
  }

  ImportPreview _parseJson({
    required String content,
    required Set<String> existingCategoryNames,
    required DeduplicationEngine deduplicationEngine,
  }) {
    final dynamic decoded = jsonDecode(content);
    List<dynamic> items;

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['transactions'] is List) {
      items = decoded['transactions'] as List;
    } else {
      throw const FormatException('Expected JSON array of transactions');
    }

    final parsedRows = <ParsedImportRow>[];
    final newCategoryNames = <String>{};

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map<String, dynamic>) continue;

      final dateStr = item['date']?.toString();
      final dateVal = dateStr != null ? _parseDateString(dateStr) : null;
      final categoryName = item['category']?.toString();
      final amountVal = item['amount'] ?? item['amountMinor'];
      final amountMinor = _parseAmountString(amountVal?.toString() ?? '');
      final currency = item['currency']?.toString().toUpperCase() ?? 'MMK';
      final direction = _parseDirection(item['direction']?.toString() ?? '');
      final note = item['note']?.toString();

      final isValid = dateVal != null && amountMinor != null && amountMinor > 0;
      final isDup =
          isValid &&
          deduplicationEngine.isDuplicate(
            date: dateVal,
            amountMinor: amountMinor,
            currency: currency,
            direction: direction,
            categoryName: categoryName,
            note: note,
          );

      if (isValid && !isDup) {
        deduplicationEngine.registerImported(
          date: dateVal,
          amountMinor: amountMinor,
          currency: currency,
          direction: direction,
          categoryName: categoryName,
          note: note,
        );

        if (categoryName != null &&
            categoryName.isNotEmpty &&
            !existingCategoryNames.contains(categoryName.toLowerCase())) {
          newCategoryNames.add(categoryName);
        }
      }

      parsedRows.add(
        ParsedImportRow(
          rowIndex: i + 1,
          rawValues: [
            dateStr ?? '',
            categoryName ?? '',
            amountVal?.toString() ?? '',
            currency,
            direction,
            note ?? '',
          ],
          date: dateVal,
          categoryName: categoryName,
          amountMinor: amountMinor,
          currency: currency,
          direction: direction,
          note: note,
          isValid: isValid,
          isDuplicate: isDup,
        ),
      );
    }

    return ImportPreview(
      format: ImportFormat.json,
      headers: const [
        'Date',
        'Category',
        'Amount',
        'Currency',
        'Direction',
        'Note',
      ],
      rows: parsedRows,
      mapping: const ImportColumnMapping({
        0: ImportFieldType.date,
        1: ImportFieldType.category,
        2: ImportFieldType.amount,
        3: ImportFieldType.currency,
        4: ImportFieldType.direction,
        5: ImportFieldType.note,
      }),
      newCategoryNames: newCategoryNames.toList(),
    );
  }

  ImportColumnMapping _inferColumnMapping(List<String> headers) {
    final map = <int, ImportFieldType>{};

    for (var col = 0; col < headers.length; col++) {
      final header = headers[col].trim().toLowerCase();
      if (header.contains('date') ||
          header.contains('day') ||
          header == 'time') {
        map[col] = ImportFieldType.date;
      } else if (header.contains('cat') ||
          header == 'tag' ||
          header == 'group') {
        map[col] = ImportFieldType.category;
      } else if (header.contains('amount') ||
          header.contains('price') ||
          header.contains('cost') ||
          header == 'sum') {
        map[col] = ImportFieldType.amount;
      } else if (header.contains('curr')) {
        map[col] = ImportFieldType.currency;
      } else if (header.contains('direct') ||
          header == 'type' ||
          header == 'kind') {
        map[col] = ImportFieldType.direction;
      } else if (header.contains('note') ||
          header.contains('memo') ||
          header.contains('desc') ||
          header.contains('remark')) {
        map[col] = ImportFieldType.note;
      } else {
        map[col] = ImportFieldType.ignore;
      }
    }

    return ImportColumnMapping(map);
  }

  String _formatAmountDecimal(int amountMinor, String currencyStr) {
    final code = CurrencyCode.tryParse(currencyStr) ?? CurrencyCode.mmk;
    if (code.exponent == 0) {
      return amountMinor.toString();
    }
    final factor = _pow10(code.exponent);
    final major = amountMinor ~/ factor;
    final minor = amountMinor % factor;
    return '$major.${minor.toString().padLeft(code.exponent, '0')}';
  }

  int _pow10(int exp) {
    var result = 1;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  int? _parseDateString(String value) {
    final clean = value.replaceAll('/', '-').replaceAll('.', '-').trim();
    // Check if it's already packed yyyyMMdd integer
    if (clean.length == 8 && int.tryParse(clean) != null) {
      return int.parse(clean);
    }
    final parts = clean.split('-');
    if (parts.length == 3) {
      int? year;
      int? month;
      int? day;

      if (parts[0].length == 4) {
        year = int.tryParse(parts[0]);
        month = int.tryParse(parts[1]);
        day = int.tryParse(parts[2]);
      } else if (parts[2].length == 4) {
        day = int.tryParse(parts[0]);
        month = int.tryParse(parts[1]);
        year = int.tryParse(parts[2]);
      }

      if (year != null &&
          month != null &&
          day != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return year * 10000 + month * 100 + day;
      }
    }
    return null;
  }

  int? _parseAmountString(String value) {
    final clean = value
        .replaceAll(',', '')
        .replaceAll('\$', '')
        .replaceAll('K', '')
        .replaceAll('MMK', '')
        .trim();
    if (clean.isEmpty) return null;

    final parts = clean.split('.');
    if (parts.length == 1) {
      final numVal = int.tryParse(parts[0]);
      if (numVal != null) {
        // Multiply by 100 as minor unit baseline
        return numVal * 100;
      }
    } else if (parts.length == 2) {
      final major = int.tryParse(parts[0]);
      if (major != null) {
        var minorStr = parts[1];
        if (minorStr.length == 1) minorStr = '${minorStr}0';
        if (minorStr.length > 2) minorStr = minorStr.substring(0, 2);
        final minor = int.tryParse(minorStr) ?? 0;
        return major * 100 + minor;
      }
    }
    return null;
  }

  String _parseDirection(String value) {
    final clean = value.trim().toLowerCase();
    if (clean.contains('in') ||
        clean.contains('income') ||
        clean.contains('deposit')) {
      return 'income';
    }
    return 'expense';
  }
}
