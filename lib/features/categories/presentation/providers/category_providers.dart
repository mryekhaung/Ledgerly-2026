import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/domain/usecases/delete_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/get_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/save_category.dart';
import 'package:ledgerly/features/categories/domain/usecases/watch_categories.dart';

/// Thin bridge between get_it and Riverpod for the categories use cases.
///
/// `docs/Architecture.md` §5: presentation state lives in Riverpod, but the
/// use-case *instances* come from the locator — a provider here is one line and
/// carries no logic. Keeping the bridge in `presentation/` means `domain/` still
/// knows nothing about a widget-layer container, which the CI
/// `banned-imports` job enforces.
///
/// These are plain `Provider`s (not auto-disposed) because a use case is
/// stateless: rebuilding one on every scroll would allocate for no benefit. The
/// state that does need disposing lives in the notifiers that consume these.
final watchCategoriesProvider = Provider<WatchCategories>(
  (_) => getIt<WatchCategories>(),
);

/// Bridge for [WatchPickableCategories].
final watchPickableCategoriesProvider = Provider<WatchPickableCategories>(
  (_) => getIt<WatchPickableCategories>(),
);

/// The pickable categories of one [CategoryKind], as an `AsyncValue`.
///
/// The use case is a `Provider` returning a `Stream`; `.call(...)` on it yields
/// the raw stream, which has no `.value` to read synchronously. Wrapping it in a
/// `StreamProvider.family` is what turns it into the `AsyncValue` a widget can
/// render from immediately — the pattern the calendar's derived providers
/// already use (`calendar_notifier.dart`).
///
/// A stream error collapses to an empty list: a form that cannot list categories
/// should show "no categories yet", not an error page that blocks the keypad.
final pickableCategoriesProvider = StreamProvider.autoDispose
    .family<List<Category>, CategoryKind>((ref, kind) {
      final stream = ref.watch(watchPickableCategoriesProvider).call((
        kind: kind,
      ));
      return stream.map(
        (result) => result.fold(
          onSuccess: (list) => list,
          onErr: (_) => const <Category>[],
        ),
      );
    });

/// Bridge for [GetCategory].
final getCategoryProvider = Provider<GetCategory>((_) => getIt<GetCategory>());

/// Resolves one category by id, for widgets that hold only a `categoryId`.
///
/// The transaction day-list row is the reason this exists: a `Transaction`
/// stores an id, not a name or a colour, and the row still has to render both.
/// A `FutureProvider.family` (rather than calling [getCategoryProvider] inside a
/// `FutureBuilder`) keeps the result cached and shared across rows — a day with
/// 30 transactions in 6 categories issues 6 reads, not 30 — and `autoDispose`
/// releases it when the last row showing that category scrolls away.
///
/// Watching a re-*named* category eventually repaints rather than instantly:
/// this family has no dependency edge to the write path, so a rename is picked
/// up on the next dispose/rebuild of the row. Making it reactive would mean
/// watching the category stream here, which is more machinery than a v1 row
/// needs — the day list is rebuilt on every date change anyway.
///
/// The use case returns `Result<Category>`, so a failure is thrown here rather
/// than modelled twice: a `FutureProvider` already *is* the error channel
/// (`AsyncError`), and a row that cannot resolve its category shows a
/// placeholder via `.value == null`.
final categoryByIdProvider = FutureProvider.autoDispose
    .family<Category, String>(
      (ref, id) async =>
          switch (await ref.watch(getCategoryProvider)((id: id))) {
            Success(:final value) => value,
            Err(:final failure) => throw failure,
          },
    );

/// Bridge for [SaveCategory].
final saveCategoryProvider = Provider<SaveCategory>(
  (_) => getIt<SaveCategory>(),
);

/// Bridge for [DeleteCategory].
final deleteCategoryProvider = Provider<DeleteCategory>(
  (_) => getIt<DeleteCategory>(),
);

/// Bridge for [RestoreCategory].
final restoreCategoryProvider = Provider<RestoreCategory>(
  (_) => getIt<RestoreCategory>(),
);

/// Bridge for [SetCategoryArchived].
final setCategoryArchivedProvider = Provider<SetCategoryArchived>(
  (_) => getIt<SetCategoryArchived>(),
);

/// Bridge for [ReorderCategories].
final reorderCategoriesProvider = Provider<ReorderCategories>(
  (_) => getIt<ReorderCategories>(),
);
