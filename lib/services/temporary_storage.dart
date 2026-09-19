import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/models/achievement.dart';
import 'package:consistency_builder/models/goal.dart';
import 'package:consistency_builder/models/user.dart';
import 'package:consistency_builder/services/database_service.dart';
import 'package:consistency_builder/services/notification_service.dart';

enum AnalyticsPeriod { daily, weekly, monthly }

class AnalyticsPoint {
  AnalyticsPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class TemporaryStorage {
  TemporaryStorage._();

  static final TemporaryStorage instance = TemporaryStorage._();

  final List<DailyTask> _dailyTasks = <DailyTask>[];
  final List<Goal> _goals = <Goal>[];
  final List<Map<String, Object?>> _webTaskCompletionHistory =
      <Map<String, Object?>>[];
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  Timer? _midnightRefreshTimer;
  SharedPreferences? _webPreferences;
  AppUser _user = AppUser(
    id: 'default-user',
    name: 'Default User',
    createdAt: DateTime.now(),
  );

  List<DailyTask> get dailyTasks => List.unmodifiable(_dailyTasks);
  List<Goal> get goals => List.unmodifiable(_goals);

  Future<void> initialize({String? userId}) async {
    if (kIsWeb) {
      _webPreferences ??= await SharedPreferences.getInstance();
      _dailyTasks
        ..clear()
        ..addAll(_readWebTasks());
      _goals
        ..clear()
        ..addAll(_readWebGoals());
      _webTaskCompletionHistory
        ..clear()
        ..addAll(_readWebCompletionHistory());
      _scheduleMidnightRefresh();
      return;
    }

    if (userId != null) {
      final user = await DatabaseService.instance.getUser(userId);
      if (user != null) {
        _user = user;
      }
    }
    await DatabaseService.instance.createUser(_user);
    final tasks = await DatabaseService.instance.getDailyTasks(
      userId: _user.id,
    );
    final goals = await DatabaseService.instance.getGoals(userId: _user.id);
    _dailyTasks
      ..clear()
      ..addAll(tasks);
    _goals
      ..clear()
      ..addAll(goals);
    _scheduleMidnightRefresh();
  }

  List<DailyTask> getTodayTasks(DateTime today) {
    _resetExpiredDailyTasks(today);
    final todaysTasks = _dailyTasks.where((task) {
      return _isVisibleOnDate(task, today);
    }).toList();

    todaysTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return a.time.hour * 60 +
          a.time.minute -
          (b.time.hour * 60 + b.time.minute);
    });

    return todaysTasks;
  }

  Future<void> addDailyTask(DailyTask task) async {
    final scheduledId = task.reminderEnabled && task.reminderDuration != null
        ? (task.notificationId ??
              DateTime.now().millisecondsSinceEpoch % 2147483647)
        : null;
    final taskToStore = task.copyWith(notificationId: scheduledId);
    _dailyTasks.add(taskToStore);
    if (!kIsWeb) {
      await DatabaseService.instance.insertDailyTask(
        taskToStore,
        userId: _user.id,
      );
      await DatabaseService.instance.saveReminderSettings(
        taskToStore.id,
        taskToStore.reminderEnabled,
        taskToStore.reminderDuration,
        taskToStore.notificationId,
        _user.id,
      );
    }
    if (taskToStore.reminderEnabled && taskToStore.reminderDuration != null) {
      unawaited(NotificationService.instance.scheduleReminder(taskToStore));
    }
    await _persistWebData();
    _notifyListeners();
  }

  Future<void> updateDailyTask(DailyTask updatedTask) async {
    final index = _dailyTasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      final previousTask = _dailyTasks[index];
      final scheduledId =
          updatedTask.reminderEnabled && updatedTask.reminderDuration != null
          ? (updatedTask.notificationId ??
                DateTime.now().millisecondsSinceEpoch % 2147483647)
          : null;
      final taskToStore = updatedTask.copyWith(notificationId: scheduledId);
      _dailyTasks[index] = taskToStore;
      if (previousTask.notificationId != null &&
          (taskToStore.notificationId != previousTask.notificationId ||
              !taskToStore.reminderEnabled)) {
        unawaited(
          NotificationService.instance.cancelReminder(
            previousTask.notificationId!,
          ),
        );
      }
      if (!kIsWeb) {
        await DatabaseService.instance.updateDailyTask(
          taskToStore,
          userId: _user.id,
        );
        await DatabaseService.instance.saveReminderSettings(
          taskToStore.id,
          taskToStore.reminderEnabled,
          taskToStore.reminderDuration,
          taskToStore.notificationId,
          _user.id,
        );
      }
      if (taskToStore.reminderEnabled && taskToStore.reminderDuration != null) {
        unawaited(NotificationService.instance.scheduleReminder(taskToStore));
      }
      await _persistWebData();
      _notifyListeners();
    }
  }

  Future<void> deleteDailyTask(String id) async {
    final task = _dailyTasks.firstWhere(
      (item) => item.id == id,
      orElse: () => DailyTask(
        id: '',
        name: '',
        description: '',
        date: DateTime.now(),
        time: TimeOfDay(hour: 0, minute: 0),
        taskType: TaskType.daily,
        isCompleted: false,
        createdDate: DateTime.now(),
        lastCompletedDate: null,
      ),
    );
    if (task.notificationId != null) {
      unawaited(
        NotificationService.instance.cancelReminder(task.notificationId!),
      );
    }
    _dailyTasks.removeWhere((item) => item.id == id);
    if (!kIsWeb) {
      await DatabaseService.instance.deleteDailyTask(id);
    }
    await _persistWebData();
    _notifyListeners();
  }

  Future<void> completeDailyTask(String id, DateTime completedDate) async {
    final task = _dailyTasks.firstWhere(
      (item) => item.id == id,
      orElse: () => throw StateError('Task not found'),
    );
    final updatedTask = task.copyWith(
      isCompleted: true,
      lastCompletedDate: completedDate,
    );
    await updateDailyTask(updatedTask);
    if (!kIsWeb) {
      await DatabaseService.instance.insertTaskCompletionHistory(
        id,
        completedDate,
        _user.id,
      );
    } else {
      _webTaskCompletionHistory.add({
        'taskId': id,
        'completedAt': completedDate.toIso8601String(),
      });
      await _persistWebData();
    }
  }

  Future<void> undoDailyTaskCompletion(String id) async {
    final task = _dailyTasks.firstWhere(
      (item) => item.id == id,
      orElse: () => throw StateError('Task not found'),
    );
    final completedDate = task.lastCompletedDate;
    final updatedTask = task.copyWith(
      isCompleted: false,
      clearLastCompletedDate: true,
    );
    await updateDailyTask(updatedTask);
    if (completedDate != null && !kIsWeb) {
      await DatabaseService.instance.deleteTaskCompletionHistory(
        id,
        completedDate,
        _user.id,
      );
    } else if (completedDate != null) {
      _webTaskCompletionHistory.removeWhere(
        (entry) =>
            entry['taskId'] == id &&
            entry['completedAt'] == completedDate.toIso8601String(),
      );
      await _persistWebData();
    }
  }

  Future<void> addGoal(Goal goal) async {
    _goals.add(goal);
    if (!kIsWeb) {
      await DatabaseService.instance.insertGoal(goal, userId: _user.id);
    }
    await _persistWebData();
    _notifyListeners();
  }

  Future<void> updateGoal(Goal updatedGoal) async {
    final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      if (!kIsWeb) {
        await DatabaseService.instance.updateGoal(
          updatedGoal,
          userId: _user.id,
        );
      }
      await _persistWebData();
      _notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((goal) => goal.id == id);
    if (!kIsWeb) {
      await DatabaseService.instance.deleteGoal(id);
    }
    await _persistWebData();
    _notifyListeners();
  }

  Future<void> completeGoal(String id) async {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index != -1) {
      _goals[index] = _goals[index].copyWith(isCompleted: true);
      if (!kIsWeb) {
        await DatabaseService.instance.updateGoal(
          _goals[index],
          userId: _user.id,
        );
        await DatabaseService.instance.insertGoalCompletionHistory(
          id,
          DateTime.now(),
          _user.id,
        );
      }
      await _persistWebData();
      _notifyListeners();
    }
  }

  Future<void> undoGoalCompletion(String id) async {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index != -1) {
      _goals[index] = _goals[index].copyWith(isCompleted: false);
      if (!kIsWeb) {
        await DatabaseService.instance.updateGoal(
          _goals[index],
          userId: _user.id,
        );
      }
      await _persistWebData();
      _notifyListeners();
    }
  }

  Future<void> clear() async {
    _dailyTasks.clear();
    _goals.clear();
    _webTaskCompletionHistory.clear();
    if (kIsWeb) {
      _webPreferences ??= await SharedPreferences.getInstance();
      await _webPreferences!.remove(_webTasksKey);
      await _webPreferences!.remove(_webGoalsKey);
      await _webPreferences!.remove(_webHistoryKey);
    }
    _notifyListeners();
  }

  List<AnalyticsPoint> getTaskCompletionSeries(
    AnalyticsPeriod period, {
    DateTime? anchor,
  }) {
    final baseDate = anchor ?? DateTime.now();
    switch (period) {
      case AnalyticsPeriod.daily:
        return List.generate(7, (index) {
          final date = baseDate.subtract(Duration(days: 6 - index));
          final tasks = _dailyTasks.where(
            (task) =>
                task.date.year == date.year &&
                task.date.month == date.month &&
                task.date.day == date.day,
          );
          final completed = tasks.where((task) => task.isCompleted).length;
          final total = tasks.isEmpty ? 1 : tasks.length;
          return AnalyticsPoint(
            label: _dayName(date.weekday),
            value: (completed / total) * 100,
          );
        });
      case AnalyticsPeriod.weekly:
        return List.generate(4, (index) {
          final weekStart = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day - ((baseDate.weekday + 6) % 7) - (3 - index) * 7,
          );
          final weekEnd = weekStart.add(const Duration(days: 6));
          final tasks = _dailyTasks.where((task) {
            final taskDate = task.lastCompletedDate ?? task.createdDate;
            return taskDate.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                taskDate.isBefore(weekEnd.add(const Duration(days: 1)));
          });
          final completed = tasks.where((task) => task.isCompleted).length;
          final total = tasks.isEmpty ? 1 : tasks.length;
          return AnalyticsPoint(
            label: 'W${index + 1}',
            value: (completed / total) * 100,
          );
        }).reversed.toList();
      case AnalyticsPeriod.monthly:
        return List.generate(6, (index) {
          final monthDate = DateTime(
            baseDate.year,
            baseDate.month - (5 - index),
            1,
          );
          final tasks = _dailyTasks.where((task) {
            return task.date.year == monthDate.year &&
                task.date.month == monthDate.month;
          });
          final completed = tasks.where((task) => task.isCompleted).length;
          final total = tasks.isEmpty ? 1 : tasks.length;
          return AnalyticsPoint(
            label: _monthName(monthDate.month),
            value: (completed / total) * 100,
          );
        });
    }
  }

  List<AnalyticsPoint> getGoalCompletionSeries(
    AnalyticsPeriod period, {
    DateTime? anchor,
  }) {
    final baseDate = anchor ?? DateTime.now();
    switch (period) {
      case AnalyticsPeriod.daily:
        return List.generate(7, (index) {
          final date = baseDate.subtract(Duration(days: 6 - index));
          final goals = _goals.where(
            (goal) =>
                goal.targetDate.year == date.year &&
                goal.targetDate.month == date.month &&
                goal.targetDate.day == date.day,
          );
          final completed = goals.where((goal) => goal.isCompleted).length;
          final total = goals.isEmpty ? 1 : goals.length;
          return AnalyticsPoint(
            label: _dayName(date.weekday),
            value: (completed / total) * 100,
          );
        });
      case AnalyticsPeriod.weekly:
        return List.generate(4, (index) {
          final weekStart = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day - ((baseDate.weekday + 6) % 7) - (3 - index) * 7,
          );
          final weekEnd = weekStart.add(const Duration(days: 6));
          final goals = _goals.where((goal) {
            return goal.targetDate.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                goal.targetDate.isBefore(weekEnd.add(const Duration(days: 1)));
          });
          final completed = goals.where((goal) => goal.isCompleted).length;
          final total = goals.isEmpty ? 1 : goals.length;
          return AnalyticsPoint(
            label: 'W${index + 1}',
            value: (completed / total) * 100,
          );
        }).reversed.toList();
      case AnalyticsPeriod.monthly:
        return List.generate(6, (index) {
          final monthDate = DateTime(
            baseDate.year,
            baseDate.month - (5 - index),
            1,
          );
          final goals = _goals.where(
            (goal) =>
                goal.targetDate.year == monthDate.year &&
                goal.targetDate.month == monthDate.month,
          );
          final completed = goals.where((goal) => goal.isCompleted).length;
          final total = goals.isEmpty ? 1 : goals.length;
          return AnalyticsPoint(
            label: _monthName(monthDate.month),
            value: (completed / total) * 100,
          );
        });
    }
  }

  int getCurrentStreak({DateTime? anchor}) {
    final baseDate = anchor ?? DateTime.now();
    var streak = 0;
    var cursor = DateTime(baseDate.year, baseDate.month, baseDate.day);
    while (true) {
      final tasks = _dailyTasks.where(
        (task) =>
            task.date.year == cursor.year &&
            task.date.month == cursor.month &&
            task.date.day == cursor.day &&
            task.isCompleted,
      );
      if (tasks.isEmpty) {
        break;
      }
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<AchievementProgress> getAchievementProgress({DateTime? anchor}) async {
    final history = kIsWeb
        ? _webTaskCompletionHistory
        : await DatabaseService.instance.getTaskCompletionHistory(_user.id);
    return AchievementCalculator.calculate(
      tasks: _dailyTasks,
      completionHistory: history,
      anchor: anchor ?? DateTime.now(),
    );
  }

  static const _webTasksKey = 'consistency_builder_web_tasks';
  static const _webGoalsKey = 'consistency_builder_web_goals';
  static const _webHistoryKey = 'consistency_builder_web_task_history';

  List<DailyTask> _readWebTasks() {
    final rawTasks = _webPreferences?.getStringList(_webTasksKey) ?? <String>[];
    return rawTasks
        .map(
          (task) => DailyTask.fromMap(
            Map<String, Object?>.from(jsonDecode(task) as Map),
          ),
        )
        .toList();
  }

  List<Goal> _readWebGoals() {
    final rawGoals = _webPreferences?.getStringList(_webGoalsKey) ?? <String>[];
    return rawGoals
        .map(
          (goal) =>
              Goal.fromMap(Map<String, Object?>.from(jsonDecode(goal) as Map)),
        )
        .toList();
  }

  List<Map<String, Object?>> _readWebCompletionHistory() {
    final rawHistory =
        _webPreferences?.getStringList(_webHistoryKey) ?? <String>[];
    return rawHistory
        .map((entry) => Map<String, Object?>.from(jsonDecode(entry) as Map))
        .toList();
  }

  Future<void> _persistWebData() async {
    if (!kIsWeb) {
      return;
    }
    _webPreferences ??= await SharedPreferences.getInstance();
    await _webPreferences!.setStringList(
      _webTasksKey,
      _dailyTasks
          .map((task) => jsonEncode(task.toMap(userId: _user.id)))
          .toList(),
    );
    await _webPreferences!.setStringList(
      _webGoalsKey,
      _goals.map((goal) => jsonEncode(goal.toMap(userId: _user.id))).toList(),
    );
    await _webPreferences!.setStringList(
      _webHistoryKey,
      _webTaskCompletionHistory.map(jsonEncode).toList(),
    );
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Day';
    }
  }

  String _monthName(int month) {
    switch (month) {
      case DateTime.january:
        return 'Jan';
      case DateTime.february:
        return 'Feb';
      case DateTime.march:
        return 'Mar';
      case DateTime.april:
        return 'Apr';
      case DateTime.may:
        return 'May';
      case DateTime.june:
        return 'Jun';
      case DateTime.july:
        return 'Jul';
      case DateTime.august:
        return 'Aug';
      case DateTime.september:
        return 'Sep';
      case DateTime.october:
        return 'Oct';
      case DateTime.november:
        return 'Nov';
      case DateTime.december:
        return 'Dec';
      default:
        return 'Mon';
    }
  }

  bool _isVisibleOnDate(DailyTask task, DateTime targetDate) {
    if (task.taskType == TaskType.daily) {
      return true;
    }

    if (task.taskType == TaskType.once) {
      return _sameDay(task.date, targetDate);
    }

    if (task.taskType == TaskType.followUp) {
      return !task.isCompleted && !_dayBefore(targetDate, task.date);
    }

    return false;
  }

  bool _resetExpiredDailyTasks(DateTime targetDate) {
    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    var resetAny = false;
    for (var index = 0; index < _dailyTasks.length; index++) {
      final task = _dailyTasks[index];
      if (task.taskType != TaskType.daily || !task.isCompleted) {
        continue;
      }
      final completedDay = task.lastCompletedDate;
      if (completedDay == null || !_dayBefore(completedDay, targetDay)) {
        continue;
      }
      resetAny = true;
      _dailyTasks[index] = task.copyWith(
        isCompleted: false,
        clearLastCompletedDate: true,
      );
      unawaited(_persistWebData());
      if (!kIsWeb) {
        unawaited(
          DatabaseService.instance.updateDailyTask(
            _dailyTasks[index],
            userId: _user.id,
          ),
        );
      }
    }
    return resetAny;
  }

  void _scheduleMidnightRefresh() {
    _midnightRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightRefreshTimer = Timer(nextMidnight.difference(now), () {
      if (_resetExpiredDailyTasks(DateTime.now())) {
        _notifyListeners();
      }
      _scheduleMidnightRefresh();
    });
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _dayBefore(DateTime first, DateTime second) {
    return DateTime(
      first.year,
      first.month,
      first.day,
    ).isBefore(DateTime(second.year, second.month, second.day));
  }

  void _notifyListeners() {
    changeNotifier.value = changeNotifier.value + 1;
  }
}
