import 'package:material_ui/material_ui.dart';

/// The icon and colour options the category form offers.
///
/// Curated rather than "every Material icon": a picker with 2000 options is
/// unusable, and a fixed set keeps icon keys stable in the database
/// (`docs/DataModel.md` — `icon_key` is a stable string, never an index, so this
/// list may be reordered or extended without touching existing rows).
///
/// Pure data + [IconData] lookups. Kept out of the widget so the same catalogue
/// can back a future "most used" reordering or a search field.
abstract final class CategoryIcons {
  const CategoryIcons._();

  /// The icon used when a stored `icon_key` is not one this build knows.
  ///
  /// A missing icon must render as *something* plausible — a category whose
  /// icon was removed in a later build should not crash the list.
  static const String fallbackKey = 'tag';

  /// Selectable icon keys, in display order.
  ///
  /// Keys are semantic (`'food'`, `'transport'`) rather than Material names, so
  /// the glyph behind a key can change without a data migration.
  static const List<String> keys = <String>[
    'tag',
    'food',
    'drink',
    'groceries',
    'transport',
    'car',
    'home',
    'bills',
    'shopping',
    'health',
    'fitness',
    'education',
    'travel',
    'entertainment',
    'gift',
    'salary',
    'savings',
    'invest',
    'pet',
    'baby',
    'phone',
    'internet',
    'beauty',
    'charity',
  ];

  /// Resolves [key] to a glyph, falling back to [fallbackKey]'s icon.
  ///
  /// Pre-vocabulary installs stored Material names (`restaurant`,
  /// `directions_bus`, …) rather than semantic keys, and old backups can still
  /// carry them. [_legacyAliases] heals those rows to the glyph they always
  /// meant — without it every one of them renders as the fallback tag.
  static IconData iconFor(String? key) =>
      _icons[key] ?? _icons[_legacyAliases[key]] ?? _icons[fallbackKey]!;

  /// Material-name keys written before the semantic vocabulary, mapped to the
  /// canonical key whose glyph they meant. Append-only: a stored row is never
  /// rewritten, so an alias removed here blinds that row back to the fallback.
  /// Never exposed in [keys] — the picker offers canonical keys only.
  static const Map<String, String> _legacyAliases = <String, String>{
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

  /// The default glyph shown in the form's live preview.
  static IconData get defaultIcon => _icons[fallbackKey]!;

  /// Key → glyph. Private so callers go through [iconFor] and cannot bypass the
  /// fallback by indexing a missing key.
  static const Map<String, IconData> _icons = <String, IconData>{
    'tag': Icons.sell_outlined,
    'food': Icons.restaurant_outlined,
    'drink': Icons.local_cafe_outlined,
    'groceries': Icons.shopping_basket_outlined,
    'transport': Icons.directions_bus_outlined,
    'car': Icons.directions_car_outlined,
    'home': Icons.home_outlined,
    'bills': Icons.receipt_long_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'health': Icons.medical_services_outlined,
    'fitness': Icons.fitness_center_outlined,
    'education': Icons.school_outlined,
    'travel': Icons.flight_outlined,
    'entertainment': Icons.movie_outlined,
    'gift': Icons.card_giftcard_outlined,
    'salary': Icons.payments_outlined,
    'savings': Icons.savings_outlined,
    'invest': Icons.trending_up_outlined,
    'pet': Icons.pets_outlined,
    'baby': Icons.child_friendly_outlined,
    'phone': Icons.smartphone_outlined,
    'internet': Icons.wifi_outlined,
    'beauty': Icons.spa_outlined,
    'charity': Icons.volunteer_activism_outlined,
  };
}

/// The colour palette the category form offers.
///
/// Values are plain ARGB ints so they persist as one integer column
/// (`docs/DataModel.md`), and are deliberately a small fixed set: a free colour
/// picker produces categories that clash and are hard to distinguish at a
/// glance, which is the opposite of what the colour is for.
abstract final class CategoryPalette {
  const CategoryPalette._();

  /// The colour used when a stored value is fully transparent (alpha 0), which
  /// the validator rejects — so a row that somehow has one still renders.
  static const int fallbackColor = 0xFF2E7D6B;

  /// Selectable colours, ordered by hue family.
  static const List<int> colors = <int>[
    0xFFE85D5D, // coral
    0xFFE8833A, // amber
    0xFFE8B93A, // gold
    0xFF9BC53D, // lime
    0xFF4CAF7D, // green
    0xFF2E7D6B, // jade (brand)
    0xFF3AA6A0, // teal
    0xFF3A8FE8, // blue
    0xFF5A6FE8, // indigo
    0xFF8A5AE8, // violet
    0xFFC85AE8, // magenta
    0xFFE85A9B, // pink
  ];

  /// True when [value] is a usable (non-transparent) colour.
  static bool isValid(int value) => value != 0 && (value >> 24) & 0xFF != 0;
}
