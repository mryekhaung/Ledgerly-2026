import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_button.dart';
import 'package:ledgerly/core/widgets/app_dialog.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/core/widgets/app_select_field.dart';
import 'package:ledgerly/core/widgets/app_switch_tile.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';
import 'package:ledgerly/features/accounts/presentation/account_catalog.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/account_form/account_color_swatch.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/account_form/account_preview_card.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/account_form/field_label.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/account_form/selectable_cell.dart';
import 'package:ledgerly/features/settings/presentation/providers/settings_providers.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Page for adding or editing an account.
///
/// Composition root only: preview, labels and picker cells live in
/// `widgets/account_form/` (`docs/Conventions.md` §1).
class AccountFormPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const AccountFormPage({this.accountId, super.key});

  /// The account being edited, or null when creating.
  final String? accountId;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  bool _initialized = false;
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController(text: '0');
    if (widget.accountId == null) {
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _initForm(Account? existing) {
    if (_initialized) return;
    _initialized = true;

    final defaultCurrency = ref.read(currencyProvider);
    ref
        .read(accountFormNotifierProvider.notifier)
        .initialise(existing: existing, defaultCurrency: defaultCurrency);

    if (existing != null) {
      _nameController.text = existing.name;
      final exponent = existing.currency.exponent;
      final doubleVal =
          existing.openingBalanceMinor / (exponent == 0 ? 1 : 100);
      _balanceController.text = exponent == 0
          ? existing.openingBalanceMinor.toString()
          : doubleVal.toStringAsFixed(exponent);
    }
  }

  Future<void> _handleSave() async {
    final strings = AppStrings.of(context);
    final success = await ref.read(accountFormNotifierProvider.notifier).save();
    if (success && mounted) {
      AppFeedback.success();
      AppFeedback.confirm(context, message: strings('accountSavedSuccess'));
      context.pop();
    }
  }

  Future<void> _handleDelete() async {
    final accountId = widget.accountId;
    if (accountId == null) return;

    final strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings('accountConfirmDelete'),
      message: strings('accountConfirmDeleteMessage'),
      confirmLabel: strings('actionDelete'),
      cancelLabel: strings('actionCancel'),
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      AppFeedback.destructive();
      final success = await ref
          .read(accountActionNotifierProvider.notifier)
          .deleteAccount(accountId);
      if (success && mounted) {
        AppFeedback.confirm(context, message: strings('accountDeletedSuccess'));
        context.pop();
      }
    }
  }

  void _onBalanceChanged(String text, CurrencyCode currency) {
    final parsed = double.tryParse(text.trim()) ?? 0.0;
    final exponent = currency.exponent;
    final minor = (parsed * (exponent == 0 ? 1 : 100)).round();
    ref.read(accountFormNotifierProvider.notifier).setOpeningBalance(minor);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final formState = ref.watch(accountFormNotifierProvider);
    final accountId = widget.accountId;

    if (accountId != null && !_initialized) {
      final accountAsync = ref.watch(accountByIdProvider(accountId));
      return accountAsync.when(
        loading: () => const AppScaffold(body: LoadingPlaceholder()),
        error: (err, _) => AppScaffold(
          body: StatePlaceholder(
            icon: AppIcons.error,
            title: strings('stateErrorTitle'),
            body: strings('stateErrorBody'),
          ),
        ),
        data: (account) {
          if (account != null && !_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_initialized) {
                _initForm(account);
                setState(() {});
              }
            });
            return const AppScaffold(body: LoadingPlaceholder());
          }
          return _buildScaffold(context, formState);
        },
      );
    }
    return _buildScaffold(context, formState);
  }

  Widget _buildScaffold(BuildContext context, AccountFormState formState) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final notifier = ref.read(accountFormNotifierProvider.notifier);

    final nameErrorKey = formState.fieldErrors['accountName'];
    final nameErrorText = nameErrorKey != null
        ? strings(AppLocalization.validationKeyFor(nameErrorKey))
        : null;

    final typeLabel = switch (formState.type.name) {
      'cash' => strings('accountTypeCash'),
      'bank' => strings('accountTypeBank'),
      'credit' => strings('accountTypeCredit'),
      'savings' => strings('accountTypeSavings'),
      'ewallet' => strings('accountTypeEwallet'),
      _ => formState.type.name,
    };

    return AppScaffold(
      title: formState.isEditing
          ? strings('accountsEditTitle')
          : strings('accountsNewTitle'),
      actions: <Widget>[
        if (formState.isEditing)
          IconButton(
            icon: Icon(AppIcons.destructive, color: colors.warning),
            tooltip: strings('accountDeleteTitle'),
            onPressed: _handleDelete,
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          // Preview Card
          AccountPreviewCard(
            name: formState.name,
            typeLabel: typeLabel,
            openingBalanceMinor: formState.openingBalanceMinor,
            currency: formState.currency,
            colorValue: formState.colorValue,
            iconKey: formState.iconKey,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Account Name
          FieldLabel(label: strings('accountFieldName')),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _nameController,
            maxLength: 60,
            textInputAction: TextInputAction.next,
            onChanged: notifier.setName,
            decoration: InputDecoration(
              hintText: strings('accountNameHint'),
              errorText: nameErrorText,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Account Type
          FieldLabel(label: strings('accountFieldType')),
          const SizedBox(height: AppSpacing.xs),
          AppSelectField<AccountType>(
            value: formState.type,
            options: AccountType.values.map((type) {
              final label = switch (type.name) {
                'cash' => strings('accountTypeCash'),
                'bank' => strings('accountTypeBank'),
                'credit' => strings('accountTypeCredit'),
                'savings' => strings('accountTypeSavings'),
                'ewallet' => strings('accountTypeEwallet'),
                _ => type.name,
              };
              return AppSelectOption<AccountType>(
                value: type,
                child: Text(label),
              );
            }).toList(),
            decoration: const InputDecoration(),
            onChanged: (val) {
              if (val != null) notifier.setType(val);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Currency
          FieldLabel(label: strings('accountFieldCurrency')),
          const SizedBox(height: AppSpacing.xs),
          AppSelectField<CurrencyCode>(
            value: formState.currency,
            options: CurrencyCode.values.map((currency) {
              return AppSelectOption<CurrencyCode>(
                value: currency,
                child: Text(
                  '${currency.symbol}   ${currency.code} (${currency.name.toUpperCase()})',
                ),
              );
            }).toList(),
            decoration: const InputDecoration(),
            onChanged: (val) {
              if (val != null) {
                notifier.setCurrency(val);
                _onBalanceChanged(_balanceController.text, val);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Opening Balance
          FieldLabel(label: strings('accountFieldOpeningBalance')),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textInputAction: TextInputAction.done,
            onChanged: (text) => _onBalanceChanged(text, formState.currency),
            decoration: InputDecoration(
              prefixText: '${formState.currency.symbol} ',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Include in Net Worth toggle
          AppSwitchTile(
            value: formState.includeInTotal,
            onChanged: notifier.setIncludeInTotal,
            title: Text(
              strings('accountFieldIncludeInTotal'),
              style: AppTypography.textTheme(colors).bodyMedium,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Icon Picker
          FieldLabel(label: strings('accountFieldIcon')),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final key in AccountIcons.keys)
                SelectableCell(
                  isSelected: key == formState.iconKey,
                  onTap: () => notifier.setIcon(key),
                  child: Icon(
                    AccountIcons.iconFor(key),
                    size: 20,
                    color: key == formState.iconKey
                        ? colors.textOnBrand
                        : colors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Color Picker
          FieldLabel(label: strings('accountFieldColor')),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final colorVal in AccountPalette.colors)
                AccountColorSwatch(
                  color: Color(colorVal),
                  isSelected: colorVal == formState.colorValue,
                  onTap: () => notifier.setColor(colorVal),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            label: strings('actionSave'),
            onPressed: formState.isSaving ? null : _handleSave,
            isLoading: formState.isSaving,
            isExpanded: true,
          ),
        ),
      ),
    );
  }
}
