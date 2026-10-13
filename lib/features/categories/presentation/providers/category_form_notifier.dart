import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';

/// Immutable form state for the category create/edit page.
///
/// A plain immutable object rather than individual fields on the notifier: the
/// form must render one consistent snapshot, and `==` on this lets
/// `ref.watch(...select(...))` skip rebuilds of untouched rows
/// (`docs/Architecture.md` §5).
final class CategoryFormState {
  /// Creates form state.
  const CategoryFormState({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.kind,
    this.existingId,
    this.isSaving = false,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.saved = false,
  });

  /// State for a brand-new category.
  ///
  /// The default icon and colour are non-null so the live preview always has
  /// something to render; a first-run `null` icon would make the form look
  /// broken before the user has touched it.
  factory CategoryFormState.blank({
    required String defaultIconKey,
    required int defaultColorValue,
    CategoryKind kind = CategoryKind.expense,
  }) => CategoryFormState(
    name: '',
    iconKey: defaultIconKey,
    colorValue: defaultColorValue,
    kind: kind,
  );

  /// State prefilled from an existing category.
  factory CategoryFormState.from(Category category) => CategoryFormState(
    name: category.name,
    iconKey: category.iconKey,
    colorValue: category.colorValue,
    kind: category.kind,
    existingId: category.id,
  );

  /// Current name text.
  final String name;

  /// Selected icon key.
  final String iconKey;

  /// Selected colour, as an ARGB int.
  final int colorValue;

  /// Income/expense classification.
  final CategoryKind kind;

  /// The id being edited, or null when creating.
  final String? existingId;

  /// True while the save is in flight — disables the submit button so a double
  /// tap cannot create two categories.
  final bool isSaving;

  /// Per-field validation errors, keyed by field name (not by ARB key).
  final Map<String, String> fieldErrors;

  /// The last save failure, or null.
  final Failure? failure;

  /// True once the save succeeded, so the page can pop.
  final bool saved;

  /// True when editing rather than creating.
  bool get isEditing => existingId != null;

  /// The draft this form currently describes.
  CategoryDraft get draft =>
      (name: name, iconKey: iconKey, colorValue: colorValue, kind: kind);

  /// Returns a copy with the given fields replaced.
  ///
  /// `fieldErrors` and `failure` are cleared on every edit by default — a stale
  /// "name taken" message must not survive the user fixing the name.
  CategoryFormState copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    CategoryKind? kind,
    bool? isSaving,
    Map<String, String>? fieldErrors,
    Failure? failure,
    bool? saved,
    bool clearFailure = false,
  }) => CategoryFormState(
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    kind: kind ?? this.kind,
    existingId: existingId,
    isSaving: isSaving ?? this.isSaving,
    fieldErrors: fieldErrors ?? const <String, String>{},
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
  );
}

/// Drives the category create/edit form.
class CategoryFormNotifier extends Notifier<CategoryFormState> {
  @override
  CategoryFormState build() => CategoryFormState.blank(
    defaultIconKey: _defaultIconKey,
    defaultColorValue: _defaultColorValue,
  );

  /// Seeds the form for an edit, or resets it for a create.
  ///
  /// Called from the page's `initState`-equivalent rather than in [build],
  /// because the category to edit arrives from the route and `build` must stay
  /// side-effect free (`docs/Architecture.md` §5).
  void initialise({Category? existing}) {
    state = existing == null
        ? CategoryFormState.blank(
            defaultIconKey: _defaultIconKey,
            defaultColorValue: _defaultColorValue,
          )
        : CategoryFormState.from(existing);
  }

  /// Updates the name and clears any stale name error.
  void setName(String value) => state = state.copyWith(
    name: value,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  /// Updates the icon.
  void setIcon(String iconKey) => state = state.copyWith(
    iconKey: iconKey,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  /// Updates the colour.
  void setColor(int colorValue) => state = state.copyWith(
    colorValue: colorValue,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  /// Updates the kind. Changing kind can invalidate a category choice, so the
  /// errors are cleared alongside it.
  void setKind(CategoryKind kind) => state = state.copyWith(
    kind: kind,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  /// Validates and saves. Returns true when the save succeeded.
  ///
  /// The notifier holds only a `bool` for its caller — the *reason* a save
  /// failed lands in `state.fieldErrors` / `state.failure`, so the page never
  /// has to interpret a failure itself.
  Future<bool> save() async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearFailure: true);

    final result = await ref.read(saveCategoryProvider).call((
      id: state.existingId,
      draft: state.draft,
    ));

    // The notifier may have been disposed while the save was in flight
    // (docs/Architecture.md §5).
    if (!ref.mounted) return false;

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSaving: false,
          saved: true,
          fieldErrors: const <String, String>{},
        );
        return true;
      },
      onErr: (failure) {
        state = state.copyWith(
          isSaving: false,
          failure: failure,
          fieldErrors: _fieldErrorsOf(failure),
        );
        return false;
      },
    );
  }

  /// Extracts a `ValidationFailure`'s per-field messages, or an empty map for
  /// any other failure kind.
  static Map<String, String> _fieldErrorsOf(Failure failure) =>
      failure is ValidationFailure ? failure.fieldErrors : const {};

  /// The icon pre-selected for a new category.
  static const String _defaultIconKey = 'tag';

  /// The colour pre-selected for a new category — brand primary.
  static const int _defaultColorValue = 0xFF2E7D6B;
}

/// Provides the category form state.
///
/// `autoDispose`: leaving the form must discard a half-typed draft rather than
/// let it resurface on the next visit.
final categoryFormProvider =
    NotifierProvider.autoDispose<CategoryFormNotifier, CategoryFormState>(
      CategoryFormNotifier.new,
    );
