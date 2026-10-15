import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_card.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_form_notifier.dart';
import 'package:material_ui/material_ui.dart';

/// Shows what the category will look like in a list, as the user edits it.
///
/// Extracted from `category_form_page.dart` (`docs/Conventions.md` §1).
class CategoryPreviewCard extends StatelessWidget {
  /// Creates a [CategoryPreviewCard].
  const CategoryPreviewCard({required this.state, super.key});

  /// The live form state.
  final CategoryFormState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    // Falls back to the hint so an empty name still renders a plausible row
    // rather than a blank gem with nothing beside it.
    final name = state.name.trim().isEmpty ? '—' : state.name.trim();

    // §5.2: previews are AppCards, not bespoke subtle containers.
    return AppCard(
      child: CategoryGemLabel(
        name: name,
        colorValue: state.colorValue,
        iconKey: state.iconKey,
        size: CategoryGemSize.lg,
        subtitle: state.kind == CategoryKind.income
            ? strings('transactionDirectionIncome')
            : strings('transactionDirectionExpense'),
      ),
    );
  }
}
