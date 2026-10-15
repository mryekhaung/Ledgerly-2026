import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/theme/app_typography.dart';
import 'package:ledgerly/features/budgets/domain/entities/budget_status.dart';
import 'package:ledgerly/features/budgets/presentation/widgets/budget_status_pill.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/app_test_host.dart';

/// `BudgetStatusPill` has two callers with opposite constraint shapes, and its
/// label has to survive both.
///
/// `budget_category_row.dart` bounds the pill (it wraps it in a `Flexible`) so
/// the label can give way at 2× type (`docs/Design.md` §8) — that is the shape
/// the second test below pins. `budget_summary_card.dart` instead puts the pill
/// straight into a `Row` as a non-flex child, which measures it with an
/// **unbounded** main axis — the first test. `RenderFlex` only allocates space
/// to flexible children when the main axis is bounded and otherwise lays them
/// out as if they were non-flex, so the label must render at its intrinsic width
/// there rather than being truncated.
void main() {
  const label = 'On Track';

  testWidgets('should_keep_its_full_label_in_an_unbounded_row', (tester) async {
    await pumpAppHost(
      tester,
      size: const Size(360, 200),
      home: const Row(
        children: <Widget>[
          // Reference: the same string at the same size, unconstrained.
          Text(label, style: AppTypography.overline),
          BudgetStatusPill(status: BudgetStatus.safe),
        ],
      ),
    );

    final reference = tester.getSize(find.text(label).first).width;
    final inPill = tester.getSize(find.text(label).last).width;

    expect(reference, greaterThan(0));
    expect(
      inPill,
      reference,
      reason:
          'The pill truncated its label inside an unbounded row — a `Flexible` '
          'there collapses to zero width.',
    );
  });

  testWidgets('should_ellipsize_its_label_when_the_caller_bounds_it', (
    tester,
  ) async {
    await pumpAppHost(
      tester,
      size: const Size(360, 200),
      textScaler: const TextScaler.linear(2),
      home: const Center(
        child: SizedBox(
          width: 60,
          child: BudgetStatusPill(status: BudgetStatus.exceeded),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.text('Over Budget')).width,
      greaterThan(0),
      reason: 'A bounded pill must shrink its label, not hide it.',
    );
  });
}
