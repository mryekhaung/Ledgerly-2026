import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/theme/app_icons.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/app_date_picker.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/transfer/accounts_section.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/transfer/details_section.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:ledgerly/l10n/app_localization.dart';
import 'package:material_ui/material_ui.dart';

/// Page for executing an atomic fund transfer between two accounts.
///
/// Composition root only: selectors and fields live in `widgets/transfer/`
/// (`docs/Conventions.md` §1).
class TransferPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const TransferPage({this.initialFromId, this.initialToId, super.key});

  /// The pre-selected source account.
  final String? initialFromId;

  /// The pre-selected destination account.
  final String? initialToId;

  @override
  ConsumerState<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends ConsumerState<TransferPage> {
  bool _initialized = false;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initForm(List<Account> accounts) {
    if (_initialized || accounts.isEmpty) return;
    _initialized = true;

    String? from = widget.initialFromId;
    String? to = widget.initialToId;

    if (from == null && accounts.isNotEmpty) {
      from = accounts.first.id;
    }
    if (to == null && accounts.length > 1) {
      to = accounts
          .firstWhere((a) => a.id != from, orElse: () => accounts.last)
          .id;
    }

    final notifier = ref.read(transferNotifierProvider.notifier);
    notifier.initialise(defaultFromId: from, defaultToId: to);
  }

  void _swapAccounts() {
    final state = ref.read(transferNotifierProvider);
    final notifier = ref.read(transferNotifierProvider.notifier);
    final temp = state.fromAccountId;
    notifier.setFromAccount(state.toAccountId);
    notifier.setToAccount(temp);
  }

  void _onAmountChanged(String text, Account? fromAccount) {
    final parsed = double.tryParse(text.trim()) ?? 0.0;
    final currency = fromAccount?.currency;
    final exponent = currency?.exponent ?? 0;
    final minor = (parsed * (exponent == 0 ? 1 : 100)).round();
    ref.read(transferNotifierProvider.notifier).setAmount(minor);
  }

  Future<void> _pickDate(LocalDate currentDate) async {
    final now = DateTime.now();
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      ),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      ref
          .read(transferNotifierProvider.notifier)
          .setDate(LocalDate(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _handleSubmit() async {
    final fromAccount = ref
        .read(accountsStreamProvider)
        .value
        ?.where((a) => a.id == ref.read(transferNotifierProvider).fromAccountId)
        .firstOrNull;
    if (fromAccount == null) return;

    final strings = AppStrings.of(context);
    final success = await ref
        .read(transferNotifierProvider.notifier)
        .submit(currency: fromAccount.currency);
    if (success && mounted) {
      AppFeedback.success();
      AppFeedback.confirm(context, message: strings('accountsTransferSuccess'));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppThemeColors.of(context);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final formState = ref.watch(transferNotifierProvider);
    final notifier = ref.read(transferNotifierProvider.notifier);

    return AppScaffold(
      title: strings('accountsTransferTitle'),
      body: accountsAsync.when(
        loading: () => const LoadingPlaceholder(),
        error: (_, _) => StatePlaceholder(
          icon: AppIcons.error,
          title: strings('stateErrorTitle'),
          body: strings('stateErrorBody'),
        ),
        data: (accounts) {
          if (!_initialized) {
            if (accounts.length < 2) {
              _initialized = true;
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_initialized) {
                  _initForm(accounts);
                  setState(() {});
                }
              });
              return const LoadingPlaceholder();
            }
          }

          if (accounts.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  strings('accountsEmptyBody'),
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final fromAccount = accounts
              .where((a) => a.id == formState.fromAccountId)
              .firstOrNull;

          final sameAccountError =
              formState.fieldErrors['toAccountId'] ??
              formState.fieldErrors['fromAccountId'];
          final amountError = formState.fieldErrors['amount'];

          final errorBanner = sameAccountError != null
              ? strings(AppLocalization.validationKeyFor(sameAccountError))
              : (amountError != null
                    ? strings(AppLocalization.validationKeyFor(amountError))
                    : null);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (errorBanner != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.warningSubtle,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(AppIcons.error, color: colors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          errorBanner,
                          style: AppTypography.body.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // From & To Selectors with Swap button
              TransferAccountsSection(
                accounts: accounts,
                fromAccountId: formState.fromAccountId,
                toAccountId: formState.toAccountId,
                onFromChanged: notifier.setFromAccount,
                onToChanged: notifier.setToAccount,
                onSwap: _swapAccounts,
              ),

              const SizedBox(height: AppSpacing.xl),

              TransferDetailsSection(
                amountController: _amountController,
                noteController: _noteController,
                fromAccount: fromAccount,
                date: formState.date,
                onAmountChanged: (text) => _onAmountChanged(text, fromAccount),
                onPickDate: () => _pickDate(formState.date),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: formState.isSubmitting ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brandPrimary,
              foregroundColor: colors.textOnBrand,
              minimumSize: const Size.fromHeight(52),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderLg,
              ),
            ),
            child: formState.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings('accountsTransferSubmit')),
          ),
        ),
      ),
    );
  }
}
