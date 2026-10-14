/// Notification interface for recurring transaction reminders and alerts.
///
/// Implemented by presentation / local notification service.
abstract class RecurringNotificationService {
  /// Show a notification / reminder for an upcoming or pending recurring transaction.
  Future<void> showDueReminder({
    required String id,
    required String title,
    required String body,
    String? payload,
  });

  /// Show a notification for newly auto-generated transactions.
  Future<void> showGeneratedNotification({
    required int count,
    required String summary,
  });

  /// Cancel any scheduled or active reminder by id.
  Future<void> cancelReminder(String id);
}
