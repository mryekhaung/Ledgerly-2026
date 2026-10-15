import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Amount limit field.
///
/// Extracted from `budget_form_page.dart` (`docs/Conventions.md` §1).
class BudgetAmountSection extends StatelessWidget {
  /// Creates a [BudgetAmountSection].
  const BudgetAmountSection({
    required this.controller,
    required this.currency,
    required this.errorText,
    required this.onChanged,
    super.key,
  });

  /// The amount field controller (owned by the page).
  final TextEditingController controller;

  /// The budget currency (prefix + precision).
  final CurrencyCode currency;

  /// The localized validation error, if any.
  final String? errorText;

  /// Called with the raw field text.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          strings('budgetFieldAmount'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '${currency.name.toUpperCase()} ',
            hintText: '0',
            errorText: errorText,
            border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
