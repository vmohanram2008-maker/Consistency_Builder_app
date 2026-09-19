import 'package:consistency_builder/models/daily_task.dart';

enum AchievementMedal {
  none('No medal yet', 0),
  bronzeI('Bronze-I', 7),
  bronzeII('Bronze-II', 14),
  bronzeIII('Bronze-III', 21),
  silverI('Silver-I', 30),
  silverII('Silver-II', 60),
  silverIII('Silver-III', 90),
  gold('Gold', 121);

  const AchievementMedal(this.label, this.requiredDays);

  final String label;
  final int requiredDays;
}

class AchievementProgress {
  const AchievementProgress({
    required this.currentStreak,
    required this.medal,
    required this.nextMedal,
    required this.daysUntilNextMedal,
  });

  final int currentStreak;
  final AchievementMedal medal;
  final AchievementMedal? nextMedal;
  final int daysUntilNextMedal;
}

class AchievementCalculator {
  const AchievementCalculator._();

  static AchievementProgress calculate({
    required List<DailyTask> tasks,
    required List<Map<String, Object?>> completionHistory,
    required DateTime anchor,
  }) {
    final completedByDay = <DateTime, Set<String>>{};
    for (final entry in completionHistory) {
      final taskId = entry['taskId'] as String?;
      final completedAt = entry['completedAt'] as String?;
      if (taskId == null || completedAt == null) continue;
      final date = DateTime.parse(completedAt);
      final day = DateTime(date.year, date.month, date.day);
      completedByDay.putIfAbsent(day, () => <String>{}).add(taskId);
    }

    var streak = 0;
    var date = DateTime(anchor.year, anchor.month, anchor.day);
    while (_completionPercentage(
          tasks,
          completedByDay[date] ?? <String>{},
          date,
        ) >=
        75) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    final medal = AchievementMedal.values.lastWhere(
      (candidate) => candidate.requiredDays <= streak,
      orElse: () => AchievementMedal.none,
    );
    final nextMedal = AchievementMedal.values
        .where((candidate) => candidate.requiredDays > streak)
        .firstOrNull;

    return AchievementProgress(
      currentStreak: streak,
      medal: medal,
      nextMedal: nextMedal,
      daysUntilNextMedal: nextMedal == null
          ? 0
          : nextMedal.requiredDays - streak,
    );
  }

  static double _completionPercentage(
    List<DailyTask> tasks,
    Set<String> completedTaskIds,
    DateTime date,
  ) {
    final scheduledTasks = tasks.where((task) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      final createdDate = DateTime(
        task.createdDate.year,
        task.createdDate.month,
        task.createdDate.day,
      );
      if (task.taskType == TaskType.daily) return !date.isBefore(createdDate);
      if (task.taskType == TaskType.followUp) return !date.isBefore(taskDate);
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();

    if (scheduledTasks.isEmpty) return 0;
    final completed = scheduledTasks
        .where((task) => completedTaskIds.contains(task.id))
        .length;
    return completed / scheduledTasks.length * 100;
  }
}
