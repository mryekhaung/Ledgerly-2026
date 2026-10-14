/// Visual status of a budget based on percentage of limit consumed.
///
/// Pure Dart — no Flutter, no Drift (docs/Agent.md §3.1).
enum BudgetStatus {
  /// Spending is safely under the alert threshold (< 80%).
  safe,

  /// Spending has reached or crossed the alert threshold but has not exceeded the limit (80% - 99%).
  warning,

  /// Spending has exceeded 100% of the allocated budget limit.
  exceeded,
}
