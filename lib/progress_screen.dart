import 'package:flutter/material.dart';
import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/services/temporary_storage.dart';
import 'package:consistency_builder/widgets/task_list_item.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: TemporaryStorage.instance.changeNotifier,
      builder: (context, _, _) {
        final tasks = TemporaryStorage.instance.getTodayTasks(DateTime.now());

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks to track yet',
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return TaskListItem(
                              task: task,
                              onToggle: () => _toggleTask(task),
                              showCheckbox: true,
                              onTap: () {},
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleTask(DailyTask task) async {
    if (!task.isCompleted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Complete Task'),
          content: Text('Mark “${task.name}” as completed?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Complete')),
          ],
        ),
      );

      if (confirmed == true) {
        TemporaryStorage.instance.completeDailyTask(task.id, DateTime.now());
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo Completion'),
        content: Text('Do you want to mark “${task.name}” as pending again?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed == true) {
      TemporaryStorage.instance.undoDailyTaskCompletion(task.id);
    }
  }
}
