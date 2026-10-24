import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_text_field.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:material_ui/material_ui.dart';

/// Amount, date and note fields.
///
/// Extracted from `transfer_page.dart` (`docs/Conventions.md` §1).
class TransferDetailsSection extends StatelessWidget {
  /// Creates a [TransferDetailsSection].
  const TransferDetailsSection({
    required this.amountController,
    required this.noteController,
    required this.fromAccount,
    required this.date,
    required this.onAmountChanged,
    required this.onPickDate,
    super.key,
  });

  /// The amount field controller (owned by the page).
  final TextEditingController amountController;

  /// The note field controller (owned by the page).
  final TextEditingController noteController;

  /// The source account (drives the currency prefix), if resolved.
  final Account? fromAccount;

  /// The transfer date.
  final LocalDate date;

  /// Called with the raw amount text.
  final ValueChanged<String> onAmountChanged;

  /// Called to pick the date.
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Amount
        Text(
          strings('accountsTransferAmount').toUpperCase(),
          style: AppTypography.overline.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: onAmountChanged,
          style: AppTypography.textTheme(colors).titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: fromAccount != null
                ? '${fromAccount!.currency.symbol} '
                : '',
            hintText: '0',
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Date Picker Field
        Text(
          strings('accountsTransferDate').toUpperCase(),
          style: AppTypography.overline.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onPickDate,
          borderRadius: AppRadius.borderMd,
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(AppIcons.calendar, size: 18),
            ),
            // §7: dates render via intl for the active locale, never ISO.
            child: Text(
              DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
                  .format(date.toDateTime()),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Note Field
        Text(
          strings('accountsTransferNote').toUpperCase(),
          style: AppTypography.overline.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          controller: noteController,
          maxLength: 200,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: strings('accountsTransferNote'),
            counterText: '',
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
