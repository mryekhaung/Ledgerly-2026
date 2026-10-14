/// Engine to detect duplicate transactions when importing from CSV or JSON.
class DeduplicationEngine {
  DeduplicationEngine();

  final Set<String> _existingSignatures = <String>{};

  /// Registers an existing transaction into the duplicate index.
  void registerExisting({
    required int date, // packed LocalDate yyyyMMdd
    required int amountMinor,
    required String currency,
    required String direction,
    String? categoryName,
    String? note,
  }) {
    _existingSignatures.add(
      computeSignature(
        date: date,
        amountMinor: amountMinor,
        currency: currency,
        direction: direction,
        categoryName: categoryName,
        note: note,
      ),
    );
  }

  /// Checks if the given transaction matches an existing or previously registered transaction.
  bool isDuplicate({
    required int date,
    required int amountMinor,
    required String currency,
    required String direction,
    String? categoryName,
    String? note,
  }) {
    final sig = computeSignature(
      date: date,
      amountMinor: amountMinor,
      currency: currency,
      direction: direction,
      categoryName: categoryName,
      note: note,
    );
    return _existingSignatures.contains(sig);
  }

  /// Registers an imported transaction so subsequent rows in the same import file
  /// that are duplicates of it will also be detected.
  void registerImported({
    required int date,
    required int amountMinor,
    required String currency,
    required String direction,
    String? categoryName,
    String? note,
  }) {
    registerExisting(
      date: date,
      amountMinor: amountMinor,
      currency: currency,
      direction: direction,
      categoryName: categoryName,
      note: note,
    );
  }

  /// Computes a normalized canonical string signature for a transaction.
  static String computeSignature({
    required int date,
    required int amountMinor,
    required String currency,
    required String direction,
    String? categoryName,
    String? note,
  }) {
    final cleanCategory = (categoryName ?? '').trim().toLowerCase();
    final cleanNote = (note ?? '').trim().toLowerCase();
    return '$date|$amountMinor|${currency.trim().toLowerCase()}|${direction.trim().toLowerCase()}|$cleanCategory|$cleanNote';
  }
}
