import 'dart:async';

import 'package:ledgerly/features/recurring/domain/services/recurring_notification_service.dart';

/// In-memory and in-app event dispatcher for recurring transaction notifications.
class InAppRecurringNotificationService
    implements RecurringNotificationService {
  final _dueReminders =
      <String, ({String title, String body, String? payload})>{};
  final _eventController = StreamController<String>.broadcast();

  /// Stream of user-facing alert messages.
  Stream<String> get events => _eventController.stream;

  /// Active due reminders map.
  Map<String, ({String title, String body, String? payload})>
  get activeReminders => Map.unmodifiable(_dueReminders);

  @override
  Future<void> showDueReminder({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    _dueReminders[id] = (title: title, body: body, payload: payload);
    _eventController.add('$title: $body');
  }

  @override
  Future<void> showGeneratedNotification({
    required int count,
    required String summary,
  }) async {
    _eventController.add(summary);
  }

  @override
  Future<void> cancelReminder(String id) async {
    _dueReminders.remove(id);
  }

  void dispose() {
    unawaited(_eventController.close());
  }
}
