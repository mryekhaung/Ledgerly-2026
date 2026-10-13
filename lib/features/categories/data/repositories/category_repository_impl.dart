import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/database/result_guard.dart';
import 'package:ledgerly/features/categories/data/datasources/category_local_datasource.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';

/// The local-first implementation of [CategoryRepository].
///
/// Today it talks to SQLite only. The v0.4 sync layer adds a
/// `CategoryRemoteDataSource` behind an interface and writes an outbox row on
/// each mutation — this class is the seam where that lands, and nothing above it
/// changes (`docs/Architecture.md` §4, ADR #5).
///
/// **Every method returns `Result`; none throws.** The two failure paths that
/// matter are a missing row on update (mapped to `NotFoundFailure`) and a
/// database error (mapped by [FailureMapper]).
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._local);

  final CategoryLocalDataSource _local;

  @override
  Stream<Result<List<Category>>> watchAll() =>
      guardResultStream(_local.watchAll());

  @override
  Stream<Result<List<Category>>> watchPickable({required CategoryKind kind}) =>
      guardResultStream(_local.watchPickable(kind: kind));

  @override
  Future<Result<Category>> findById(String id) => guardResult(() async {
    final category = await _local.findById(id);
    if (category == null || !category.isActive) {
      throw CategoryNotFoundException(id);
    }
    return category;
  }, onError: _notFoundAsFailure);

  @override
  Future<Result<Category>> create(CategoryDraft draft) =>
      guardResult(() => _local.create(draft));

  @override
  Future<Result<Category>> update(String id, CategoryDraft draft) =>
      guardResult(() => _local.update(id, draft), onError: _notFoundAsFailure);

  @override
  Future<Result<void>> delete(String id) =>
      guardResult(() => _local.delete(id));

  @override
  Future<Result<void>> restore(String id) =>
      guardResult(() => _local.restore(id));

  @override
  Future<Result<void>> setArchived(String id, {required bool isArchived}) =>
      guardResult(() => _local.setArchived(id, isArchived: isArchived));

  @override
  Future<Result<void>> reorder(List<String> orderedIds) =>
      guardResult(() => _local.reorder(orderedIds));

  @override
  Future<Result<bool>> nameExists(String name, {String? excludingId}) =>
      guardResult(() => _local.nameExists(name, excludingId: excludingId));

  /// Maps "row is gone" to a domain `NotFoundFailure` and everything else to the
  /// generic storage failure.
  ///
  /// A soft-deleted category counts as gone: the list page already hides it, so
  /// an edit form opened from a stale route must say "this no longer exists"
  /// rather than "something went wrong" (`docs/Architecture.md` §8).
  static Failure _notFoundAsFailure(Object error, StackTrace stackTrace) =>
      error is CategoryNotFoundException
      ? NotFoundFailure(error.toString(), cause: error, stackTrace: stackTrace)
      : FailureMapper.fromStorage(error, stackTrace);
}
