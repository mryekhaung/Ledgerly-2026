import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveTextField;
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/platform/app_platform.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

/// Min/max amount fields with the apply action.
///
/// Extracted from `transaction_filter_sheet.dart` (`docs/Conventions.md` §1).
class FilterAmountRangeSection extends StatelessWidget {
  /// Creates a [FilterAmountRangeSection].
  const FilterAmountRangeSection({
    required this.minController,
    required this.maxController,
    required this.currency,
    required this.onApply,
    super.key,
  });

  /// The min-amount field controller (owned by the sheet).
  final TextEditingController minController;

  /// The max-amount field controller (owned by the sheet).
  final TextEditingController maxController;

  /// The currency shown in the section label.
  final CurrencyCode currency;

  /// Called to apply the filter.
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${strings('filterAmount')} (${currency.code.toUpperCase()})',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: _amountInput(
                context,
                controller: minController,
                placeholder: strings('filterMinAmount'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('~'),
            ),
            Expanded(
              child: _amountInput(
                context,
                controller: maxController,
                placeholder: strings('filterMaxAmount'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Action button
        AppButton(
          label: strings('filterApply'),
          onPressed: onApply,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _amountInput(
    BuildContext context, {
    required TextEditingController controller,
    required String placeholder,
  }) {
    if (AppPlatform.resolve().usesCupertino) {
      return AdaptiveTextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: placeholder,
        cupertinoDecoration: BoxDecoration(
          color: AppThemeColors.of(context).surfaceSubtle,
          borderRadius: AppRadius.borderMd,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: placeholder,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
      ),
    );
  }
}
