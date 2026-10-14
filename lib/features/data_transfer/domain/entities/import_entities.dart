/// Format of imported data.
enum ImportFormat { csv, json }

/// The semantic field an imported column maps to.
enum ImportFieldType {
  date,
  category,
  amount,
  currency,
  direction,
  note,
  ignore;

  String get label {
    switch (this) {
      case ImportFieldType.date:
        return 'Date';
      case ImportFieldType.category:
        return 'Category';
      case ImportFieldType.amount:
        return 'Amount';
      case ImportFieldType.currency:
        return 'Currency';
      case ImportFieldType.direction:
        return 'Direction';
      case ImportFieldType.note:
        return 'Note';
      case ImportFieldType.ignore:
        return 'Ignore';
    }
  }
}

/// Column mapping from CSV column index to [ImportFieldType].
class ImportColumnMapping {
  const ImportColumnMapping(this.indexToField);

  final Map<int, ImportFieldType> indexToField;

  ImportFieldType getField(int columnIndex) =>
      indexToField[columnIndex] ?? ImportFieldType.ignore;

  ImportColumnMapping withField(int columnIndex, ImportFieldType field) {
    final next = Map<int, ImportFieldType>.from(indexToField);
    next[columnIndex] = field;
    return ImportColumnMapping(next);
  }
}

/// Represents a single parsed row from an import file.
class ParsedImportRow {
  const ParsedImportRow({
    required this.rowIndex,
    required this.rawValues,
    this.date,
    this.categoryName,
    this.amountMinor,
    this.currency,
    this.direction,
    this.note,
    this.isValid = false,
    this.errorMessage,
    this.isDuplicate = false,
  });

  final int rowIndex;
  final List<String> rawValues;
  final int? date; // packed LocalDate yyyyMMdd
  final String? categoryName;
  final int? amountMinor;
  final String? currency;
  final String? direction; // 'expense' | 'income'
  final String? note;
  final bool isValid;
  final String? errorMessage;
  final bool isDuplicate;

  ParsedImportRow copyWith({
    int? rowIndex,
    List<String>? rawValues,
    int? date,
    String? categoryName,
    int? amountMinor,
    String? currency,
    String? direction,
    String? note,
    bool? isValid,
    String? errorMessage,
    bool? isDuplicate,
  }) {
    return ParsedImportRow(
      rowIndex: rowIndex ?? this.rowIndex,
      rawValues: rawValues ?? this.rawValues,
      date: date ?? this.date,
      categoryName: categoryName ?? this.categoryName,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      note: note ?? this.note,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }
}

/// High-level preview of what an import will do before writing to the database.
class ImportPreview {
  const ImportPreview({
    required this.format,
    required this.headers,
    required this.rows,
    required this.mapping,
    required this.newCategoryNames,
  });

  final ImportFormat format;
  final List<String> headers;
  final List<ParsedImportRow> rows;
  final ImportColumnMapping mapping;
  final List<String> newCategoryNames;

  int get totalRows => rows.length;
  int get validRows => rows.where((r) => r.isValid && !r.isDuplicate).length;
  int get duplicateRows => rows.where((r) => r.isDuplicate).length;
  int get invalidRows => rows.where((r) => !r.isValid).length;
}

/// User options when executing an import.
class ImportOptions {
  const ImportOptions({
    this.skipDuplicates = true,
    this.autoCreateCategories = true,
    this.defaultCurrency = 'MMK',
    this.defaultCategoryName = 'General',
  });

  final bool skipDuplicates;
  final bool autoCreateCategories;
  final String defaultCurrency;
  final String defaultCategoryName;

  ImportOptions copyWith({
    bool? skipDuplicates,
    bool? autoCreateCategories,
    String? defaultCurrency,
    String? defaultCategoryName,
  }) {
    return ImportOptions(
      skipDuplicates: skipDuplicates ?? this.skipDuplicates,
      autoCreateCategories: autoCreateCategories ?? this.autoCreateCategories,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultCategoryName: defaultCategoryName ?? this.defaultCategoryName,
    );
  }
}

/// Result summary after an import has been executed.
class ImportResult {
  const ImportResult({
    required this.importedCount,
    required this.skippedDuplicatesCount,
    required this.createdCategoriesCount,
  });

  final int importedCount;
  final int skippedDuplicatesCount;
  final int createdCategoriesCount;
}
