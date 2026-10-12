import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';

/// The domain's contract for reading and writing categories.
///
/// The `data/` layer implements this over Drift; a future remote-backed
/// implementation swaps in without a single change to domain or presentation
/// (`docs/Architecture.md` §4, `docs/Agent.md` §3.2).
///
/// Every fallible method returns `Result<T>` — **no method throws for an
/// expected failure**, and the presentation layer never catches
/// (`docs/Agent.md` §3.4).
///
/// Reactive reads return `Stream<Result<T>>` rather than `Stream<T>`: the local
/// stream itself rarely fails, but a remote-backed implementation can, and
/// giving callers a uniform shape now avoids a breaking change at v0.4.
abstract interface class CategoryRepository {
  /// Active and archived categories in manual order, archived ones last.
  ///
  /// Archived rows are included deliberately — the list page shows them in a
  /// collapsed section, and only pickers filter them out.
  Stream<Result<List<Category>>> watchAll();

  /// Non-archived, active categories usable for [kind] — the picker query.
  Stream<Result<List<Category>>> watchPickable({required CategoryKind kind});

  /// The category with [id], or a `NotFoundFailure` when it is missing or
  /// soft-deleted.
  Future<Result<Category>> findById(String id);

  /// Creates a category from [draft] and returns it.
  ///
  /// The repository assigns the id, `sortOrder` and timestamps — a form never
  /// invents an id, which is what keeps ids collision-free across offline
  /// devices.
  Future<Result<Category>> create(CategoryDraft draft);

  /// Applies [draft] to the category with [id] and returns the updated row.
  Future<Result<Category>> update(String id, CategoryDraft draft);

  /// Soft-deletes [id]. The row stays on disk so a future sync can propagate
  /// the tombstone (`docs/Architecture.md` ADR #4).
  Future<Result<void>> delete(String id);

  /// Undoes [delete] by clearing the tombstone on [id].
  ///
  /// Exists because deletion is soft, which makes the undo affordance honest
  /// rather than a re-create that would lose the original id and timestamps
  /// (`docs/Design.md` §5.7).
  Future<Result<void>> restore(String id);

  /// Archives or unarchives [id].
  ///
  /// Distinct from [delete]: archiving retires a category from the picker while
  /// keeping it in history, so last year's chart still resolves its label.
  Future<Result<void>> setArchived(String id, {required bool isArchived});

  /// Persists a new manual order.
  ///
  /// [orderedIds] is the full, new top-to-bottom order. The whole column is
  /// rewritten in one transaction so the list is never observed half-reordered.
  Future<Result<void>> reorder(List<String> orderedIds);

  /// Whether an active category other than [excludingId] already uses [name].
  ///
  /// Exposed separately from [create]/[update] so a form can validate on the
  /// fly without attempting a write.
  Future<Result<bool>> nameExists(String name, {String? excludingId});
}
