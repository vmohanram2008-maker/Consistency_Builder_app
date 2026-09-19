import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/models/achievement.dart';
import 'package:consistency_builder/models/goal.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TemporaryStorage', () {
    setUp(() {
      TemporaryStorage.instance.clear();
    });

    test('requires 75 percent each day and resets below the threshold', () {
      final tasks = List.generate(
        4,
        (index) => DailyTask(
          id: 'task-$index',
          name: 'Task $index',
          description: '',
          date: DateTime(2026, 7, 1),
          time: const TimeOfDay(hour: 8, minute: 0),
          taskType: TaskType.daily,
          isCompleted: false,
          createdDate: DateTime(2026, 6, 1),
          lastCompletedDate: null,
        ),
      );
      final history = <Map<String, Object?>>[];
      for (var day = 0; day < 7; day++) {
        for (var task = 0; task < 3; task++) {
          history.add({
            'taskId': 'task-$task',
            'completedAt': DateTime(2026, 7, 1 + day).toIso8601String(),
          });
        }
      }

      final progress = AchievementCalculator.calculate(
        tasks: tasks,
        completionHistory: history,
        anchor: DateTime(2026, 7, 7),
      );
      expect(progress.currentStreak, 7);
      expect(progress.medal, AchievementMedal.bronzeI);

      history.add({
        'taskId': 'task-0',
        'completedAt': DateTime(2026, 7, 8).toIso8601String(),
      });
      final reset = AchievementCalculator.calculate(
        tasks: tasks,
        completionHistory: history,
        anchor: DateTime(2026, 7, 8),
      );
      expect(reset.currentStreak, 0);
      expect(reset.medal, AchievementMedal.none);
    });

    test('adds and updates daily tasks in memory', () {
      final task = DailyTask(
        id: 'task-1',
        name: 'Morning Reflection',
        description: 'Write a short note',
        date: DateTime(2026, 7, 25),
        time: const TimeOfDay(hour: 7, minute: 30),
        taskType: TaskType.daily,
        isCompleted: false,
        createdDate: DateTime(2026, 7, 24),
        lastCompletedDate: null,
      );

      TemporaryStorage.instance.addDailyTask(task);
      expect(TemporaryStorage.instance.dailyTasks.length, 1);

      TemporaryStorage.instance.updateDailyTask(
        task.copyWith(name: 'Evening Reflection'),
      );

      expect(
        TemporaryStorage.instance.dailyTasks.first.name,
        'Evening Reflection',
      );
    });

    test('shows only today-visible tasks and keeps pending tasks first', () {
      final task = DailyTask(
        id: 'task-2',
        name: 'Stand up',
        description: 'A quick review',
        date: DateTime(2026, 7, 25),
        time: const TimeOfDay(hour: 8, minute: 0),
        taskType: TaskType.once,
        isCompleted: false,
        createdDate: DateTime(2026, 7, 24),
        lastCompletedDate: null,
      );

      TemporaryStorage.instance.addDailyTask(task);
      final visible = TemporaryStorage.instance.getTodayTasks(
        DateTime(2026, 7, 25),
      );

      expect(visible, hasLength(1));
      expect(visible.first.name, 'Stand up');
    });

    test('resets daily tasks at the next day', () {
      final task = DailyTask(
        id: 'daily-reset',
        name: 'Daily reset',
        description: '',
        date: DateTime(2026, 7, 25),
        time: const TimeOfDay(hour: 8, minute: 0),
        taskType: TaskType.daily,
        isCompleted: true,
        createdDate: DateTime(2026, 7, 25),
        lastCompletedDate: DateTime(2026, 7, 25, 20),
      );

      TemporaryStorage.instance.addDailyTask(task);
      final visible = TemporaryStorage.instance.getTodayTasks(
        DateTime(2026, 7, 26),
      );

      expect(visible.single.isCompleted, isFalse);
      expect(visible.single.lastCompletedDate, isNull);
    });

    test('once tasks stay on their assigned day only', () {
      final task = DailyTask(
        id: 'once-task',
        name: 'One time task',
        description: '',
        date: DateTime(2026, 7, 25),
        time: const TimeOfDay(hour: 8, minute: 0),
        taskType: TaskType.once,
        isCompleted: false,
        createdDate: DateTime(2026, 7, 25),
        lastCompletedDate: null,
      );

      TemporaryStorage.instance.addDailyTask(task);

      expect(
        TemporaryStorage.instance.getTodayTasks(DateTime(2026, 7, 25)),
        hasLength(1),
      );
      expect(
        TemporaryStorage.instance.getTodayTasks(DateTime(2026, 7, 26)),
        isEmpty,
      );
    });

    test('follow-up tasks remain until completed', () {
      final task = DailyTask(
        id: 'follow-up-task',
        name: 'Follow up',
        description: '',
        date: DateTime(2026, 7, 25),
        time: const TimeOfDay(hour: 8, minute: 0),
        taskType: TaskType.followUp,
        isCompleted: false,
        createdDate: DateTime(2026, 7, 25),
        lastCompletedDate: null,
      );

      TemporaryStorage.instance.addDailyTask(task);

      expect(
        TemporaryStorage.instance.getTodayTasks(DateTime(2026, 7, 27)),
        hasLength(1),
      );
      TemporaryStorage.instance.completeDailyTask(
        task.id,
        DateTime(2026, 7, 27),
      );
      expect(
        TemporaryStorage.instance.getTodayTasks(DateTime(2026, 7, 27)),
        isEmpty,
      );
    });

    test('75 percent streak counts follow-up tasks after assignment date', () {
      final tasks = List.generate(
        4,
        (index) => DailyTask(
          id: 'streak-$index',
          name: 'Streak task $index',
          description: '',
          date: DateTime(2026, 7, 25),
          time: const TimeOfDay(hour: 8, minute: 0),
          taskType: index == 3 ? TaskType.followUp : TaskType.daily,
          isCompleted: false,
          createdDate: DateTime(2026, 7, 25),
          lastCompletedDate: null,
        ),
      );
      final history = [
        {'taskId': 'streak-0', 'completedAt': '2026-07-27T08:00:00.000'},
        {'taskId': 'streak-1', 'completedAt': '2026-07-27T08:00:00.000'},
        {'taskId': 'streak-2', 'completedAt': '2026-07-27T08:00:00.000'},
        {'taskId': 'streak-3', 'completedAt': '2026-07-27T08:00:00.000'},
      ];

      final progress = AchievementCalculator.calculate(
        tasks: tasks,
        completionHistory: history,
        anchor: DateTime(2026, 7, 27),
      );

      expect(progress.currentStreak, 1);
    });

    test('toggles task completion and undo state', () {
      final task = DailyTask(
        id: 'task-3',
        name: 'Review plan',
        description: 'Check the weekly plan',
        date: DateTime(2026, 7, 26),
        time: const TimeOfDay(hour: 9, minute: 0),
        taskType: TaskType.daily,
        isCompleted: false,
        createdDate: DateTime(2026, 7, 25),
        lastCompletedDate: null,
      );

      TemporaryStorage.instance.addDailyTask(task);
      TemporaryStorage.instance.completeDailyTask(
        task.id,
        DateTime(2026, 7, 26, 9, 0),
      );
      expect(TemporaryStorage.instance.dailyTasks.first.isCompleted, isTrue);

      TemporaryStorage.instance.undoDailyTaskCompletion(task.id);
      expect(TemporaryStorage.instance.dailyTasks.first.isCompleted, isFalse);
    });

    test('toggles goal completion and undo state', () {
      final goal = Goal(
        id: 'goal-1',
        name: 'Read 20 Pages',
        description: 'Read daily',
        targetDate: DateTime(2026, 8, 1),
        isCompleted: false,
        createdDate: DateTime(2026, 7, 24),
      );

      TemporaryStorage.instance.addGoal(goal);
      TemporaryStorage.instance.completeGoal(goal.id);
      expect(TemporaryStorage.instance.goals.first.isCompleted, isTrue);

      TemporaryStorage.instance.undoGoalCompletion(goal.id);
      expect(TemporaryStorage.instance.goals.first.isCompleted, isFalse);
    });

    test('adds and deletes goals in memory', () {
      final goal = Goal(
        id: 'goal-2',
        name: 'Read 20 Pages',
        description: 'Read daily',
        targetDate: DateTime(2026, 8, 1),
        isCompleted: false,
        createdDate: DateTime(2026, 7, 24),
      );

      TemporaryStorage.instance.addGoal(goal);
      expect(TemporaryStorage.instance.goals.length, 1);

      TemporaryStorage.instance.deleteGoal('goal-2');
      expect(TemporaryStorage.instance.goals, isEmpty);
    });

    test('builds task completion analytics data and current streak', () {
      final task = DailyTask(
        id: 'task-4',
        name: 'Practice focus',
        description: 'Deep work session',
        date: DateTime(2026, 7, 26),
        time: const TimeOfDay(hour: 8, minute: 30),
        taskType: TaskType.daily,
        isCompleted: true,
        createdDate: DateTime(2026, 7, 24),
        lastCompletedDate: DateTime(2026, 7, 26),
      );

      TemporaryStorage.instance.addDailyTask(task);
      final series = TemporaryStorage.instance.getTaskCompletionSeries(
        AnalyticsPeriod.daily,
        anchor: DateTime(2026, 7, 26),
      );

      expect(series, isNotEmpty);
      expect(series.last.value, greaterThanOrEqualTo(0));
      expect(
        TemporaryStorage.instance.getCurrentStreak(
          anchor: DateTime(2026, 7, 26),
        ),
        1,
      );
    });
  });
}
