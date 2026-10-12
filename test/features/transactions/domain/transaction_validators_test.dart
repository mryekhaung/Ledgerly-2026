import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/validators/transaction_validators.dart';

/// Transaction validation sits between a keypad and the ledger, so these tests
/// cover the amount boundary (zero, overflow, precision) as carefully as the
/// note normalisation that decides whether a row renders a second line.
void main() {
  Money mmk(int minor) => Money.minor(minor, CurrencyCode.mmk);

  group('TransactionValidators.amountError', () {
    test('should_report_zero_when_amount_is_zero', () {
      expect(
        TransactionValidators.amountError(mmk(0)),
        TransactionValidators.amountZero,
      );
    });

    test('should_accept_a_positive_amount', () {
      expect(TransactionValidators.amountError(mmk(1)), isNull);
    });

    test('should_report_too_large_when_digits_exceed_max', () {
      // One digit past the cap: `Money.maxDigits` keeps intermediates inside
      // ±2^53 on web, where `int` is a JS number.
      final digits = Money.maxDigits + 1;
      final overflow = int.parse('1' * digits);
      expect(
        TransactionValidators.amountError(mmk(overflow)),
        TransactionValidators.amountTooLarge,
      );
    });

    test('should_accept_an_amount_at_exactly_max_digits', () {
      final atCap = int.parse('1' * Money.maxDigits);
      expect(TransactionValidators.amountError(mmk(atCap)), isNull);
    });

    test('should_measure_the_magnitude_ignoring_sign', () {
      // `Money` may be negative (a keypad can hand one back), and the digit cap
      // is about magnitude, so the sign must not make a 15-digit value look
      // like a 16-digit one.
      final atCap = int.parse('1' * Money.maxDigits);
      expect(TransactionValidators.amountError(mmk(-atCap)), isNull);
    });
  });

  group('TransactionValidators.directionError', () {
    test('should_accept_expense_and_income', () {
      expect(
        TransactionValidators.directionError(TransactionDirection.expense),
        isNull,
      );
      expect(
        TransactionValidators.directionError(TransactionDirection.income),
        isNull,
      );
    });

    test('should_reject_transfer_when_v1_cannot_store_it', () {
      // `transfer` exists in the schema but has no v1 UI; letting it through
      // would write a row no screen can render or edit.
      expect(
        TransactionValidators.directionError(TransactionDirection.transfer),
        TransactionValidators.directionUnsupported,
      );
    });
  });

  group('TransactionValidators.categoryError', () {
    test('should_report_required_when_category_is_empty', () {
      expect(
        TransactionValidators.categoryError(''),
        TransactionValidators.categoryRequired,
      );
    });

    test('should_report_required_when_category_is_whitespace_only', () {
      expect(
        TransactionValidators.categoryError('   '),
        TransactionValidators.categoryRequired,
      );
    });

    test('should_accept_a_populated_category_id', () {
      expect(TransactionValidators.categoryError('cat-1'), isNull);
    });
  });

  group('TransactionValidators.noteError', () {
    test('should_accept_a_null_note', () {
      expect(TransactionValidators.noteError(null), isNull);
    });

    test('should_accept_a_note_at_exactly_max_length', () {
      final exact = 'a' * TransactionValidators.maxNoteLength;
      expect(TransactionValidators.noteError(exact), isNull);
    });

    test('should_report_too_long_when_the_trimmed_note_exceeds_max', () {
      final long = 'a' * (TransactionValidators.maxNoteLength + 1);
      expect(
        TransactionValidators.noteError(long),
        TransactionValidators.noteTooLong,
      );
    });

    test('should_not_count_surrounding_whitespace_toward_the_limit', () {
      // The stored value is trimmed, so the trimmed length is what the column
      // will actually hold.
      final padded = '  ${'a' * TransactionValidators.maxNoteLength}  ';
      expect(TransactionValidators.noteError(padded), isNull);
    });
  });

  group('TransactionValidators.normalizeNote', () {
    test('should_trim_surrounding_whitespace_when_present', () {
      expect(TransactionValidators.normalizeNote('  lunch  '), 'lunch');
    });

    test('should_map_blank_to_null_when_only_whitespace', () {
      // One "no note" state rather than two, so a row widget can decide whether
      // to render a second line at all.
      expect(TransactionValidators.normalizeNote('   '), isNull);
    });

    test('should_map_empty_to_null', () {
      expect(TransactionValidators.normalizeNote(''), isNull);
    });

    test('should_pass_null_through', () {
      expect(TransactionValidators.normalizeNote(null), isNull);
    });
  });

  group('TransactionValidators.draftError', () {
    final valid = (
      categoryId: 'cat-1',
      amount: mmk(1500),
      direction: TransactionDirection.expense,
      date: LocalDate(2026, 10, 3),
      note: null,
    );

    test('should_report_nothing_when_draft_is_valid', () {
      expect(TransactionValidators.draftError(valid), isNull);
    });

    test('should_report_the_amount_problem_first', () {
      // Form order: amount -> direction -> category -> note, so the topmost
      // problem is the one reported.
      expect(
        TransactionValidators.draftError((
          categoryId: '',
          amount: mmk(0),
          direction: TransactionDirection.transfer,
          date: LocalDate(2026, 10, 3),
          note: 'a' * 600,
        )),
        TransactionValidators.amountZero,
      );
    });

    test(
      'should_report_the_direction_problem_when_only_direction_is_wrong',
      () {
        expect(
          TransactionValidators.draftError((
            categoryId: 'cat-1',
            amount: mmk(100),
            direction: TransactionDirection.transfer,
            date: LocalDate(2026, 10, 3),
            note: null,
          )),
          TransactionValidators.directionUnsupported,
        );
      },
    );

    test('should_report_the_category_problem_when_only_category_is_wrong', () {
      expect(
        TransactionValidators.draftError((
          categoryId: '  ',
          amount: mmk(100),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 10, 3),
          note: null,
        )),
        TransactionValidators.categoryRequired,
      );
    });

    test('should_report_the_note_problem_when_only_note_is_wrong', () {
      expect(
        TransactionValidators.draftError((
          categoryId: 'cat-1',
          amount: mmk(100),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 10, 3),
          note: 'a' * (TransactionValidators.maxNoteLength + 1),
        )),
        TransactionValidators.noteTooLong,
      );
    });
  });

  group('TransactionValidators.isFuture', () {
    test('should_be_true_when_the_date_is_after_today', () {
      expect(
        TransactionValidators.isFuture(
          LocalDate(2026, 10, 5),
          today: LocalDate(2026, 10, 3),
        ),
        isTrue,
      );
    });

    test('should_be_false_when_the_date_is_today', () {
      expect(
        TransactionValidators.isFuture(
          LocalDate(2026, 10, 3),
          today: LocalDate(2026, 10, 3),
        ),
        isFalse,
      );
    });

    test('should_be_false_when_the_date_is_past', () {
      expect(
        TransactionValidators.isFuture(
          LocalDate(2026, 10, 1),
          today: LocalDate(2026, 10, 3),
        ),
        isFalse,
      );
    });
  });
}
