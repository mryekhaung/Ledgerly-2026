import 'package:ledgerly/core/utils/local_date.dart';
import 'package:ledgerly/features/categories/domain/entities/category.dart';
import 'package:ledgerly/features/categories/domain/entities/category_kind.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction.dart';
import 'package:ledgerly/features/transactions/domain/entities/transaction_direction.dart';

import '../features/categories/domain/fake_category_repository.dart';
import '../features/transactions/domain/fake_transaction_repository.dart';

/// A month with activity spread across **all five capsule intensity steps**.
///
/// Shared by `calendar_golden_test.dart` and `calendar_page_test.dart` so the
/// grid's signature texture — the whole point of the component — is exercised by
/// the unit tests as well as rendered in the goldens.
///
/// ## Why this exists
///
/// Both calendar fixtures used to seed **one** day. Every Calendar screenshot
/// the owner reviewed therefore showed a single capsule bar, and the grid read
/// as a bare list of numbers: the 5-step ramp in `docs/Design.md` §6.2 had never
/// once been rendered, so it had never once been judged (§M.8).
///
/// ## How the steps fall out
///
/// Intensity is `|net| / p95` quantised to 5 steps, where `p95` is the
/// 95th-percentile absolute net of the period (`MonthGrid._intensities`).
/// Fourteen active days give `p95Index = (14 - 1) * 0.95 → 12`, so `p95` is the
/// 13th-smallest net — **180,000**. Against that:
///
/// | day   | net (MMK) | `|net| / p95` | step | direction |
/// | ----- | --------- | ------------ | ---- | --------- |
/// | Oct 1 |      2000 |        0.011 |    0 | expense   |
/// | Oct 2 |      5000 |        0.028 |    0 | expense   |
/// | Oct 4 |      9000 |        0.050 |    0 | expense   |
/// | Oct 5 |     12000 |        0.067 |    0 | expense   |
/// | Oct 6 |     15000 |        0.083 |    0 | expense   |
/// | Oct 7 |     28000 |        0.156 |    1 | expense   |
/// | Oct 8 |     32000 |        0.178 |    1 | expense   |
/// | Oct 9 |     40000 |        0.222 |    1 | expense   |
/// | Oct 10|     70000 |        0.389 |    2 | expense   |
/// | Oct 11|     95000 |        0.528 |    2 | expense   |
/// | Oct 12|    140000 |        0.778 |    3 | expense   |
/// | Oct 13|    180000 |        1.000 |    4 | expense   |
/// | Oct 14|     95000 |        0.528 |    2 | income    |
/// | Oct 3 |    495500 |   (clamped)  |    4 | income    |
///
/// Three things the numbers are chosen for, each easy to lose in an edit:
///
/// * **Oct 3, the selected day, is step 4.** The selected cell is the one place
///   the capsule is repainted `onSelectedFill` (§6.2, §M.5), so a fixture whose
///   selected day had no capsule would render that rule untestable.
/// * **Oct 14 is the only mid-ramp income day.** Every other active day is
///   `expense`, so without it the green half of the ramp would only ever be
///   drawn at step 4.
/// * **Oct 13 is the `p95` day itself**, so the ramp's top step is reached by a
///   day that is *not* the selected one — the two heaviest days on the grid are
///   distinguishable instead of both saturating.
///
/// [selectedDay] keeps its original two transactions (a small expense plus a
/// salary) so the summary card and the day list under the grid are unchanged
/// from the one-active-day fixture — only the *grid* gets richer.
List<Transaction> calendarGridTransactions({required LocalDate selectedDay}) {
  return <Transaction>[
    fakeTransaction(
      id: 'txn-coffee',
      categoryId: 'cat-food',
      amountMinor: 4500,
      date: selectedDay,
      note: 'Morning coffee',
    ),
    fakeTransaction(
      id: 'txn-pay',
      categoryId: 'cat-salary',
      amountMinor: 500000,
      direction: TransactionDirection.income,
      date: selectedDay,
    ),
    // Step 0 — activity too small to clear the first quantile.
    fakeTransaction(
      id: 'txn-oct1',
      categoryId: 'cat-transport',
      amountMinor: 2000,
      date: LocalDate(selectedDay.year, selectedDay.month, 1),
    ),
    fakeTransaction(
      id: 'txn-oct2',
      categoryId: 'cat-food',
      amountMinor: 5000,
      date: LocalDate(selectedDay.year, selectedDay.month, 2),
    ),
    fakeTransaction(
      id: 'txn-oct4',
      categoryId: 'cat-food',
      amountMinor: 9000,
      date: LocalDate(selectedDay.year, selectedDay.month, 4),
    ),
    fakeTransaction(
      id: 'txn-oct5',
      categoryId: 'cat-groceries',
      amountMinor: 12000,
      date: LocalDate(selectedDay.year, selectedDay.month, 5),
    ),
    fakeTransaction(
      id: 'txn-oct6',
      categoryId: 'cat-shopping',
      amountMinor: 15000,
      date: LocalDate(selectedDay.year, selectedDay.month, 6),
    ),
    // Step 1.
    fakeTransaction(
      id: 'txn-oct7',
      categoryId: 'cat-rent',
      amountMinor: 28000,
      date: LocalDate(selectedDay.year, selectedDay.month, 7),
    ),
    fakeTransaction(
      id: 'txn-oct8',
      categoryId: 'cat-rent',
      amountMinor: 32000,
      date: LocalDate(selectedDay.year, selectedDay.month, 8),
    ),
    fakeTransaction(
      id: 'txn-oct9',
      categoryId: 'cat-utilities',
      amountMinor: 40000,
      date: LocalDate(selectedDay.year, selectedDay.month, 9),
    ),
    // Step 2, including the mid-ramp income day.
    fakeTransaction(
      id: 'txn-oct10',
      categoryId: 'cat-insurance',
      amountMinor: 70000,
      date: LocalDate(selectedDay.year, selectedDay.month, 10),
    ),
    fakeTransaction(
      id: 'txn-oct11',
      categoryId: 'cat-car',
      amountMinor: 95000,
      date: LocalDate(selectedDay.year, selectedDay.month, 11),
    ),
    fakeTransaction(
      id: 'txn-oct14',
      categoryId: 'cat-freelance',
      amountMinor: 95000,
      direction: TransactionDirection.income,
      date: LocalDate(selectedDay.year, selectedDay.month, 14),
    ),
    // Step 3.
    fakeTransaction(
      id: 'txn-oct12',
      categoryId: 'cat-tuition',
      amountMinor: 140000,
      date: LocalDate(selectedDay.year, selectedDay.month, 12),
    ),
    // Step 4 — the day `p95` is taken from.
    fakeTransaction(
      id: 'txn-oct13',
      categoryId: 'cat-travel',
      amountMinor: 180000,
      date: LocalDate(selectedDay.year, selectedDay.month, 13),
    ),
  ];
}

/// Every category [calendarGridTransactions] references.
///
/// `categoryByIdProvider` resolves through `firstWhere`, so a category the
/// fixture spends on but does not list throws rather than degrading.
///
/// The `iconKey`s are canonical keys from `CategoryIcons.keys`, not the Material
/// names `fakeCategory` defaults to — an unknown key silently renders the
/// fallback tag, which is exactly the kind of quiet wrongness a fixture should
/// not teach.
final List<Category> calendarGridCategories = <Category>[
  fakeCategory(id: 'cat-food', name: 'Food', iconKey: 'food'),
  fakeCategory(
    id: 'cat-salary',
    name: 'Salary',
    kind: CategoryKind.income,
    iconKey: 'salary',
  ),
  fakeCategory(id: 'cat-transport', name: 'Transport', iconKey: 'transport'),
  fakeCategory(id: 'cat-groceries', name: 'Groceries', iconKey: 'groceries'),
  fakeCategory(id: 'cat-shopping', name: 'Shopping', iconKey: 'shopping'),
  fakeCategory(id: 'cat-rent', name: 'Rent', iconKey: 'home'),
  fakeCategory(id: 'cat-utilities', name: 'Utilities', iconKey: 'bills'),
  fakeCategory(id: 'cat-insurance', name: 'Insurance', iconKey: 'health'),
  fakeCategory(id: 'cat-car', name: 'Car', iconKey: 'car'),
  fakeCategory(
    id: 'cat-freelance',
    name: 'Freelance',
    kind: CategoryKind.income,
    iconKey: 'salary',
  ),
  fakeCategory(id: 'cat-tuition', name: 'Tuition', iconKey: 'education'),
  fakeCategory(id: 'cat-travel', name: 'Travel', iconKey: 'travel'),
];
