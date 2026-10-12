import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';

/// Watches the category list page's data: everything, archived rows last.
///
/// A `StreamUseCase`, not a `UseCase`: the list is backed by a Drift stream and
/// must react to its own writes (`docs/Architecture.md` §7). Wrapping it in a
/// one-shot read would force the caller to poll or manually refresh.
class WatchCategories implements StreamUseCase<List<Category>, NoParams> {
  const WatchCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Stream<Result<List<Category>>> call(NoParams params) =>
      _repository.watchAll();
}

/// Parameters for [WatchPickableCategories] — present so the use case fits the
/// `StreamUseCase<T, P>` shape and can grow without breaking callers.
typedef WatchPickableParams = ({CategoryKind kind});

/// Watches the categories a picker may offer for one direction.
///
/// Separate from [WatchCategories] because the two queries differ in what they
/// hide: the picker drops archived rows, the list page keeps them. Sharing one
/// stream and filtering in Dart would rebuild the list page whenever a picker
/// changed (`docs/Architecture.md` §5).
class WatchPickableCategories
    implements StreamUseCase<List<Category>, WatchPickableParams> {
  const WatchPickableCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Stream<Result<List<Category>>> call(WatchPickableParams params) =>
      _repository.watchPickable(kind: params.kind);
}
