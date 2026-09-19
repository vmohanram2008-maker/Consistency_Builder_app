import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/services/web_notification_stub.dart'
    if (dart.library.js_interop) 'package:consistency_builder/services/web_notification.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder(DailyTask task) async {
    if (kIsWeb) {
      await scheduleWebNotification(task);
      return;
    }

    if (!task.reminderEnabled || task.reminderDuration == null) {
      if (task.notificationId != null) {
        await cancelReminder(task.notificationId!);
      }
      return;
    }

    await initialize();
    await requestPermissions();

    final scheduledDate = _buildScheduledDate(task);
    if (scheduledDate == null) {
      return;
    }

    final notificationId =
        task.notificationId ??
        DateTime.now().millisecondsSinceEpoch % 2147483647;
    final scheduledDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      notificationId,
      'Reminder: ${task.name}',
      task.description.isEmpty
          ? 'Time to complete your task'
          : task.description,
      scheduledDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'consistency_builder_reminders',
          'Consistency Builder Reminders',
          channelDescription: 'Task reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: task.taskType == TaskType.daily
          ? DateTimeComponents.time
          : null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    if (kIsWeb) {
      return;
    }
    await initialize();
    await _notifications.cancel(notificationId);
  }

  DateTime? _buildScheduledDate(DailyTask task) {
    final taskDateTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.time.hour,
      task.time.minute,
    );

    final reminderTime = taskDateTime.subtract(task.reminderDuration!);
    if (reminderTime.isBefore(DateTime.now())) {
      return reminderTime.add(const Duration(days: 1));
    }
    return reminderTime;
  }
}
