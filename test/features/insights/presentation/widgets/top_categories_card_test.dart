import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/money/currency_code.dart';
import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/widgets/amount_text.dart';
import 'package:ledgerly/features/insights/domain/entities/category_breakdown.dart';
import 'package:ledgerly/features/insights/presentation/widgets/top_categories_card.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/app_test_host.dart';
import '../../../categories/domain/fake_category_repository.dart';

/// `TopCategoriesCard` cannot be covered by the insights golden: the page body
/// is a lazy list, so at 360×900 the card sits below the fold and is never
/// built — neither the golden nor the width walk sees it, which is how its
/// overflow survived until the walk was added. It is exercised directly here.
///
/// The row is `[gem][name] … [pct][amount]`. At 2× type (`docs/Design.md` §8)
/// the amount alone is wider than the row, so the trailing pair is capped and
/// ellipsizes; at 1× the cap must not bind, or the amount — the actual data —
/// would be truncated on a screen that has room for it.
void main() {
  const mmk = CurrencyCode.mmk;
  const amountMinor = 412000;

  final breakdowns = <CategoryBreakdown>[
    CategoryBreakdown(
      category: fakeCategory(
        id: 'cat-food',
        name: 'Food & Dining',
        colorValue: 0xFFE8735A,
        iconKey: 'food',
      ),
      amountMinor: amountMinor,
      percentage: 0.42,
      currency: mmk,
    ),
  ];

  Future<void> host(WidgetTester tester, {double textScale = 1}) => pumpAppHost(
    tester,
    size: const Size(360, 400),
    textScaler: TextScaler.linear(textScale),
    home: Center(
      child: SizedBox(
        width: 360,
        child: TopCategoriesCard(breakdowns: breakdowns, currency: mmk),
      ),
    ),
  );

  for (final textScale in <double>[1, 2]) {
    testWidgets('should_not_overflow_at_text_scale_$textScale', (tester) async {
      await host(tester, textScale: textScale);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'TopCategoriesCard overflowed at 360 px, scale $textScale',
      );
    });
  }

  testWidgets('should_not_truncate_the_amount_where_the_row_fits', (
    tester,
  ) async {
    await host(tester);
    final rendered = tester.getSize(find.byType(AmountText));

    // The same amount as a non-flex child of a `Row`, so it is measured with an
    // unbounded main axis — i.e. at its intrinsic width.
    await pumpAppHost(
      tester,
      size: const Size(1200, 400),
      home: const Row(
        children: <Widget>[
          AmountText(
            Money.minor(amountMinor, mmk),
            style: AmountStyle.row,
            signed: false,
          ),
        ],
      ),
    );
    final intrinsic = tester.getSize(find.byType(AmountText));

    expect(
      rendered.width,
      intrinsic.width,
      reason: 'The cap bound at 1× and ellipsized the amount.',
    );
  });
}
