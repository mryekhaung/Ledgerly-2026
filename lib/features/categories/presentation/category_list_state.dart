import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';

/// The categories list page's state.
///
/// Pure Dart so the active/archived split is unit-testable without a widget or
/// a running Riverpod container (`docs/Agent.md` §6): the page should not be the
/// only thing that knows how a `Result` becomes a renderable list.
final class CategoryListState {
  /// Creates a list state.
  const CategoryListState({
    required this.active,
    required this.archived,
    this.failure,
  });

  /// An empty state, used before the first stream event.
  const CategoryListState.empty()
    : active = const <Category>[],
      archived = const <Category>[],
      failure = null;

  /// Derives the state from a repository [result].
  ///
  /// A failed load yields empty lists *plus* the failure, so the page shows one
  /// banner rather than a banner over stale rows that are no longer valid.
  factory CategoryListState.from(Result<List<Category>> result) => result.fold(
    onSuccess: CategoryListState.of,
    onErr: (failure) => CategoryListState(
      active: const <Category>[],
      archived: const <Category>[],
      failure: failure,
    ),
  );

  /// Splits [categories] into active and archived, preserving order.
  ///
  /// Order is preserved rather than re-sorted: the list reflects the manual
  /// `sortOrder` the user set, and re-sorting here would silently override it.
  factory CategoryListState.of(List<Category> categories) => CategoryListState(
    active: categories.where((c) => !c.isArchived).toList(growable: false),
    archived: categories.where((c) => c.isArchived).toList(growable: false),
  );

  /// Non-archived categories, in manual order.
  final List<Category> active;

  /// Archived categories, in manual order.
  final List<Category> archived;

  /// The last failure, or null.
  final Failure? failure;

  /// True when the user has no categories at all.
  bool get isEmpty => active.isEmpty && archived.isEmpty;

  /// True when nothing has been loaded and nothing failed yet.
  bool get isFirstLoad => isEmpty && failure == null;
}
