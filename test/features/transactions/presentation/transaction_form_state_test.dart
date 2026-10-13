import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/presentation/transaction_form_state.dart';

/// Tests for the transaction form's state and the draft it produces.
///
/// The buffer-to-draft path is where a currency or a sign could go wrong
/// silently, so it is pinned here rather than through the page.
void main() {
  TransactionFormState blank({
    CurrencyCode currency = CurrencyCode.mmk,
    TransactionDirection direction = TransactionDirection.expense,
  }) => TransactionFormState.blank(
    currency: currency,
    date: LocalDate(2026, 3, 14),
    direction: direction,
  );

  group('TransactionFormState.blank', () {
    test('should_start_with_an_empty_buffer_rather_than_a_zero', () {
      // A pre-filled `0` reads as a value the user chose; an empty buffer lets
      // the display show a placeholder instead.
      final state = blank();

      expect(state.entryBuffer, '');
      expect(state.hasEntry, isFalse);
      expect(state.amount, isNull);
      expect(state.draft, isNull);
    });

    test('should_default_to_expense', () {
      expect(blank().direction, TransactionDirection.expense);
    });
  });

  group('TransactionFormState.amount', () {
    test('should_parse_whole_units_for_a_zero_exponent_currency', () {
      final state = blank().copyWith(entryBuffer: '1250');

      expect(state.amount, const Money.minor(1250, CurrencyCode.mmk));
    });

    test('should_scale_minor_units_for_a_two_exponent_currency', () {
      // 12.50 USD is 1250 cents, not 12 cents — the parse must apply the
      // currency's exponent.
      final state = blank(currency: CurrencyCode.usd)
          .copyWith(entryBuffer: '12.50');

      expect(state.amount, const Money.minor(1250, CurrencyCode.usd));
      expect(state.amount!.amountMinor, 1250);
    });

    test('should_resolve_a_partially_typed_trailing_point', () {
      final state = blank(currency: CurrencyCode.usd)
          .copyWith(entryBuffer: '12.');

      expect(state.amount, const Money.minor(1200, CurrencyCode.usd));
    });

    test('should_treat_a_lone_zero_as_zero_not_null', () {
      final state = blank().copyWith(entryBuffer: '0');

      expect(state.amount, const Money.zero(CurrencyCode.mmk));
      expect(state.hasEntry, isTrue);
    });
  });

  group('TransactionFormState.draft', () {
    test('should_be_null_until_both_amount_and_category_are_present', () {
      final withAmount = blank().copyWith(
        entryBuffer: '1000',
        categoryId: null,
      );
      expect(withAmount.draft, isNull);

      final withCategoryOnly = blank().copyWith(categoryId: 'cat-1');
      expect(withCategoryOnly.draft, isNull);

      final complete = blank().copyWith(
        entryBuffer: '1000',
        categoryId: 'cat-1',
      );
      expect(complete.draft, isNotNull);
    });

    test('should_carry_the_currency_through_the_draft', () {
      final state = blank(currency: CurrencyCode.usd)
          .copyWith(entryBuffer: '12.50', categoryId: 'cat-1');

      expect(state.draft!.amount.currency, CurrencyCode.usd);
      expect(state.draft!.amount.amountMinor, 1250);
    });

    test('should_turn_a_blank_note_into_null', () {
      final state = blank().copyWith(
        entryBuffer: '1000',
        categoryId: 'cat-1',
        note: '   ',
      );

      expect(state.draft!.note, isNull, reason: 'whitespace is not a note');
    });

    test('should_trim_a_real_note', () {
      final state = blank().copyWith(
        entryBuffer: '1000',
        categoryId: 'cat-1',
        note: '  lunch  ',
      );

      expect(state.draft!.note, 'lunch');
    });

    test('should_keep_the_direction_from_the_form', () {
      final state = blank(direction: TransactionDirection.income)
          .copyWith(entryBuffer: '1000', categoryId: 'cat-1');

      expect(state.draft!.direction, TransactionDirection.income);
    });
  });

  group('TransactionFormState.copyWith', () {
    test('should_clear_field_errors_on_every_edit', () {
      // A stale "pick a category" must not survive the user picking one.
      final state = blank()
          .copyWith(fieldErrors: const <String, String>{'categoryId': 'x'})
          .copyWith(categoryId: 'cat-1');

      expect(state.fieldErrors, isEmpty);
    });

    test('should_keep_the_existing_id_across_edits', () {
      final state = TransactionFormState.from(
        Transaction(
          id: 'tx-9',
          categoryId: 'cat-1',
          amount: const Money.minor(500, CurrencyCode.mmk),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 3, 14),
          createdAt: 1,
          updatedAt: 1,
        ),
      ).copyWith(entryBuffer: '700');

      expect(state.existingId, 'tx-9');
      expect(state.isEditing, isTrue);
      expect(state.draft!.amount.amountMinor, 700);
    });
  });

  group('TransactionFormState.from', () {
    test('should_seed_whole_units_for_a_zero_exponent_currency', () {
      final state = TransactionFormState.from(
        Transaction(
          id: 'tx-1',
          categoryId: 'cat-1',
          amount: const Money.minor(1250, CurrencyCode.mmk),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 3, 14),
          createdAt: 1,
          updatedAt: 1,
        ),
      );

      expect(state.entryBuffer, '1250');
    });

    test('should_seed_minor_digits_for_a_two_exponent_currency', () {
      // 1250 cents must come back as `12.50`, not `1250` — otherwise editing a
      // USD row would multiply it by 100 on save.
      final state = TransactionFormState.from(
        Transaction(
          id: 'tx-1',
          categoryId: 'cat-1',
          amount: const Money.minor(1250, CurrencyCode.usd),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 3, 14),
          createdAt: 1,
          updatedAt: 1,
        ),
      );

      expect(state.entryBuffer, '12.50');
      expect(state.amount, const Money.minor(1250, CurrencyCode.usd));
    });

    test('should_left_pad_a_sub_unit_amount_so_it_round_trips', () {
      // 5 cents is `0.05`, not `.05` and not `5`.
      final state = TransactionFormState.from(
        Transaction(
          id: 'tx-1',
          categoryId: 'cat-1',
          amount: const Money.minor(5, CurrencyCode.usd),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 3, 14),
          createdAt: 1,
          updatedAt: 1,
        ),
      );

      expect(state.entryBuffer, '0.05');
      expect(state.amount, const Money.minor(5, CurrencyCode.usd));
    });

    test('should_carry_note_and_direction', () {
      final state = TransactionFormState.from(
        Transaction(
          id: 'tx-1',
          categoryId: 'cat-1',
          amount: const Money.minor(500, CurrencyCode.mmk),
          direction: TransactionDirection.income,
          date: LocalDate(2026, 3, 14),
          note: 'salary',
          createdAt: 1,
          updatedAt: 1,
        ),
      );

      expect(state.note, 'salary');
      expect(state.direction, TransactionDirection.income);
      expect(state.draft!.note, 'salary');
    });

    test('should_seed_a_blank_note_when_the_row_has_none', () {
      final state = TransactionFormState.from(
        Transaction(
          id: 'tx-1',
          categoryId: 'cat-1',
          amount: const Money.minor(500, CurrencyCode.mmk),
          direction: TransactionDirection.expense,
          date: LocalDate(2026, 3, 14),
          createdAt: 1,
          updatedAt: 1,
        ),
      );

      expect(state.note, '');
    });
  });
}
