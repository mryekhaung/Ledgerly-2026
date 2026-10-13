/// Which way money moved.
///
/// Persisted as the enum's `name` (never an ordinal) so reordering this enum
/// cannot silently reinterpret existing rows — `docs/DataModel.md` §1.
///
/// Pure Dart: no Flutter, no Drift (`docs/Agent.md` §3.1).
library;

/// The direction of a transaction.
///
/// This — not the sign of an amount — is where the direction lives
/// (`docs/DataModel.md` §3). `amountMinor` is always a positive magnitude, so
/// `SUM(amount_minor)` filtered by direction is the only correct aggregation.
enum TransactionDirection {
  /// Money out.
  expense,

  /// Money in.
  income,

  /// Movement between two accounts (no UI until v0.3, `docs/Roadmap.md`).
  transfer;

  /// Resolves a direction from its stored name.
  ///
  /// Case-insensitive and null-tolerant so a hand-edited CSV or an older schema
  /// resolves instead of throwing. Returns null for an unknown name so the
  /// caller can raise a `ValidationFailure` rather than silently defaulting —
  /// guessing a direction would flip the sign of a user's money on import.
  static TransactionDirection? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final direction in TransactionDirection.values) {
      if (direction.name == normalized) return direction;
    }
    return null;
  }

  /// The stable storage form — identical to [name], spelled out so call sites
  /// do not depend on the enum's implicit `toString`.
  String get storageValue => name;

  /// True for the directions a v0.1 user can pick (transfer ships in v0.3).
  bool get isSelectableInV1 => this != TransactionDirection.transfer;

  /// The opposite direction, for the `+`/`−` toggle.
  ///
  /// `transfer` has no opposite in v0.1, so it maps to itself rather than
  /// throwing — a toggle on an unseen direction should be inert, not a crash.
  TransactionDirection get opposite => switch (this) {
    TransactionDirection.expense => TransactionDirection.income,
    TransactionDirection.income => TransactionDirection.expense,
    TransactionDirection.transfer => TransactionDirection.transfer,
  };
}
