import 'package:drift/drift.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/daos/clock.dart';
import 'package:ledgerly/core/database/uuid.dart';

/// A starter category: name, icon catalog key, and light-mode accent colour.
///
/// Colours are literal ARGB here rather than design tokens because this is the
/// **data** layer — the tokens live in `app/theme`, and a `core/` file importing
/// them would invert the dependency direction (`docs/Conventions.md` §2). The
/// values below are the same hues the token file declares; a drift between the two
/// is caught by `test/core/database/seed_test.dart`.
class SeedCategory {
  const SeedCategory(this.name, this.iconKey, this.colorValue, this.kind);

  final String name;
  final String iconKey;
  final int colorValue;
  final String kind;
}

/// The default category set for a fresh install. Spec: `docs/DataModel.md` §6.
///
/// `iconKey`s must be `CategoryIcons` vocabulary keys (semantic names like
/// `food`, never Material names like `restaurant`): unknown keys render as the
/// fallback glyph, so a wrong key here turns every seed row into the same tag
/// icon. Guarded by `seed_test.dart`.
const List<SeedCategory> defaultCategories = <SeedCategory>[
  SeedCategory('Food', 'food', 0xFFE8735A, 'expense'),
  SeedCategory('Transport', 'transport', 0xFF5A8FE8, 'expense'),
  SeedCategory('Groceries', 'groceries', 0xFF6FB98F, 'expense'),
  SeedCategory('Bills', 'bills', 0xFF8A7FE8, 'expense'),
  SeedCategory('Health', 'health', 0xFFE85A7F, 'expense'),
  SeedCategory('Shopping', 'shopping', 0xFFE8B25A, 'expense'),
  SeedCategory('Entertainment', 'entertainment', 0xFF5ACBE8, 'expense'),
  SeedCategory('Education', 'education', 0xFF7F8AE8, 'expense'),
  SeedCategory('Other', 'tag', 0xFF9AA0A6, 'expense'),
  SeedCategory('Salary', 'salary', 0xFF6FB98F, 'income'),
  SeedCategory('Other Income', 'savings', 0xFF5ACBE8, 'income'),
];

/// Inserts [defaultCategories] when the table is empty.
///
/// Returns the number of rows inserted (0 when seeding was skipped), so a caller
/// can log or assert the first-launch path.
///
/// Deliberately **not** called from a migration: a migration runs once per schema
/// version, but a user may delete every category on purpose and must not have them
/// reappear. Seeding is a first-launch concern, decided by an empty table.
Future<int> seedDefaults(AppDatabase db, {Clock clock = const Clock()}) async {
  final existing = await db.select(db.categories).get();
  if (existing.isNotEmpty) return 0;

  final now = clock.nowUtcMillis();
  await db.batch((batch) {
    for (var i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i];
      batch.insert(
        db.categories,
        CategoriesCompanion.insert(
          id: Value(generateUuid()),
          name: category.name,
          iconKey: category.iconKey,
          colorValue: category.colorValue,
          kind: Value(category.kind),
          sortOrder: Value(i),
          // True so a future "restore default categories" action needs no schema
          // change (`docs/DataModel.md` §2).
          isDefault: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  });
  return defaultCategories.length;
}
