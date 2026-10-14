import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/result/failure.dart';
import 'package:ledgerly/core/result/result.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/accounts/domain/entities/account.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_transfer.dart';
import 'package:ledgerly/features/accounts/domain/entities/account_type.dart';
import 'package:ledgerly/features/accounts/domain/usecases/delete_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/get_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/reorder_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/save_account.dart';
import 'package:ledgerly/features/accounts/domain/usecases/set_account_archived.dart';
import 'package:ledgerly/features/accounts/domain/usecases/transfer_between_accounts.dart';
import 'package:ledgerly/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:ledgerly/features/accounts/presentation/account_catalog.dart';

// --- Bridge Providers ---

final watchAccountsUseCaseProvider = Provider<WatchAccounts>(
  (_) => getIt<WatchAccounts>(),
);

final getAccountUseCaseProvider = Provider<GetAccount>(
  (_) => getIt<GetAccount>(),
);

final saveAccountUseCaseProvider = Provider<SaveAccount>(
  (_) => getIt<SaveAccount>(),
);

final deleteAccountUseCaseProvider = Provider<DeleteAccount>(
  (_) => getIt<DeleteAccount>(),
);

final setAccountArchivedUseCaseProvider = Provider<SetAccountArchived>(
  (_) => getIt<SetAccountArchived>(),
);

final reorderAccountsUseCaseProvider = Provider<ReorderAccounts>(
  (_) => getIt<ReorderAccounts>(),
);

final transferBetweenAccountsUseCaseProvider =
    Provider<TransferBetweenAccounts>((_) => getIt<TransferBetweenAccounts>());

// --- Stream Providers ---

/// Stream of all active (non-archived) accounts.
final accountsStreamProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  final stream = ref.watch(watchAccountsUseCaseProvider)(
    const WatchAccountsParams(includeArchived: false),
  );
  return stream.map(
    (result) =>
        result.fold(onSuccess: (list) => list, onErr: (_) => const <Account>[]),
  );
});

/// Stream of archived accounts.
final archivedAccountsStreamProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
      final stream = ref.watch(watchAccountsUseCaseProvider)(
        const WatchAccountsParams(includeArchived: true),
      );
      return stream.map(
        (result) => result.fold(
          onSuccess: (list) => list.where((a) => a.isArchived).toList(),
          onErr: (_) => const <Account>[],
        ),
      );
    });

/// Stream of all accounts (both active and archived).
final allAccountsStreamProvider = StreamProvider.autoDispose<List<Account>>((
  ref,
) {
  final stream = ref.watch(watchAccountsUseCaseProvider)(
    const WatchAccountsParams(includeArchived: true),
  );
  return stream.map(
    (result) =>
        result.fold(onSuccess: (list) => list, onErr: (_) => const <Account>[]),
  );
});

/// Resolves a single account by id.
final accountByIdProvider = FutureProvider.autoDispose.family<Account?, String>(
  (ref, id) async {
    final result = await ref.watch(getAccountUseCaseProvider)(id);
    return switch (result) {
      Success(:final value) => value,
      Err(:final failure) => throw failure,
    };
  },
);

/// Total net worth calculated from active accounts included in total.
final totalNetWorthProvider = Provider.autoDispose<int>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const <Account>[];
  var total = 0;
  for (final a in accounts) {
    if (a.includeInTotal) {
      total += a.currentBalanceMinor;
    }
  }
  return total;
});

// --- Account Form State & Notifier ---

final class AccountFormState {
  const AccountFormState({
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalanceMinor,
    required this.iconKey,
    required this.colorValue,
    required this.includeInTotal,
    this.existingId,
    this.isSaving = false,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.saved = false,
  });

  factory AccountFormState.blank({
    String? defaultIconKey,
    int? defaultColorValue,
    CurrencyCode defaultCurrency = CurrencyCode.mmk,
  }) => AccountFormState(
    name: '',
    type: AccountType.cash,
    currency: defaultCurrency,
    openingBalanceMinor: 0,
    iconKey: defaultIconKey ?? AccountIcons.fallbackKey,
    colorValue: defaultColorValue ?? AccountPalette.fallbackColor,
    includeInTotal: true,
  );

  factory AccountFormState.from(Account account) => AccountFormState(
    name: account.name,
    type: account.type,
    currency: account.currency,
    openingBalanceMinor: account.openingBalanceMinor,
    iconKey: account.iconKey,
    colorValue: account.colorValue,
    includeInTotal: account.includeInTotal,
    existingId: account.id,
  );

  final String name;
  final AccountType type;
  final CurrencyCode currency;
  final int openingBalanceMinor;
  final String iconKey;
  final int colorValue;
  final bool includeInTotal;
  final String? existingId;
  final bool isSaving;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final bool saved;

  bool get isEditing => existingId != null;

  Account toEntity({required int sortOrder}) => Account(
    id: existingId ?? '',
    name: name,
    type: type,
    currency: currency,
    openingBalanceMinor: openingBalanceMinor,
    currentBalanceMinor: openingBalanceMinor,
    iconKey: iconKey,
    colorValue: colorValue,
    sortOrder: sortOrder,
    isArchived: false,
    includeInTotal: includeInTotal,
    createdAt: 0,
    updatedAt: 0,
  );

  AccountFormState copyWith({
    String? name,
    AccountType? type,
    CurrencyCode? currency,
    int? openingBalanceMinor,
    String? iconKey,
    int? colorValue,
    bool? includeInTotal,
    String? existingId,
    bool? isSaving,
    Map<String, String>? fieldErrors,
    Failure? failure,
    bool clearFailure = false,
    bool? saved,
  }) => AccountFormState(
    name: name ?? this.name,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    includeInTotal: includeInTotal ?? this.includeInTotal,
    existingId: existingId ?? this.existingId,
    isSaving: isSaving ?? this.isSaving,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
  );
}

class AccountFormNotifier extends Notifier<AccountFormState> {
  @override
  AccountFormState build() => AccountFormState.blank();

  void initialise({Account? existing, CurrencyCode? defaultCurrency}) {
    state = existing == null
        ? AccountFormState.blank(
            defaultCurrency: defaultCurrency ?? CurrencyCode.mmk,
          )
        : AccountFormState.from(existing);
  }

  void setName(String value) => state = state.copyWith(
    name: value,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  void setType(AccountType type) => state = state.copyWith(
    type: type,
    iconKey: type.defaultIconKey,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  void setCurrency(CurrencyCode currency) =>
      state = state.copyWith(currency: currency, clearFailure: true);

  void setOpeningBalance(int minor) =>
      state = state.copyWith(openingBalanceMinor: minor, clearFailure: true);

  void setIcon(String iconKey) =>
      state = state.copyWith(iconKey: iconKey, clearFailure: true);

  void setColor(int colorValue) =>
      state = state.copyWith(colorValue: colorValue, clearFailure: true);

  void setIncludeInTotal(bool value) =>
      state = state.copyWith(includeInTotal: value, clearFailure: true);

  Future<bool> save() async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearFailure: true);

    final account = state.toEntity(sortOrder: 0);
    final result = await ref.read(saveAccountUseCaseProvider)(
      SaveAccountParams(account: account, isNew: !state.isEditing),
    );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isSaving: false, saved: true);
        return true;
      },
      onErr: (f) {
        if (f is ValidationFailure) {
          state = state.copyWith(
            isSaving: false,
            fieldErrors: f.fieldErrors,
            failure: f,
          );
        } else {
          state = state.copyWith(isSaving: false, failure: f);
        }
        return false;
      },
    );
  }
}

final accountFormNotifierProvider =
    NotifierProvider.autoDispose<AccountFormNotifier, AccountFormState>(
      AccountFormNotifier.new,
    );

// --- Transfer Form State & Notifier ---

final class TransferFormState {
  const TransferFormState({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountMinor,
    required this.date,
    this.note = '',
    this.isSubmitting = false,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.isSuccess = false,
  });

  factory TransferFormState.initial({
    String? fromId,
    String? toId,
    LocalDate? date,
  }) => TransferFormState(
    fromAccountId: fromId ?? '',
    toAccountId: toId ?? '',
    amountMinor: 0,
    date: date ?? LocalDate.fromDateTime(DateTime.now()),
  );

  final String fromAccountId;
  final String toAccountId;
  final int amountMinor;
  final LocalDate date;
  final String note;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final bool isSuccess;

  TransferFormState copyWith({
    String? fromAccountId,
    String? toAccountId,
    int? amountMinor,
    LocalDate? date,
    String? note,
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    Failure? failure,
    bool clearFailure = false,
    bool? isSuccess,
  }) => TransferFormState(
    fromAccountId: fromAccountId ?? this.fromAccountId,
    toAccountId: toAccountId ?? this.toAccountId,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    note: note ?? this.note,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    failure: clearFailure ? null : (failure ?? this.failure),
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class TransferNotifier extends Notifier<TransferFormState> {
  @override
  TransferFormState build() => TransferFormState.initial();

  void initialise({String? defaultFromId, String? defaultToId}) {
    state = TransferFormState.initial(fromId: defaultFromId, toId: defaultToId);
  }

  void setFromAccount(String id) => state = state.copyWith(
    fromAccountId: id,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  void setToAccount(String id) => state = state.copyWith(
    toAccountId: id,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  void setAmount(int minor) => state = state.copyWith(
    amountMinor: minor,
    fieldErrors: const <String, String>{},
    clearFailure: true,
  );

  void setDate(LocalDate date) =>
      state = state.copyWith(date: date, clearFailure: true);

  void setNote(String note) =>
      state = state.copyWith(note: note, clearFailure: true);

  Future<bool> submit({required CurrencyCode currency}) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final transfer = AccountTransfer(
      fromAccountId: state.fromAccountId,
      toAccountId: state.toAccountId,
      amount: Money.minor(state.amountMinor, currency),
      date: state.date,
      note: state.note.trim().isEmpty ? null : state.note.trim(),
    );

    final result = await ref.read(transferBetweenAccountsUseCaseProvider)(
      transfer,
    );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isSubmitting: false, isSuccess: true);
        return true;
      },
      onErr: (Failure f) {
        if (f is ValidationFailure) {
          state = state.copyWith(
            isSubmitting: false,
            fieldErrors: f.fieldErrors,
            failure: f,
          );
        } else {
          state = state.copyWith(isSubmitting: false, failure: f);
        }
        return false;
      },
    );
  }
}

final transferNotifierProvider =
    NotifierProvider.autoDispose<TransferNotifier, TransferFormState>(
      TransferNotifier.new,
    );

// --- Account Action Notifier ---

class AccountActionNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<bool> deleteAccount(String id) async {
    final result = await ref.read(deleteAccountUseCaseProvider)(id);
    return result.isSuccess;
  }

  Future<bool> setArchived(String id, bool isArchived) async {
    final result = await ref.read(setAccountArchivedUseCaseProvider)(
      SetAccountArchivedParams(id: id, isArchived: isArchived),
    );
    return result.isSuccess;
  }

  Future<bool> reorder(List<String> orderedIds) async {
    final result = await ref.read(reorderAccountsUseCaseProvider)(orderedIds);
    return result.isSuccess;
  }
}

final accountActionNotifierProvider =
    NotifierProvider.autoDispose<AccountActionNotifier, void>(
      AccountActionNotifier.new,
    );
