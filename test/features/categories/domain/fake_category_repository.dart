/// In-memory fakes for the category domain tests.
///
/// Hand-written rather than generated with `mocktail` so the tests read as
/// behaviour ("this repository starts with Food already taken") instead of a
/// wall of `when(...).thenAnswer(...)`, and so a change to the interface breaks
/// the fake at compile time rather than at run time
/// (`docs/Conventions.md` §6: fakes over mocks).
library;

import 'dart:async';

import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';

/// A [CategoryRepository] backed by a `List`, for use-case tests.
///
/// Records every call so a test can assert the use case *did the right thing*
/// (issued one `nameExists`, and with the right exclusions) rather than only
/// that it returned a value.
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository({List<Category> seed = const <Category>[]})
    : _items = List<Category>.of(seed);

  final List<Category> _items;

  /// Every id passed to [update], in call order.
  final List<String> updatedIds = <String>[];

  /// Every draft passed to [create], in call order.
  final List<CategoryDraft> createdDrafts = <CategoryDraft>[];

  /// Every id passed to [restore], in call order — the undo path.
  final List<String> restoredIds = <String>[];

  /// Every `(name, excludingId)` pair passed to [nameExists].
  final List<({String name, String? excludingId})> nameExistsCalls =
      <({String name, String? excludingId})>[];

  /// Emits on every mutation, so a test can drive a `watch*` consumer.
  final StreamController<List<Category>> _allController =
      StreamController<List<Category>>.broadcast();

  /// When true, every method returns [forcedFailure] instead of succeeding.
  Failure? forcedFailure;

  /// The current contents, for assertions.
  List<Category> get items => List<Category>.unmodifiable(_items);

  /// Pushes the current state to [watchAll] subscribers.
  void emit() => _allController.add(List<Category>.of(_items));

  /// Releases the stream controller. Every test that constructs a fake must call
  /// this in an `addTearDown` (docs/Conventions.md §3: dispose everything).
  Future<void> dispose() => _allController.close();

  @override
  Stream<Result<List<Category>>> watchAll() async* {
    yield Success<List<Category>>(List<Category>.of(_items));
    yield* _allController.stream.map(Success<List<Category>>.new);
  }

  @override
  Stream<Result<List<Category>>> watchPickable({required CategoryKind kind}) =>
      watchAll().map(
        (result) => result.map(
          (list) => list.where((c) => c.isSelectableFor(kind)).toList(),
        ),
      );

  @override
  Future<Result<Category>> findById(String id) async {
    if (forcedFailure case final failure?) return Err<Category>(failure);
    final match = _items.where((c) => c.id == id && c.isActive).firstOrNull;
    return match == null
        ? const Err<Category>(NotFoundFailure('not found'))
        : Success(match);
  }

  @override
  Future<Result<Category>> create(CategoryDraft draft) async {
    createdDrafts.add(draft);
    if (forcedFailure case final failure?) return Err<Category>(failure);
    final created = Category(
      id: 'generated-${_items.length}',
      name: draft.name,
      iconKey: draft.iconKey,
      colorValue: draft.colorValue,
      kind: draft.kind,
      sortOrder: _items.length,
      isArchived: false,
      isDefault: false,
      createdAt: 1000,
      updatedAt: 1000,
    );
    _items.add(created);
    emit();
    return Success(created);
  }

  @override
  Future<Result<Category>> update(String id, CategoryDraft draft) async {
    updatedIds.add(id);
    if (forcedFailure case final failure?) return Err<Category>(failure);
    final index = _items.indexWhere((c) => c.id == id);
    if (index == -1) {
      return const Err<Category>(NotFoundFailure('not found'));
    }
    final updated = _items[index].copyWith(
      name: draft.name,
      iconKey: draft.iconKey,
      colorValue: draft.colorValue,
      kind: draft.kind,
      updatedAt: 2000,
    );
    _items[index] = updated;
    emit();
    return Success(updated);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (forcedFailure case final failure?) return Err<void>(failure);
    final index = _items.indexWhere((c) => c.id == id);
    if (index == -1) return const Err<void>(NotFoundFailure('not found'));
    _items[index] = _items[index].copyWith(deletedAt: 3000);
    emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restore(String id) async {
    restoredIds.add(id);
    if (forcedFailure case final failure?) return Err<void>(failure);
    final index = _items.indexWhere((c) => c.id == id);
    if (index == -1) return const Err<void>(NotFoundFailure('not found'));
    _items[index] = _items[index].copyWith(
      clearDeletedAt: true,
      updatedAt: 3200,
    );
    emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setArchived(
    String id, {
    required bool isArchived,
  }) async {
    if (forcedFailure case final failure?) return Err<void>(failure);
    final index = _items.indexWhere((c) => c.id == id);
    if (index == -1) return const Err<void>(NotFoundFailure('not found'));
    _items[index] = _items[index].copyWith(
      isArchived: isArchived,
      updatedAt: 3100,
    );
    emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> reorder(List<String> orderedIds) async {
    if (forcedFailure case final failure?) return Err<void>(failure);
    for (var i = 0; i < orderedIds.length; i++) {
      final index = _items.indexWhere((c) => c.id == orderedIds[i]);
      if (index != -1) {
        _items[index] = _items[index].copyWith(sortOrder: i, updatedAt: 4000);
      }
    }
    emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<bool>> nameExists(String name, {String? excludingId}) async {
    nameExistsCalls.add((name: name, excludingId: excludingId));
    if (forcedFailure case final failure?) return Err<bool>(failure);
    final taken = _items.any(
      (c) =>
          c.isActive &&
          c.id != excludingId &&
          c.name.toLowerCase() == name.toLowerCase(),
    );
    return Success(taken);
  }
}

/// Builds a [Category] with sensible defaults, so a test states only the field
/// it cares about.
Category fakeCategory({
  String id = 'cat-1',
  String name = 'Food',
  String iconKey = 'restaurant',
  int colorValue = 0xFFE8735A,
  CategoryKind kind = CategoryKind.expense,
  int sortOrder = 0,
  bool isArchived = false,
  bool isDefault = false,
  int createdAt = 1000,
  int updatedAt = 1000,
  int? deletedAt,
}) => Category(
  id: id,
  name: name,
  iconKey: iconKey,
  colorValue: colorValue,
  kind: kind,
  sortOrder: sortOrder,
  isArchived: isArchived,
  isDefault: isDefault,
  createdAt: createdAt,
  updatedAt: updatedAt,
  deletedAt: deletedAt,
);
