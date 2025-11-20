import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for managing reminders using local notifications
class ReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the reminder service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permission
    await _requestPermission();
  }

  /// Request notification permission (Android 13+)
  static Future<void> _requestPermission() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to the specific thought
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule a reminder
  Future<int> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'thought_reminders',
          'Thought Reminders',
          channelDescription: 'Reminders for your captured thoughts',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    return notificationId;
  }

  /// Schedule a reminder with a delay (e.g., "in 2 hours")
  Future<int> scheduleReminderWithDelay({
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    final scheduledTime = DateTime.now().add(delay);
    return await scheduleReminder(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }

  /// Cancel a reminder
  Future<void> cancelReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// Get pending reminders
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Parse natural language time to DateTime
  /// Examples: "tomorrow 9am", "in 2 hours", "next week"
  static DateTime? parseNaturalTime(String naturalTime) {
    final now = DateTime.now();
    final lowerTime = naturalTime.toLowerCase().trim();

    // "in X hours"
    if (lowerTime.contains('in') && lowerTime.contains('hour')) {
      final hours = int.tryParse(lowerTime.replaceAll(RegExp(r'[^0-9]'), ''));
      if (hours != null) {
        return now.add(Duration(hours: hours));
      }
    }

    // "in X minutes"
    if (lowerTime.contains('in') && lowerTime.contains('minute')) {
      final minutes = int.tryParse(lowerTime.replaceAll(RegExp(r'[^0-9]'), ''));
      if (minutes != null) {
        return now.add(Duration(minutes: minutes));
      }
    }

    // "tomorrow"
    if (lowerTime.contains('tomorrow')) {
      var tomorrow = now.add(const Duration(days: 1));

      // Check for specific time
      if (lowerTime.contains('9am') || lowerTime.contains('9 am')) {
        tomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      } else {
        tomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      }

      return tomorrow;
    }

    // "next week"
    if (lowerTime.contains('next week')) {
      return now.add(const Duration(days: 7));
    }

    // "later today"
    if (lowerTime.contains('later')) {
      return now.add(const Duration(hours: 3));
    }

    // Default: 1 hour from now
    return now.add(const Duration(hours: 1));
  }
}
