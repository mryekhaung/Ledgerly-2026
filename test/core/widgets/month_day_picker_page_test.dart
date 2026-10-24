import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/core/widgets/month_day_picker_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/app_test_host.dart';

void main() {
  testWidgets('should return a selected date within the configured range', (
    tester,
  ) async {
    final result = Completer<LocalDate?>();
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final picked = await context.pushNamed<LocalDate>(
                    'datePicker',
                  );
                  if (!result.isCompleted) result.complete(picked);
                },
                child: const Text('Open date picker'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/date',
          name: 'datePicker',
          builder: (context, state) => MonthDayPickerPage(
            initialDate: LocalDate(2026, 1, 10),
            firstDate: LocalDate(2026, 1, 15),
            lastDate: LocalDate(2026, 1, 20),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await pumpAppHost(tester, router: router);
    await tester.tap(find.text('Open date picker'));
    await tester.pumpAndSettle();

    final disabledDay = find.text('14');
    await tester.tap(disabledDay);
    await tester.pumpAndSettle();
    expect(find.text('Open date picker'), findsNothing);
    expect(result.isCompleted, isFalse);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(await result.future, LocalDate(2026, 1, 15));
  });
}
