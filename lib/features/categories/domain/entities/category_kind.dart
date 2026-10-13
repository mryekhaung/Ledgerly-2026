/// Which transaction directions a category may be used for.
///
/// Persisted as the enum's `name` (never an ordinal) so reordering this enum
/// cannot silently reinterpret existing rows — `docs/DataModel.md` §1.
///
/// Pure Dart: no Flutter, no Drift (`docs/Agent.md` §3.1).
library;

/// The direction(s) a category applies to.
///
/// `transfer` is declared because the schema allows it (`docs/DataModel.md` §2)
/// even though v0.1 has no transfer UI — categories are the long-lived rows, so
/// the value must be representable before the feature that only reads it exists.
enum CategoryKind {
  /// Money out — the default for a new category.
  expense,

  /// Money in.
  income,

  /// Movement between two accounts (no UI until v0.3, `docs/Roadmap.md`).
  transfer;

  /// Resolves a [CategoryKind] from its stored name.
  ///
  /// Case-insensitive and null-tolerant so a value read from a hand-edited CSV
  /// or an older schema resolves instead of throwing. Returns null for an
  /// unknown name so the caller can map it to a `ValidationFailure`
  /// (`docs/Architecture.md` §8) — never silently default, which would rewrite
  /// a user's data on import.
  static CategoryKind? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final kind in CategoryKind.values) {
      if (kind.name == normalized) return kind;
    }
    return null;
  }

  /// The stable storage/key form — identical to [name], spelled out so call
  /// sites do not depend on the enum's implicit `toString`.
  String get storageValue => name;
}
