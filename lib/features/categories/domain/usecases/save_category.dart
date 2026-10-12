import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/usecase/usecase.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/domain/validators/category_validators.dart';

/// Parameters for [SaveCategory].
///
/// [id] null means "create"; a value means "update". One use case rather than a
/// separate Create/Update pair because the form is one form — splitting it would
/// duplicate the validation and uniqueness logic that is the only interesting
/// part.
typedef SaveCategoryParams = ({String? id, CategoryDraft draft});

/// Validates and persists a category, create or update.
///
/// This is where the "no duplicate name" and "no blank name" rules are
/// enforced, so **no caller can bypass them** — a form, an import, and a future
/// sync all funnel through here (`docs/Agent.md` §3.3).
///
/// Returns a [ValidationFailure] whose [ValidationFailure.fieldErrors] maps a
/// field name to a localization key, so the UI can mark the offending field
/// without parsing text.
class SaveCategory implements UseCase<Category, SaveCategoryParams> {
  const SaveCategory(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Result<Category>> call(SaveCategoryParams params) async {
    final draft = params.draft;
    final id = params.id;

    // The name lookup only runs when the name is otherwise well-formed, so a
    // blank field reports "required" rather than a spurious "taken" — and so a
    // typo-length name never reaches the database.
    final trimmed = CategoryValidators.normalizeName(draft.name);
    final nameIsWellFormed =
        trimmed.isNotEmpty &&
        trimmed.length <= CategoryValidators.maxNameLength;

    final taken = <String>[];
    if (nameIsWellFormed) {
      // Checked against the *other* active categories, so an edit that leaves
      // the name unchanged does not conflict with itself.
      final result = await _repository.nameExists(trimmed, excludingId: id);
      if (result case Err(:final failure)) return Err<Category>(failure);
      if (result.valueOrNull ?? false) taken.add(trimmed);
    }

    final fieldError = CategoryValidators.draftError(
      draft,
      existingNames: taken,
    );
    if (fieldError != null) {
      return Err<Category>(
        ValidationFailure(
          'Category draft is invalid: $fieldError',
          fieldErrors: <String, String>{_fieldFor(fieldError): fieldError},
        ),
      );
    }

    // One region literal, so the uniqueness check and the stored value cannot
    // disagree about whitespace.
    final normalized = (
      name: trimmed,
      iconKey: draft.iconKey,
      colorValue: draft.colorValue,
      kind: draft.kind,
    );

    return id == null
        ? _repository.create(normalized)
        : _repository.update(id, normalized);
  }

  /// Maps a validator key to the form field it belongs to.
  static String _fieldFor(String validationKey) => switch (validationKey) {
    CategoryValidators.nameRequired ||
    CategoryValidators.nameTooLong ||
    CategoryValidators.nameTaken => 'name',
    CategoryValidators.iconRequired => 'iconKey',
    _ => 'colorValue',
  };
}
