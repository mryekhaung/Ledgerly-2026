import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/domain/validators/category_validators.dart';

/// Category validation is what stops a blank or duplicated label from reaching
/// storage, so these tests cover the normalisation boundary (trim, case) as
/// carefully as the rejections.
void main() {
  group('CategoryValidators.normalizeName', () {
    test('should_strip_surrounding_whitespace_when_present', () {
      expect(CategoryValidators.normalizeName('  Food  '), 'Food');
    });

    test('should_preserve_inner_spacing_when_present', () {
      // "Eating Out" and "Eating  Out" are the same label to the eye but
      // different strings; collapsing them would silently rename a user's data.
      expect(CategoryValidators.normalizeName('Eating  Out'), 'Eating  Out');
    });

    test('should_return_empty_when_input_is_only_whitespace', () {
      expect(CategoryValidators.normalizeName('   '), isEmpty);
    });
  });

  group('CategoryValidators.nameError', () {
    test('should_report_required_when_name_is_empty', () {
      expect(CategoryValidators.nameError(''), CategoryValidators.nameRequired);
    });

    test('should_report_required_when_name_is_whitespace_only', () {
      expect(
        CategoryValidators.nameError('   '),
        CategoryValidators.nameRequired,
      );
    });

    test('should_report_too_long_when_name_exceeds_max_length', () {
      final long = 'a' * (CategoryValidators.maxNameLength + 1);
      expect(
        CategoryValidators.nameError(long),
        CategoryValidators.nameTooLong,
      );
    });

    test('should_accept_name_at_exactly_max_length', () {
      final exact = 'a' * CategoryValidators.maxNameLength;
      expect(CategoryValidators.nameError(exact), isNull);
    });

    test('should_not_count_whitespace_when_measuring_length', () {
      // Trim happens before the length check, so 60 characters padded with
      // spaces is a valid 60-character name — not a spurious "too long".
      final padded = '  ${'a' * CategoryValidators.maxNameLength}  ';
      expect(CategoryValidators.nameError(padded), isNull);
    });

    test('should_report_taken_when_name_already_exists', () {
      expect(
        CategoryValidators.nameError('Food', existingNames: ['Food']),
        CategoryValidators.nameTaken,
      );
    });

    test('should_report_taken_when_existing_name_differs_only_in_case', () {
      // "food" and "Food" are one label to a user; allowing both makes the
      // picker ambiguous and the chart legend contradictory.
      expect(
        CategoryValidators.nameError('food', existingNames: ['Food']),
        CategoryValidators.nameTaken,
      );
    });

    test('should_report_taken_when_existing_name_has_padding', () {
      expect(
        CategoryValidators.nameError('Food', existingNames: ['  Food  ']),
        CategoryValidators.nameTaken,
      );
    });

    test('should_accept_name_when_existing_names_are_unrelated', () {
      expect(
        CategoryValidators.nameError(
          'Travel',
          existingNames: ['Food', 'Bills'],
        ),
        isNull,
      );
    });
  });

  group('CategoryValidators.iconError', () {
    test('should_report_required_when_icon_key_is_empty', () {
      expect(CategoryValidators.iconError(''), CategoryValidators.iconRequired);
    });

    test('should_report_required_when_icon_key_is_whitespace_only', () {
      expect(
        CategoryValidators.iconError('   '),
        CategoryValidators.iconRequired,
      );
    });

    test('should_accept_a_populated_icon_key', () {
      expect(CategoryValidators.iconError('restaurant'), isNull);
    });
  });

  group('CategoryValidators.colorError', () {
    test('should_report_invalid_when_alpha_is_zero', () {
      // A fully transparent accent renders the gem invisible — a silent visual
      // bug, which is why it is a validation error rather than a style choice.
      expect(
        CategoryValidators.colorError(0x00E8735A),
        CategoryValidators.colorInvalid,
      );
    });

    test('should_accept_a_fully_opaque_colour', () {
      expect(CategoryValidators.colorError(0xFFE8735A), isNull);
    });

    test('should_accept_a_semi_transparent_colour_when_alpha_is_non_zero', () {
      expect(CategoryValidators.colorError(0x80E8735A), isNull);
    });

    test('should_accept_colour_zero_when_alpha_bits_are_absent', () {
      // `0` has alpha 0, so it is rejected — asserted explicitly because
      // "transparent black" is the classic default value a form forgets to set.
      expect(CategoryValidators.colorError(0), CategoryValidators.colorInvalid);
    });
  });

  group('CategoryValidators.draftError', () {
    const valid = (
      name: 'Travel',
      iconKey: 'flight',
      colorValue: 0xFF5A8FE8,
      kind: CategoryKind.expense,
    );

    test('should_report_nothing_when_draft_is_valid', () {
      expect(CategoryValidators.draftError(valid), isNull);
    });

    test(
      'should_report_the_name_problem_first_when_several_fields_are_wrong',
      () {
        // Field order matches the form, so the user is pointed at the topmost
        // problem rather than an arbitrary one.
        expect(
          CategoryValidators.draftError((
            name: '',
            iconKey: '',
            colorValue: 0,
            kind: CategoryKind.expense,
          )),
          CategoryValidators.nameRequired,
        );
      },
    );

    test('should_report_the_icon_problem_when_only_the_icon_is_wrong', () {
      expect(
        CategoryValidators.draftError((
          name: 'Travel',
          iconKey: '  ',
          colorValue: 0xFF5A8FE8,
          kind: CategoryKind.expense,
        )),
        CategoryValidators.iconRequired,
      );
    });

    test('should_report_the_colour_problem_when_only_the_colour_is_wrong', () {
      expect(
        CategoryValidators.draftError((
          name: 'Travel',
          iconKey: 'flight',
          colorValue: 0,
          kind: CategoryKind.expense,
        )),
        CategoryValidators.colorInvalid,
      );
    });

    test('should_forward_existing_names_when_checking_uniqueness', () {
      expect(
        CategoryValidators.draftError(valid, existingNames: ['Travel']),
        CategoryValidators.nameTaken,
      );
    });
  });
}
