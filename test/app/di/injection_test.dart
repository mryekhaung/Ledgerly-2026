import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/di/app_environment.dart';
import 'package:ledgerly/app/di/injection.dart';
import 'package:ledgerly/core/database/app_database.dart';
import 'package:ledgerly/core/database/connection/database_connection.dart';
import 'package:ledgerly/core/database/daos/accounts_dao.dart';
import 'package:ledgerly/core/database/daos/app_settings_dao.dart';
import 'package:ledgerly/core/database/daos/budgets_dao.dart';
import 'package:ledgerly/core/database/daos/categories_dao.dart';
import 'package:ledgerly/core/database/daos/recurring_dao.dart';
import 'package:ledgerly/core/database/daos/savings_goals_dao.dart';
import 'package:ledgerly/core/database/daos/transactions_dao.dart';
import 'package:ledgerly/features/accounts/domain/repositories/account_repository.dart';
import 'package:ledgerly/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:ledgerly/features/auth/domain/repositories/auth_repository.dart';
import 'package:ledgerly/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:ledgerly/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:ledgerly/features/budgets/domain/repositories/budget_repository.dart';
import 'package:ledgerly/features/categories/domain/repositories/category_repository.dart';
import 'package:ledgerly/features/data_transfer/domain/repositories/data_transfer_repository.dart';
import 'package:ledgerly/features/goals/domain/repositories/savings_goals_repository.dart';
import 'package:ledgerly/features/insights/domain/repositories/insights_repository.dart';
import 'package:ledgerly/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:ledgerly/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:ledgerly/features/settings/domain/repositories/settings_repository.dart';
import 'package:ledgerly/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  setUp(() async {
    await resetDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  test('configureDependencies registers and resolves all services and DAOs without error', () async {
    await configureDependencies(
      environment: AppEnvironment.dev,
      connectionFactory: openInMemoryDatabase,
    );

    // Verify DAOs resolve without throwing
    expect(getIt<AppDatabase>(), isA<AppDatabase>());
    expect(getIt<AppSettingsDao>(), isA<AppSettingsDao>());
    expect(getIt<CategoriesDao>(), isA<CategoriesDao>());
    expect(getIt<TransactionsDao>(), isA<TransactionsDao>());
    expect(getIt<AccountsDao>(), isA<AccountsDao>());
    expect(getIt<BudgetsDao>(), isA<BudgetsDao>());
    expect(getIt<RecurringDao>(), isA<RecurringDao>());
    expect(getIt<SavingsGoalsDao>(), isA<SavingsGoalsDao>());

    // Verify Auth module dependencies resolve (the crash in user screenshot)
    expect(getIt<AuthLocalDataSource>(), isA<AuthLocalDataSource>());
    expect(getIt<AuthRepository>(), isA<AuthRepository>());
    expect(getIt<WatchAuthState>(), isA<WatchAuthState>());

    // Verify Budgets module resolves
    expect(getIt<BudgetLocalDataSource>(), isA<BudgetLocalDataSource>());
    expect(getIt<BudgetRepository>(), isA<BudgetRepository>());

    // Verify all other feature repositories resolve
    expect(getIt<CategoryRepository>(), isA<CategoryRepository>());
    expect(getIt<TransactionRepository>(), isA<TransactionRepository>());
    expect(getIt<InsightsRepository>(), isA<InsightsRepository>());
    expect(getIt<SettingsRepository>(), isA<SettingsRepository>());
    expect(getIt<UserProfileRepository>(), isA<UserProfileRepository>());
    expect(getIt<AccountRepository>(), isA<AccountRepository>());
    expect(getIt<DataTransferRepository>(), isA<DataTransferRepository>());
    expect(getIt<RecurringRepository>(), isA<RecurringRepository>());
    expect(getIt<SavingsGoalsRepository>(), isA<SavingsGoalsRepository>());
  });
}
