import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_frequency.dart';
import 'package:ledgerly/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:ledgerly/features/recurring/domain/validators/recurring_validators.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

void main() {
  group('RecurringFrequency', () {
    test('fromString parses correctly or defaults to monthly', () {
      expect(RecurringFrequency.fromString('daily'), RecurringFrequency.daily);
      expect(
        RecurringFrequency.fromString('WEEKLY'),
        RecurringFrequency.weekly,
      );
      expect(
        RecurringFrequency.fromString('monthly'),
        RecurringFrequency.monthly,
      );
      expect(
        RecurringFrequency.fromString('yearly'),
        RecurringFrequency.yearly,
      );
      expect(
        RecurringFrequency.fromString('unknown'),
        RecurringFrequency.monthly,
      );
    });

    test('daily adds 1 day', () {
      final start = LocalDate(2026, 10, 15);
      expect(RecurringFrequency.daily.nextDate(start), LocalDate(2026, 10, 16));
    });

    test('weekly adds 7 days', () {
      final start = LocalDate(2026, 10, 15);
      expect(
        RecurringFrequency.weekly.nextDate(start),
        LocalDate(2026, 10, 22),
      );
    });

    test('monthly adds 1 month with end of month clamping', () {
      final jan31 = LocalDate(2026, 1, 31);
      final feb = RecurringFrequency.monthly.nextDate(jan31);
      expect(feb, LocalDate(2026, 2, 28));

      final oct15 = LocalDate(2026, 10, 15);
      expect(
        RecurringFrequency.monthly.nextDate(oct15),
        LocalDate(2026, 11, 15),
      );
    });

    test('yearly adds 12 months', () {
      final date = LocalDate(2026, 10, 15);
      expect(RecurringFrequency.yearly.nextDate(date), LocalDate(2027, 10, 15));
    });
  });

  group('RecurringTransaction', () {
    final recurring = RecurringTransaction(
      id: 'rec-1',
      categoryId: 'cat-rent',
      amount: const Money.minor(500000, CurrencyCode.mmk),
      direction: TransactionDirection.expense,
      frequency: RecurringFrequency.monthly,
      startDate: LocalDate(2026, 10, 1),
      nextDueDate: LocalDate(2026, 11, 1),
      endDate: LocalDate(2027, 10, 1),
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('isDue evaluates correctly', () {
      expect(recurring.isDue(LocalDate(2026, 10, 31)), isFalse);
      expect(recurring.isDue(LocalDate(2026, 11, 1)), isTrue);
      expect(recurring.isDue(LocalDate(2026, 11, 5)), isTrue);

      final archived = recurring.copyWith(isArchived: true);
      expect(archived.isDue(LocalDate(2026, 11, 1)), isFalse);

      final deleted = recurring.copyWith(deletedAt: 2000);
      expect(deleted.isDue(LocalDate(2026, 11, 1)), isFalse);
    });

    test('isExpired checks endDate', () {
      expect(recurring.isExpired(LocalDate(2026, 12, 1)), isFalse);
      expect(recurring.isExpired(LocalDate(2027, 10, 2)), isTrue);

      final noEndDate = recurring.copyWith(clearEndDate: true);
      expect(noEndDate.isExpired(LocalDate(2030, 1, 1)), isFalse);
    });

    test('copyWith updates fields correctly', () {
      final updated = recurring.copyWith(
        amount: const Money.minor(600000, CurrencyCode.mmk),
        nextDueDate: LocalDate(2026, 12, 1),
        isArchived: true,
      );

      expect(updated.amountMinor, 600000);
      expect(updated.nextDueDate, LocalDate(2026, 12, 1));
      expect(updated.isArchived, isTrue);
      expect(updated.id, 'rec-1');
    });

    test('equality and hashCode', () {
      final copy = recurring.copyWith();
      expect(recurring, copy);
      expect(recurring.hashCode, copy.hashCode);
    });
  });

  group('RecurringValidators', () {
    test('validates amount strictly positive', () {
      expect(RecurringValidators.validateAmount(null), isNotNull);
      expect(RecurringValidators.validateAmount(0), isNotNull);
      expect(RecurringValidators.validateAmount(-100), isNotNull);
      expect(RecurringValidators.validateAmount(500), isNull);
    });

    test('validates category non-empty', () {
      expect(RecurringValidators.validateCategory(null), isNotNull);
      expect(RecurringValidators.validateCategory(''), isNotNull);
      expect(RecurringValidators.validateCategory('  '), isNotNull);
      expect(RecurringValidators.validateCategory('cat-1'), isNull);
    });

    test('validates endDate >= startDate', () {
      final start = LocalDate(2026, 10, 1);
      final before = LocalDate(2026, 9, 30);
      final same = LocalDate(2026, 10, 1);
      final after = LocalDate(2026, 10, 2);

      expect(RecurringValidators.validateDates(start, null), isNull);
      expect(RecurringValidators.validateDates(start, after), isNull);
      expect(RecurringValidators.validateDates(start, same), isNull);
      expect(RecurringValidators.validateDates(start, before), isNotNull);
    });
  });
}
