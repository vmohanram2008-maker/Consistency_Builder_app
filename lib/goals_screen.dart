import 'package:flutter/material.dart';
import 'package:consistency_builder/models/goal.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: TemporaryStorage.instance.changeNotifier,
      builder: (context, _, _) {
        final goals = TemporaryStorage.instance.goals;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: goals.isEmpty
                      ? Center(
                          child: Text(
                            'No goals yet',
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          itemCount: goals.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final goal = goals[index];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                              child: ListTile(
                                leading: Checkbox(
                                  value: goal.isCompleted,
                                  onChanged: (_) => _toggleGoal(goal),
                                ),
                                title: Text(
                                  goal.name,
                                  style: TextStyle(
                                    decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                                    color: goal.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                                  ),
                                ),
                                subtitle: Text(goal.description.isEmpty ? 'Target: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}' : '${goal.description}\nTarget: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}'),
                                isThreeLine: goal.description.isNotEmpty,
                              ),
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

  Future<void> _toggleGoal(Goal goal) async {
    if (!goal.isCompleted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Complete Goal'),
          content: Text('Mark “${goal.name}” as completed?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Complete')),
          ],
        ),
      );

      if (confirmed == true) {
        TemporaryStorage.instance.completeGoal(goal.id);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo Completion'),
        content: Text('Do you want to mark “${goal.name}” as pending again?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed == true) {
      TemporaryStorage.instance.undoGoalCompletion(goal.id);
    }
  }
}
