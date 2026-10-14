/// Export format options for data transfer.
enum ExportFormat {
  csv,
  json;

  String get fileExtension => this == ExportFormat.csv ? 'csv' : 'json';

  String get mimeType =>
      this == ExportFormat.csv ? 'text/csv' : 'application/json';
}

/// Predefined date range presets for exporting transactions.
enum ExportRangePreset { thisPeriod, lastPeriod, allTime, custom }

/// Filter configuration for transaction export.
class ExportFilter {
  const ExportFilter({
    this.rangePreset = ExportRangePreset.thisPeriod,
    this.format = ExportFormat.csv,
    this.customStartDate,
    this.customEndDate,
    this.categoryIds,
  });

  final ExportRangePreset rangePreset;
  final ExportFormat format;
  final int? customStartDate; // packed LocalDate yyyyMMdd
  final int? customEndDate; // packed LocalDate yyyyMMdd
  final List<String>? categoryIds;

  ExportFilter copyWith({
    ExportRangePreset? rangePreset,
    ExportFormat? format,
    int? customStartDate,
    int? customEndDate,
    List<String>? categoryIds,
  }) {
    return ExportFilter(
      rangePreset: rangePreset ?? this.rangePreset,
      format: format ?? this.format,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}

/// Result payload containing the exported data and metadata.
class ExportData {
  const ExportData({
    required this.content,
    required this.format,
    required this.filename,
    required this.recordCount,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.currencyCode,
  });

  final String content;
  final ExportFormat format;
  final String filename;
  final int recordCount;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final String currencyCode;
}
