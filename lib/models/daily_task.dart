import 'package:flutter/material.dart';

enum TaskType { daily, once, followUp }

extension TaskTypeName on TaskType {
  String get value => switch (this) {
    TaskType.daily => 'daily',
    TaskType.once => 'once',
    TaskType.followUp => 'followUp',
  };
}

class DailyTask {
  DailyTask({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.taskType,
    required this.isCompleted,
    required this.createdDate,
    required this.lastCompletedDate,
    this.reminderEnabled = false,
    this.reminderDuration,
    this.notificationId,
  });

  final String id;
  final String name;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final TaskType taskType;
  final bool isCompleted;
  final DateTime createdDate;
  final DateTime? lastCompletedDate;
  final bool reminderEnabled;
  final Duration? reminderDuration;
  final int? notificationId;

  DailyTask copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    TaskType? taskType,
    bool? isCompleted,
    DateTime? createdDate,
    DateTime? lastCompletedDate,
    bool clearLastCompletedDate = false,
    bool? reminderEnabled,
    Duration? reminderDuration,
    int? notificationId,
  }) {
    return DailyTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      taskType: taskType ?? this.taskType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : lastCompletedDate ?? this.lastCompletedDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDuration: reminderDuration ?? this.reminderDuration,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, Object?> toMap({String? userId}) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'taskType': taskType.value,
      'isCompleted': isCompleted ? 1 : 0,
      'createdDate': createdDate.toIso8601String(),
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderDurationMinutes': reminderDuration?.inMinutes,
      'notificationId': notificationId,
      'userId': userId ?? '',
    };
  }

  static DailyTask fromMap(Map<String, Object?> map) {
    return DailyTask(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      time: TimeOfDay(
        hour: map['timeHour'] as int,
        minute: map['timeMinute'] as int,
      ),
      taskType: _taskTypeFromString(map['taskType'] as String),
      isCompleted: (map['isCompleted'] as int) == 1,
      createdDate: DateTime.parse(map['createdDate'] as String),
      lastCompletedDate: map['lastCompletedDate'] == null
          ? null
          : DateTime.parse(map['lastCompletedDate'] as String),
      reminderEnabled: (map['reminderEnabled'] as int) == 1,
      reminderDuration: map['reminderDurationMinutes'] == null
          ? null
          : Duration(minutes: map['reminderDurationMinutes'] as int),
      notificationId: map['notificationId'] as int?,
    );
  }

  static TaskType _taskTypeFromString(String value) {
    switch (value) {
      case 'once':
        return TaskType.once;
      case 'followUp':
        return TaskType.followUp;
      default:
        return TaskType.daily;
    }
  }
}
