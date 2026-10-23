import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/features/transactions/presentation/providers/calendar_notifier.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/calendar/transaction_row.dart';
import 'package:material_ui/material_ui.dart';

/// The list of transactions for the selected day.
///
/// Extracted from `calendar_page.dart` (`docs/Conventions.md` §1).
class DayList extends ConsumerStatefulWidget {
  /// Creates a [DayList].
  const DayList({required this.day, super.key});

  /// The day whose transactions are shown.
  final LocalDate day;

  @override
  ConsumerState<DayList> createState() => _DayListState();
}

/// State for [DayList].
///
/// Holds the set of ids dismissed by a swipe so the row is removed from the
/// visible list on the same frame the gesture completes. The soft delete only
/// propagates through the provider stream a frame later, and a `Dismissible`
/// whose key is still in the parent's children after `onDismissed` throws — so
/// we drop it locally first and let the stream confirm the removal.
class _DayListState extends ConsumerState<DayList> {
  final Set<String> _dismissed = <String>{};

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final transactionsAsync = ref.watch(selectedDayTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final visible = transactions
            .where((t) => !_dismissed.contains(t.id))
            .toList(growable: false);

        return visible.isEmpty
            ? StatePlaceholder(
                icon: AppIcons.inbox,
                title: strings('calendarEmptyDay'),
                body: strings('stateEmptyBody'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _DayHeader(day: widget.day),
                  const SizedBox(height: AppSpacing.sm),
                  for (final transaction in visible)
                    TransactionRow(
                      transaction: transaction,
                      onRemoved: (id) => setState(() => _dismissed.add(id)),
                      onRestored: (id) => setState(() => _dismissed.remove(id)),
                    ),
                ],
              );
      },
      loading: () => const LoadingPlaceholder(),
      error: (_, _) => ErrorBanner(
        message: strings('stateErrorBody'),
        onRetry: () => ref.invalidate(selectedDayTransactionsProvider),
      ),
    );
  }
}

/// The sticky date header above the day list.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final LocalDate day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final localizations = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    final label = localizations != null
        ? localizations.formatMediumDate(day.toUtcDateTime().toLocal())
        : DateFormat.yMMMd().format(day.toUtcDateTime().toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
