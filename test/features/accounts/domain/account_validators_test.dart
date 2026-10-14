import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/accounts/domain/validators/account_validators.dart';

void main() {
  group('AccountValidators', () {
    test('nameError reports required for empty or whitespace', () {
      expect(AccountValidators.nameError(''), AccountValidators.nameRequired);
      expect(
        AccountValidators.nameError('   '),
        AccountValidators.nameRequired,
      );
    });

    test('nameError reports too long for names > 60 chars', () {
      final longName = 'A' * 61;
      expect(
        AccountValidators.nameError(longName),
        AccountValidators.nameTooLong,
      );
    });

    test('nameError detects duplicate names case-insensitively', () {
      const existing = ['Main Wallet', 'KBZ Bank'];
      expect(
        AccountValidators.nameError('main wallet', existingNames: existing),
        AccountValidators.nameTaken,
      );
      expect(
        AccountValidators.nameError('  KBZ BANK  ', existingNames: existing),
        AccountValidators.nameTaken,
      );
      expect(
        AccountValidators.nameError('Cash', existingNames: existing),
        isNull,
      );
    });

    test('transferError detects same from and to accounts', () {
      expect(
        AccountValidators.transferError(
          fromAccountId: 'acc-1',
          toAccountId: 'acc-1',
          amountMinor: 1000,
        ),
        AccountValidators.transferSameAccount,
      );
    });

    test('transferError detects zero or negative amounts', () {
      expect(
        AccountValidators.transferError(
          fromAccountId: 'acc-1',
          toAccountId: 'acc-2',
          amountMinor: 0,
        ),
        AccountValidators.transferAmountInvalid,
      );
      expect(
        AccountValidators.transferError(
          fromAccountId: 'acc-1',
          toAccountId: 'acc-2',
          amountMinor: -50,
        ),
        AccountValidators.transferAmountInvalid,
      );
      expect(
        AccountValidators.transferError(
          fromAccountId: 'acc-1',
          toAccountId: 'acc-2',
          amountMinor: 5000,
        ),
        isNull,
      );
    });
  });
}
