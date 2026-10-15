import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:material_ui/material_ui.dart';

/// Name, target and current-saved amount fields.
///
/// Extracted from `goal_form_page.dart` (`docs/Conventions.md` §1).
class GoalBasicsSection extends StatelessWidget {
  /// Creates a [GoalBasicsSection].
  const GoalBasicsSection({
    required this.nameController,
    required this.targetAmountController,
    required this.currentAmountController,
    required this.currency,
    required this.nameError,
    required this.targetAmountError,
    required this.currentAmountError,
    super.key,
  });

  /// The name field controller (owned by the page).
  final TextEditingController nameController;

  /// The target amount controller (owned by the page).
  final TextEditingController targetAmountController;

  /// The current-saved controller (owned by the page).
  final TextEditingController currentAmountController;

  /// The goal currency (prefix).
  final CurrencyCode currency;

  /// Localized validation errors, if any.
  final String? nameError;
  final String? targetAmountError;
  final String? currentAmountError;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Goal Name
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: strings('goalNameLabel'),
            border: const OutlineInputBorder(),
            errorText: nameError,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Target Amount
        TextField(
          controller: targetAmountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: strings('goalTargetAmountLabel'),
            prefixText: '${currency.name.toUpperCase()} ',
            border: const OutlineInputBorder(),
            errorText: targetAmountError,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Current Saved Amount
        TextField(
          controller: currentAmountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: strings('goalCurrentAmountLabel'),
            prefixText: '${currency.name.toUpperCase()} ',
            border: const OutlineInputBorder(),
            errorText: currentAmountError,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
