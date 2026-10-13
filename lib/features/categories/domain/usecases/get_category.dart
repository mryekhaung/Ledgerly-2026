import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';

/// Parameters for [GetCategory].
typedef GetCategoryParams = ({String id});

/// Loads one category by id — the edit form's initial read.
///
/// Maps a missing row to a [NotFoundFailure] here rather than in the form: a
/// deleted-while-editing category is a *domain* fact ("this no longer exists"),
/// and the presentation layer should only have to localize it
/// (`docs/Architecture.md` §8).
class GetCategory implements UseCase<Category, GetCategoryParams> {
  const GetCategory(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Result<Category>> call(GetCategoryParams params) async {
    final result = await _repository.findById(params.id);
    return result.flatMap(
      (category) => category.isActive
          ? Success(category)
          : const Err<Category>(
              NotFoundFailure('Category is deleted', cause: null),
            ),
    );
  }
}
