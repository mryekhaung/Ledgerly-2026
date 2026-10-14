import 'package:ledgerly/core/utils/local_date.dart';

/// Recurrence cadence for a recurring transaction rule.
enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get storageValue => name;

  static RecurringFrequency fromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (f) => f.name == value.toLowerCase().trim(),
      orElse: () => RecurringFrequency.monthly,
    );
  }

  /// Calculates the next scheduled occurrence after [current].
  LocalDate nextDate(LocalDate current) {
    switch (this) {
      case RecurringFrequency.daily:
        return current.addDays(1) ?? current;
      case RecurringFrequency.weekly:
        return current.addDays(7) ?? current;
      case RecurringFrequency.monthly:
        return current.addMonths(1) ?? current;
      case RecurringFrequency.yearly:
        return current.addMonths(12) ?? current;
    }
  }
}
