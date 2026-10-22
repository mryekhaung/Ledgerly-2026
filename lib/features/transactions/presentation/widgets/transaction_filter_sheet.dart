import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/month_day_picker_page.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/categories/presentation/providers/category_providers.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ledgerly/features/transactions/presentation/pages/category_picker_page.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/filter_sheet/amount_range_section.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/filter_sheet/category_section.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/filter_sheet/date_range_section.dart';
import 'package:ledgerly/features/transactions/presentation/widgets/filter_sheet/direction_section.dart';
import 'package:material_ui/material_ui.dart';

/// Modal bottom sheet allowing users to configure detailed search/filter options.
///
/// Composition root only: sections live in `widgets/filter_sheet/`
/// (`docs/Conventions.md` §1).
class TransactionFilterSheet extends ConsumerStatefulWidget {
  /// Creates the sheet.
  const TransactionFilterSheet({
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  /// The filter to start from.
  final TransactionFilter initialFilter;

  /// Called with the applied filter.
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
      cupertino.CupertinoPageRoute<Category>(
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
      cupertino.CupertinoPageRoute<LocalDate>(
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
      cupertino.CupertinoPageRoute<LocalDate>(
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
        borderRadius: const BorderRadius.vertical(top: AppRadius.radiusLg),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(strings('filterClearAll')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            FilterDirectionSection(
              direction: _direction,
              onChanged: (direction) {
                setState(() => _direction = direction);
              },
            ),
            FilterCategorySection(
              selectedCategory: selectedCategory,
              onPick: _pickCategory,
              onClear: () => setState(() => _categoryId = null),
            ),
            FilterDateRangeSection(
              startDate: _startDate,
              endDate: _endDate,
              dateFormat: dateFormat,
              onPickStart: _pickStartDate,
              onPickEnd: _pickEndDate,
              onClear: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
            ),
            FilterAmountRangeSection(
              minController: _minAmountController,
              maxController: _maxAmountController,
              currency: currency,
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
