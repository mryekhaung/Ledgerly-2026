import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';

/// Aggregated spending for one category within a budget period.
///
/// Combines the SQL category sum with the category's presentation metadata
/// (name, icon, color) and its share of total expenses.
final class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amountMinor,
    required this.percentage,
    required this.currency,
  });

  /// The category metadata (name, iconKey, colorValue).
  final Category category;

  /// Absolute amount spent in minor units (always positive).
  final int amountMinor;

  /// Ratio of this category's spend relative to total expenses (0.0 to 1.0).
  final double percentage;

  /// The currency this total is denominated in.
  final CurrencyCode currency;

  @override
  bool operator ==(Object other) =>
      other is CategoryBreakdown &&
      other.category == category &&
      other.amountMinor == amountMinor &&
      other.percentage == percentage &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(category, amountMinor, percentage, currency);

  @override
  String toString() =>
      'CategoryBreakdown(${category.name}, $amountMinor, ${(percentage * 100).toStringAsFixed(1)}%)';
}
