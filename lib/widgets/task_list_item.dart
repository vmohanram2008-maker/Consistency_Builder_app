import 'package:flutter/material.dart';
import 'package:consistency_builder/models/daily_task.dart';

class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.showCheckbox,
    required this.onTap,
  });

  final DailyTask task;
  final VoidCallback onToggle;
  final bool showCheckbox;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return Card(
      color: isCompleted
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.42)
          : const Color(0xFF102A43).withValues(alpha: 0.9),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: showCheckbox
            ? Checkbox(
                value: isCompleted,
                onChanged: (_) => onToggle(),
                activeColor: const Color(0xFF8AB8FF),
              )
            : null,
        title: Text(
          task.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isCompleted
                ? const Color(0xFFB9D9FF)
                : const Color(0xFFEAF4FF),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: const TextStyle(color: Color(0xFFD6E6FF)),
              ),
            const SizedBox(height: 4),
            Text(
              '${task.time.format(context)} • ${_taskTypeLabel(task.taskType)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB9D9FF),
              ),
            ),
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _taskTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return 'Daily';
      case TaskType.once:
        return 'Once';
      case TaskType.followUp:
        return 'Follow Up';
    }
  }
}
