import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';

/// Parameters for [DeleteCategory].
typedef DeleteCategoryParams = ({String id});

/// Soft-deletes a category.
///
/// A thin pass-through by design: the rules that matter (a category in use by
/// transactions must not vanish from history) are satisfied by soft delete
/// itself, not by a check here — the rows that reference it stay intact and the
/// category still resolves by id (`docs/DataModel.md` §2).
///
/// Returned separately from [SaveCategory] because the delete confirm flow and
/// the undo affordance both need it in isolation (`docs/Design.md` §5.7).
class DeleteCategory implements UseCase<void, DeleteCategoryParams> {
  const DeleteCategory(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Result<void>> call(DeleteCategoryParams params) =>
      _repository.delete(params.id);
}

/// Parameters for [RestoreCategory].
typedef RestoreCategoryParams = ({String id});

/// Undoes a [DeleteCategory] by clearing the soft-delete tombstone.
///
/// Paired with [DeleteCategory] so the undo snack bar has a single, named
/// operation to call rather than reaching for the repository directly from a
/// widget. Restoring is deliberately **not** a create: the original id and
/// timestamps survive, so any transaction that referenced the category still
/// resolves — a re-create would mint a new id and orphan that history.
class RestoreCategory implements UseCase<void, RestoreCategoryParams> {
  const RestoreCategory(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Result<void>> call(RestoreCategoryParams params) =>
      _repository.restore(params.id);
}

/// Parameters for [SetCategoryArchived].
typedef SetCategoryArchivedParams = ({String id, bool isArchived});

/// Archives or unarchives a category.
///
/// The swipe action on the list page. Distinct from [DeleteCategory]: archiving
/// retires a category from the picker while keeping it in history and reports.
class SetCategoryArchived implements UseCase<void, SetCategoryArchivedParams> {
  const SetCategoryArchived(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Result<void>> call(SetCategoryArchivedParams params) =>
      _repository.setArchived(params.id, isArchived: params.isArchived);
}

/// Parameters for [ReorderCategories].
typedef ReorderCategoriesParams = ({List<String> orderedIds});

/// Persists a new manual category order.
///
/// Rejects an empty list early: a reorder that names no ids is a UI bug (a grid
/// that failed to build), and letting it reach the repository would rewrite
/// every `sortOrder` to nothing.
class ReorderCategories implements UseCase<void, ReorderCategoriesParams> {
  const ReorderCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Result<void>> call(ReorderCategoriesParams params) {
    if (params.orderedIds.isEmpty) {
      // Not a ValidationFailure: no user input is involved. An empty reorder is
      // a programming error, so it is reported as unexpected rather than shown
      // as a form error.
      return Future<Result<void>>.value(
        const Err<void>(
          UnexpectedFailure('ReorderCategories called with no ids'),
        ),
      );
    }
    return _repository.reorder(params.orderedIds);
  }
}
