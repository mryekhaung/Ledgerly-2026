import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/segmented_tabs.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:material_ui/material_ui.dart';

/// The expense/income switch.
///
/// Extracted from `transaction_form_page.dart` (`docs/Conventions.md` §1).
class DirectionToggle extends StatelessWidget {
  /// Creates a [DirectionToggle].
  const DirectionToggle({
    required this.direction,
    required this.onChanged,
    super.key,
  });

  /// The current direction.
  final TransactionDirection direction;

  /// Called with the new direction.
  final ValueChanged<TransactionDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SegmentedTabs<TransactionDirection>(
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
      onChanged: onChanged,
    );
  }
}
