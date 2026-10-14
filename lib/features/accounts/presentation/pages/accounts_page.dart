import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/app/router/app_routes.dart';
import 'package:ledgerly/app/theme/app_spacing.dart';
import 'package:ledgerly/app/theme/app_theme.dart';
import 'package:ledgerly/core/presentation/app_strings.dart';
import 'package:ledgerly/core/widgets/app_scaffold.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/presentation/providers/account_providers.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/account_card.dart';
import 'package:ledgerly/features/accounts/presentation/widgets/net_worth_card.dart';
import 'package:ledgerly/features/shared/presentation/feedback/app_feedback.dart';
import 'package:ledgerly/features/shared/presentation/widgets/state_placeholder.dart';
import 'package:material_ui/material_ui.dart';

/// The Accounts & Wallets management page.
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToAdd() {
    unawaited(context.pushNamed(AppRoutes.accountNewName));
  }

  void _navigateToTransfer({String? fromId}) {
    unawaited(
      context.pushNamed(
        AppRoutes.accountTransferName,
        queryParameters: fromId != null
            ? <String, dynamic>{'from': fromId}
            : const <String, dynamic>{},
      ),
    );
  }

  void _navigateToEdit(String id) {
    unawaited(
      context.pushNamed(
        AppRoutes.accountEditName,
        pathParameters: <String, String>{'id': id},
      ),
    );
  }

  Future<void> _handleDelete(
    Account account,
    String Function(String) strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings('accountConfirmDelete')),
        content: Text(strings('accountConfirmDeleteMessage')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.of(context).warning,
            ),
            child: Text(strings('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppFeedback.destructive();
      final success = await ref
          .read(accountActionNotifierProvider.notifier)
          .deleteAccount(account.id);
      if (success && mounted) {
        AppFeedback.confirm(context, message: strings('accountDeletedSuccess'));
      }
    }
  }

  Future<void> _handleToggleArchive(
    Account account,
    String Function(String) strings,
  ) async {
    final newArchived = !account.isArchived;
    final success = await ref
        .read(accountActionNotifierProvider.notifier)
        .setArchived(account.id, newArchived);

    if (success && mounted) {
      AppFeedback.success();
      AppFeedback.confirm(
        context,
        message: newArchived
            ? strings('accountArchiveSuccess')
            : strings('accountUnarchiveSuccess'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final strings = AppStrings.of(context);
    final activeAccountsAsync = ref.watch(accountsStreamProvider);
    final archivedAccountsAsync = ref.watch(archivedAccountsStreamProvider);

    return AppScaffold(
      title: strings('accountsTitle'),
      bottom: TabBar(
        controller: _tabController,
        labelColor: colors.brandPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.brandPrimary,
        tabs: <Widget>[
          Tab(text: strings('accountsActiveTab')),
          Tab(text: strings('accountsArchivedTab')),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: strings('accountsTransferButton'),
          onPressed: _navigateToTransfer,
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          // Active Accounts Tab
          activeAccountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => StatePlaceholder(
              icon: Icons.error_outline,
              title: strings('stateErrorTitle'),
              body: strings('stateErrorBody'),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return StatePlaceholder(
                  icon: Icons.account_balance_wallet_outlined,
                  title: strings('accountsEmptyTitle'),
                  body: strings('accountsEmptyBody'),
                  action: FilledButton.icon(
                    onPressed: _navigateToAdd,
                    icon: const Icon(Icons.add),
                    label: Text(strings('accountsAddButton')),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: <Widget>[
                  NetWorthCard(
                    onTransfer: _navigateToTransfer,
                    onAddAccount: _navigateToAdd,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...accounts.map(
                    (account) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AccountCard(
                        account: account,
                        onTap: () => _navigateToEdit(account.id),
                        onEdit: () => _navigateToEdit(account.id),
                        onTransfer: () =>
                            _navigateToTransfer(fromId: account.id),
                        onArchiveToggle: () =>
                            _handleToggleArchive(account, strings),
                        onDelete: () => _handleDelete(account, strings),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Archived Accounts Tab
          archivedAccountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => StatePlaceholder(
              icon: Icons.error_outline,
              title: strings('stateErrorTitle'),
              body: strings('stateErrorBody'),
            ),
            data: (archived) {
              if (archived.isEmpty) {
                return StatePlaceholder(
                  icon: Icons.archive_outlined,
                  title: strings('accountsEmptyTitle'),
                  body: strings('accountsArchivedTab'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: archived.length,
                itemBuilder: (context, index) {
                  final account = archived[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AccountCard(
                      account: account,
                      onTap: () => _navigateToEdit(account.id),
                      onEdit: () => _navigateToEdit(account.id),
                      onArchiveToggle: () =>
                          _handleToggleArchive(account, strings),
                      onDelete: () => _handleDelete(account, strings),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: activeAccountsAsync.maybeWhen(
        data: (accounts) => accounts.isNotEmpty
            ? FloatingActionButton(
                onPressed: _navigateToAdd,
                backgroundColor: colors.brandPrimary,
                foregroundColor: colors.textOnBrand,
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
