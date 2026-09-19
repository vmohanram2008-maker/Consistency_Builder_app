import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:consistency_builder/models/daily_task.dart';

Future<void> scheduleWebNotification(DailyTask task) async {
  if (!task.reminderEnabled || task.reminderDuration == null) {
    return;
  }

  if (web.Notification.permission != 'granted') {
    final permission = await web.Notification.requestPermission().toDart;
    if (permission != 'granted') {
      return;
    }
  }

  var reminderDate = DateTime(
    task.date.year,
    task.date.month,
    task.date.day,
    task.time.hour,
    task.time.minute,
  ).subtract(task.reminderDuration!);
  final now = DateTime.now();
  if (reminderDate.isBefore(now)) {
    reminderDate = reminderDate.add(const Duration(days: 1));
  }

  final delay = reminderDate.difference(now);
  Timer(delay.isNegative ? Duration.zero : delay, () {
    web.Notification(
      'Reminder: ${task.name}',
      web.NotificationOptions(
        body: task.description.isEmpty
            ? 'Time to complete your task'
            : task.description,
      ),
    );
  });
}
