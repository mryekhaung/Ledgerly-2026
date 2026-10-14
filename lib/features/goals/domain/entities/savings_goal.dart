import 'package:ledgerly/core/money/money.dart';
import 'package:ledgerly/core/utils/local_date.dart';

/// A savings goal tracking progress toward a financial target.
///
/// Spec: Phase 3 Item 4 (`docs/Roadmap.md` §Phase 3).
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.accountId,
    this.iconKey = 'savings',
    this.colorValue = 0xFF2E7D32,
    this.notes,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final Money targetAmount;
  final Money currentAmount;
  final LocalDate? targetDate;
  final String? accountId;
  final String iconKey;
  final int colorValue;
  final String? notes;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the target amount has been achieved.
  bool get isCompleted =>
      targetAmount.amountMinor > 0 &&
      currentAmount.amountMinor >= targetAmount.amountMinor;

  /// Progress ratio clamped between 0.0 and 1.0 for progress bars.
  double get progress {
    if (targetAmount.amountMinor <= 0) return 0.0;
    return (currentAmount.amountMinor / targetAmount.amountMinor).clamp(
      0.0,
      1.0,
    );
  }

  /// Exact progress ratio without clamping (can be > 1.0).
  double get progressRatio {
    if (targetAmount.amountMinor <= 0) return 0.0;
    return currentAmount.amountMinor / targetAmount.amountMinor;
  }

  /// Remaining amount needed to reach target (0 if completed).
  Money get remainingAmount {
    final remaining = targetAmount.amountMinor - currentAmount.amountMinor;
    return Money.minor(remaining > 0 ? remaining : 0, targetAmount.currency);
  }

  /// Days left until target deadline relative to [today], or null if no targetDate.
  int? daysRemaining(LocalDate today) {
    if (targetDate == null) return null;
    return targetDate!.daysSince(today);
  }

  /// Whether target deadline date has passed without reaching the goal.
  bool isOverdue(LocalDate today) {
    if (targetDate == null || isCompleted) return false;
    return targetDate!.isBefore(today);
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    Money? targetAmount,
    Money? currentAmount,
    LocalDate? Function()? targetDate,
    String? Function()? accountId,
    String? iconKey,
    int? colorValue,
    String? Function()? notes,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate != null ? targetDate() : this.targetDate,
      accountId: accountId != null ? accountId() : this.accountId,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      notes: notes != null ? notes() : this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          targetDate == other.targetDate &&
          accountId == other.accountId &&
          iconKey == other.iconKey &&
          colorValue == other.colorValue &&
          notes == other.notes &&
          isArchived == other.isArchived;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetAmount,
    currentAmount,
    targetDate,
    accountId,
    iconKey,
    colorValue,
    notes,
    isArchived,
  );
}
