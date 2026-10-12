import 'package:ledgerly/features/categories/domain/entities/category.dart';

/// Field-level validation for a category form.
///
/// Lives in `domain/` so the same rules apply to the form, to an import, and to
/// a future sync payload — a rule duplicated in a widget is a rule that will
/// disagree with storage (`docs/Architecture.md` §5, §11).
///
/// Every method returns a **localization key**, not a sentence: the
/// presentation layer resolves the text from ARB (`docs/Conventions.md` §5).
/// Pure Dart — no Flutter, no Drift (`docs/Agent.md` §3.1).
abstract final class CategoryValidators {
  const CategoryValidators._();

  /// Maximum display-name length. Matches the `withLength(max: 60)` column in
  /// `tables/categories.dart` — the schema is the source of truth, this mirrors it.
  static const int maxNameLength = 60;

  /// Validation key returned when a name is empty or whitespace-only.
  static const String nameRequired = 'categoryNameRequired';

  /// Validation key returned when a name is longer than [maxNameLength].
  static const String nameTooLong = 'categoryNameTooLong';

  /// Validation key returned when a name is already taken by another category.
  static const String nameTaken = 'categoryNameTaken';

  /// Validation key returned when no icon has been chosen.
  static const String iconRequired = 'categoryIconRequired';

  /// Validation key returned when a colour is not a valid opaque ARGB value.
  static const String colorInvalid = 'categoryColorInvalid';

  /// Trims a raw name to its storage form.
  ///
  /// Trimming happens here, not at the storage boundary, so that the
  /// uniqueness check and the stored value agree — otherwise ` Food` and
  /// `Food` would both be accepted and stored differently.
  static String normalizeName(String raw) => raw.trim();

  /// The first problem with [rawName], or null when it is acceptable.
  ///
  /// [existingNames] is the set of names already in use by *other* active
  /// categories, compared case-insensitively: "Food" and "food" are the same
  /// label to a user, and allowing both makes the picker ambiguous.
  static String? nameError(
    String rawName, {
    Iterable<String> existingNames = const <String>[],
  }) {
    final normalized = normalizeName(rawName);
    if (normalized.isEmpty) return nameRequired;
    if (normalized.length > maxNameLength) return nameTooLong;

    final lowered = normalized.toLowerCase();
    for (final existing in existingNames) {
      if (normalizeName(existing).toLowerCase() == lowered) return nameTaken;
    }
    return null;
  }

  /// The first problem with [iconKey], or null when it is acceptable.
  static String? iconError(String iconKey) =>
      iconKey.trim().isEmpty ? iconRequired : null;

  /// The first problem with [colorValue], or null when it is acceptable.
  ///
  /// A colour is stored as opaque ARGB32, so a zero alpha channel would render
  /// the gem invisible — rejecting it here turns a silent visual bug into a
  /// form error.
  static String? colorError(int colorValue) {
    final alpha = (colorValue >> 24) & 0xFF;
    return alpha == 0 ? colorInvalid : null;
  }

  /// The first problem with [draft], or null when the whole draft is valid.
  ///
  /// The order matches the form's field order so the user is pointed at the
  /// topmost problem rather than an arbitrary one.
  static String? draftError(
    CategoryDraft draft, {
    Iterable<String> existingNames = const <String>[],
  }) {
    final name = nameError(draft.name, existingNames: existingNames);
    if (name != null) return name;
    final icon = iconError(draft.iconKey);
    if (icon != null) return icon;
    return colorError(draft.colorValue);
  }
}
