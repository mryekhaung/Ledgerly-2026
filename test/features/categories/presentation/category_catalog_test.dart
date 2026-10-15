import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/categories/presentation/category_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// The icon vocabulary contract (`docs/Design.md` §5.3, `docs/DataModel.md` §2).
///
/// `icon_key` is a stable string: the picker offers canonical keys, old rows
/// and backups can carry pre-vocabulary Material names, and anything else must
/// degrade to the fallback instead of throwing.
void main() {
  group('CategoryIcons.iconFor', () {
    test('should_resolve_every_catalogue_key_without_fallback', () {
      final fallback = CategoryIcons.iconFor(CategoryIcons.fallbackKey);
      for (final key in CategoryIcons.keys) {
        if (key == CategoryIcons.fallbackKey) continue;
        expect(
          CategoryIcons.iconFor(key),
          isNot(fallback),
          reason: '$key must not collapse onto the fallback',
        );
      }
    });

    test('should_heal_every_legacy_material_name', () {
      const legacy = <String, String>{
        'restaurant': 'food',
        'directions_bus': 'transport',
        'shopping_basket': 'groceries',
        'receipt_long': 'bills',
        'local_hospital': 'health',
        'shopping_bag': 'shopping',
        'movie': 'entertainment',
        'school': 'education',
        'more_horiz': 'tag',
        'payments': 'salary',
      };

      for (final entry in legacy.entries) {
        expect(
          CategoryIcons.iconFor(entry.key),
          CategoryIcons.iconFor(entry.value),
          reason: '${entry.key} should heal to ${entry.value}',
        );
      }
    });

    test('should_fall_back_for_unknown_and_null_keys', () {
      final fallback = CategoryIcons.iconFor(CategoryIcons.fallbackKey);

      expect(CategoryIcons.iconFor('no_such_icon'), fallback);
      expect(CategoryIcons.iconFor(null), fallback);
      expect(CategoryIcons.iconFor(''), fallback);
    });

    test('should_keep_the_fallback_inside_the_catalogue', () {
      expect(CategoryIcons.keys, contains(CategoryIcons.fallbackKey));
      expect(CategoryIcons.defaultIcon, isA<IconData>());
    });
  });
}
