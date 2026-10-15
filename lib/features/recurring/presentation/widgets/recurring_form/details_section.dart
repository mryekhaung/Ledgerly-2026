import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// Direction, amount, category and account fields.
///
/// Extracted from `recurring_form_page.dart` (`docs/Conventions.md` §1).
class RecurringDetailsSection extends StatelessWidget {
  /// Creates a [RecurringDetailsSection].
  const RecurringDetailsSection({
    required this.direction,
    required this.amountController,
    required this.currency,
    required this.amountError,
    required this.categories,
    required this.categoryId,
    required this.categoryError,
    required this.accounts,
    required this.accountId,
    required this.onDirectionChanged,
    required this.onAmountChanged,
    required this.onCategoryChanged,
    required this.onAccountChanged,
    super.key,
  });

  /// The transaction direction.
  final TransactionDirection direction;

  /// The amount field controller (owned by the page).
  final TextEditingController amountController;

  /// The form currency.
  final CurrencyCode currency;

  /// The localized amount error, if any.
  final String? amountError;

  /// Pickable categories for the current direction.
  final List<Category> categories;

  /// The chosen category id.
  final String categoryId;

  /// The localized category error, if any.
  final String? categoryError;

  /// Available accounts (empty hides the selector).
  final List<Account> accounts;

  /// The chosen account id, if any.
  final String? accountId;

  /// Called with the new direction.
  final ValueChanged<TransactionDirection> onDirectionChanged;

  /// Called with the raw amount text.
  final ValueChanged<String> onAmountChanged;

  /// Called with the picked category id.
  final ValueChanged<String> onCategoryChanged;

  /// Called with the picked account id (null clears).
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Direction selector (Expense / Income)
        SegmentedTabs<TransactionDirection>(
          tabs: <SegmentedTab<TransactionDirection>>[
            SegmentedTab<TransactionDirection>(
              value: TransactionDirection.expense,
              label: strings('transactionDirectionExpense'),
              icon: AppIcons.increase,
            ),
            SegmentedTab<TransactionDirection>(
              value: TransactionDirection.income,
              label: strings('transactionDirectionIncome'),
              icon: AppIcons.decrease,
            ),
          ],
          selected: direction,
          onChanged: onDirectionChanged,
        ),
        const SizedBox(height: AppSpacing.md),

        // Amount input
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: strings('budgetFieldAmount'),
            prefixText: '${currency.code.toUpperCase()} ',
            border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
            errorText: amountError,
          ),
          onChanged: onAmountChanged,
        ),
        const SizedBox(height: AppSpacing.md),

        // Category dropdown
        DropdownButtonFormField<String>(
          initialValue: categoryId.isNotEmpty
              ? categoryId
              : (categories.isNotEmpty ? categories.first.id : null),
          decoration: InputDecoration(
            labelText: strings('budgetFieldCategory'),
            border: const OutlineInputBorder(borderRadius: AppRadius.borderMd),
            errorText: categoryError,
          ),
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat.id,
              child: Row(
                children: <Widget>[
                  CategoryGem(
                    colorValue: cat.colorValue,
                    iconKey: cat.iconKey,
                    size: CategoryGemSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(cat.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (catId) {
            if (catId != null) onCategoryChanged(catId);
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Account selector (optional)
        if (accounts.isNotEmpty) ...<Widget>[
          DropdownButtonFormField<String?>(
            initialValue: accountId,
            decoration: InputDecoration(
              labelText: strings('recurringFieldAccountOptional'),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
              ),
            ),
            items: <DropdownMenuItem<String?>>[
              DropdownMenuItem<String?>(
                value: null,
                child: Text(strings('recurringAccountNone')),
              ),
              ...accounts.map(
                (acc) => DropdownMenuItem<String?>(
                  value: acc.id,
                  child: Text('${acc.name} (${acc.currency.code})'),
                ),
              ),
            ],
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
