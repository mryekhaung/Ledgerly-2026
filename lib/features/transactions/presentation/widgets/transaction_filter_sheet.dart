import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/category_gem.dart';
import 'package:ledgerly/core/widgets/month_day_picker_page.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/presentation/pages/category_picker_page.dart';
import 'package:material_ui/material_ui.dart';

/// Modal bottom sheet allowing users to configure detailed search/filter options.
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final TransactionFilter initialFilter;
  final ValueChanged<TransactionFilter> onApply;

  /// Shows the filter sheet modal.
  static Future<void> show({
    required BuildContext context,
    required TransactionFilter initialFilter,
    required ValueChanged<TransactionFilter> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFilterSheet(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TransactionDirection? _direction;
  late String? _categoryId;
  late LocalDate? _startDate;
  late LocalDate? _endDate;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialFilter.direction;
    _categoryId = widget.initialFilter.categoryId;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;

    final currency = ref.read(currencyProvider);
    final divisor = currency.exponent == 0 ? 1 : 100;

    final initialMin = widget.initialFilter.minAmountMinor;
    _minAmountController = TextEditingController(
      text: initialMin == null
          ? ''
          : (initialMin / divisor).toStringAsFixed(currency.exponent),
    );

    final initialMax = widget.initialFilter.maxAmountMinor;
    _maxAmountController = TextEditingController(
      text: initialMax == null
          ? ''
          : (initialMax / divisor).toStringAsFixed(currency.exponent),
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _direction = null;
      _categoryId = null;
      _startDate = null;
      _endDate = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _apply() {
    final currency = ref.read(currencyProvider);
    final multiplier = currency.exponent == 0 ? 1 : 100;

    int? minMinor;
    final minText = _minAmountController.text.trim();
    if (minText.isNotEmpty) {
      final val = double.tryParse(minText);
      if (val != null && val >= 0) {
        minMinor = (val * multiplier).round();
      }
    }

    int? maxMinor;
    final maxText = _maxAmountController.text.trim();
    if (maxText.isNotEmpty) {
      final val = double.tryParse(maxText);
      if (val != null && val >= 0) {
        maxMinor = (val * multiplier).round();
      }
    }

    final newFilter = widget.initialFilter.copyWith(
      direction: _direction,
      clearDirection: _direction == null,
      categoryId: _categoryId,
      clearCategoryId: _categoryId == null,
      startDate: _startDate,
      clearStartDate: _startDate == null,
      endDate: _endDate,
      clearEndDate: _endDate == null,
      minAmountMinor: minMinor,
      clearMinAmount: minMinor == null,
      maxAmountMinor: maxMinor,
      clearMaxAmount: maxMinor == null,
    );

    widget.onApply(newFilter);
    Navigator.of(context).pop();
  }

  Future<void> _pickCategory() async {
    final kind = switch (_direction) {
      TransactionDirection.income => CategoryKind.income,
      _ => CategoryKind.expense,
    };

    final chosen = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) => CategoryPickerPage(kind: kind, selectedId: _categoryId),
      ),
    );

    if (chosen != null && mounted) {
      setState(() => _categoryId = chosen.id);
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = LocalDate(now.year, now.month, now.day);
    final chosen = await Navigator.of(context).push<LocalDate>(
      MaterialPageRoute<LocalDate>(
        builder: (_) => MonthDayPickerPage(initialDate: _startDate ?? today),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _startDate = chosen);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = LocalDate(now.year, now.month, now.day);
    final chosen = await Navigator.of(context).push<LocalDate>(
      MaterialPageRoute<LocalDate>(
        builder: (_) => MonthDayPickerPage(initialDate: _endDate ?? today),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _endDate = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final currency = ref.watch(currencyProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    Category? selectedCategory;
    if (_categoryId case final id?) {
      selectedCategory = ref.watch(categoryByIdProvider(id)).value;
    }

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: AppRadius.borderSm,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  strings('filterTitle'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(strings('filterClearAll')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Direction / Type
            Text(
              strings('categoriesKindLabel'),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<TransactionDirection?>(
              segments: <ButtonSegment<TransactionDirection?>>[
                ButtonSegment<TransactionDirection?>(
                  value: null,
                  label: Text(strings('filterAll')),
                ),
                ButtonSegment<TransactionDirection?>(
                  value: TransactionDirection.expense,
                  label: Text(strings('filterExpense')),
                ),
                ButtonSegment<TransactionDirection?>(
                  value: TransactionDirection.income,
                  label: Text(strings('filterIncome')),
                ),
              ],
              selected: <TransactionDirection?>{_direction},
              onSelectionChanged: (newSelection) {
                setState(() => _direction = newSelection.first);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category Picker Row
            Text(
              strings('filterCategory'),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickCategory,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: <Widget>[
                    if (selectedCategory case final cat?) ...<Widget>[
                      CategoryGem(
                        colorValue: cat.colorValue,
                        iconKey: cat.iconKey,
                        size: CategoryGemSize.sm,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _categoryId = null),
                      ),
                    ] else ...<Widget>[
                      Icon(
                        Icons.category_outlined,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          strings('transactionCategoryChoose'),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date Range
            Text(
              strings('filterDateRange'),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStartDate,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _startDate == null
                          ? strings('filterStartDate')
                          : dateFormat.format(_startDate!.toDateTime()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text('~'),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEndDate,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _endDate == null
                          ? strings('filterEndDate')
                          : dateFormat.format(_endDate!.toDateTime()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null) ...<Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: Text(strings('filterClearAll')),
                ),
              ),
            ] else ...<Widget>[const SizedBox(height: AppSpacing.lg)],

            // Amount Range
            Text(
              '${strings('filterAmount')} (${currency.code.toUpperCase()})',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: strings('filterMinAmount'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text('~'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: strings('filterMaxAmount'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action button
            FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(strings('filterApply')),
            ),
          ],
        ),
      ),
    );
  }
}
