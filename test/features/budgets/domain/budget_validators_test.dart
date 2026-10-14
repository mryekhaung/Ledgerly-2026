import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/budgets/domain/validators/budget_validators.dart';

void main() {
  group('BudgetValidators', () {
    test('validateAmount rejects non-positive amounts', () {
      expect(
        BudgetValidators.validateAmount(0),
        BudgetValidators.amountInvalid,
      );
      expect(
        BudgetValidators.validateAmount(-500),
        BudgetValidators.amountInvalid,
      );
      expect(BudgetValidators.validateAmount(1000), isNull);
    });

    test('validateThreshold rejects outside [0.1, 1.0]', () {
      expect(
        BudgetValidators.validateThreshold(0.05),
        BudgetValidators.thresholdInvalid,
      );
      expect(
        BudgetValidators.validateThreshold(1.1),
        BudgetValidators.thresholdInvalid,
      );
      expect(BudgetValidators.validateThreshold(0.8), isNull);
    });
  });
}
