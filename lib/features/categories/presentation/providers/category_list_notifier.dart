import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/categories/presentation/category_list_state.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';

/// Watches the categories list and exposes it as a [CategoryListState].
///
/// A `StreamNotifier` (`docs/Architecture.md` §5) so a change written anywhere
/// — another screen creating a category — repaints this list without an explicit
/// invalidation channel.
///
/// The `Result` → state translation lives in [CategoryListState.from] rather
/// than here, so it is unit-testable without a container.
class CategoryListNotifier extends StreamNotifier<CategoryListState> {
  @override
  Stream<CategoryListState> build() {
    final watch = ref.watch(watchCategoriesProvider);
    return watch(const NoParams()).map(CategoryListState.from);
  }

  /// Re-runs the underlying query by rebuilding the stream.
  void refresh() => ref.invalidateSelf();
}

/// Provides the categories list state.
///
/// Auto-disposed: leaving the page releases the Drift stream
/// (`docs/Architecture.md` §5).
final categoryListProvider =
    StreamNotifierProvider.autoDispose<CategoryListNotifier, CategoryListState>(
      CategoryListNotifier.new,
    );
