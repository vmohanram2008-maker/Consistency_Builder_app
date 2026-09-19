import 'package:flutter/material.dart';
import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/models/goal.dart';
import 'package:consistency_builder/screens/add_goal_screen.dart';
import 'package:consistency_builder/screens/add_task_screen.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  String _selectedSection = 'daily';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDailyTasks = _selectedSection == 'daily';

    return ValueListenableBuilder<int>(
      valueListenable: TemporaryStorage.instance.changeNotifier,
      builder: (context, _, _) {
        final tasks = TemporaryStorage.instance.dailyTasks;
        final goals = TemporaryStorage.instance.goals;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Edit',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'daily',
                      label: Text('Daily Tasks'),
                      icon: Icon(Icons.list_alt_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'goals',
                      label: Text('Goals'),
                      icon: Icon(Icons.flag_outlined),
                    ),
                  ],
                  selected: {_selectedSection},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedSection = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  isDailyTasks ? 'Available Tasks' : 'Available Goals',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isDailyTasks
                      ? _buildDailyTasksView(theme, tasks)
                      : _buildGoalsView(theme, goals),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isDailyTasks ? _openAddTaskFlow : _openAddGoalFlow,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(isDailyTasks ? 'Add Task' : 'Add Goal'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isDailyTasks ? _openDeleteTaskFlow : _openDeleteGoalFlow,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(isDailyTasks ? 'Delete Task' : 'Delete Goal'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyTasksView(ThemeData theme, List<DailyTask> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No daily tasks yet',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          child: ListTile(
            title: Text(task.name),
            subtitle: Text('${task.description}\n${task.date.day}/${task.date.month}/${task.date.year} • ${task.time.format(context)}'),
            isThreeLine: true,
            onTap: () => _editDailyTask(task),
          ),
        );
      },
    );
  }

  Widget _buildGoalsView(ThemeData theme, List<Goal> goals) {
    if (goals.isEmpty) {
      return Center(
        child: Text(
          'No goals yet',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: goals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          child: ListTile(
            title: Text(goal.name),
            subtitle: Text('${goal.description}\nTarget: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}'),
            isThreeLine: true,
            onTap: () => _editGoal(goal),
          ),
        );
      },
    );
  }

  Future<void> _editDailyTask(DailyTask task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddTaskScreen(task: task)),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openDeleteTaskFlow() async {
    final tasks = TemporaryStorage.instance.dailyTasks;
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to delete')),
      );
      return;
    }

    final task = await showDialog<DailyTask>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Delete Task'),
        children: tasks.map((item) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(item),
            child: Text(item.name),
          );
        }).toList(),
      ),
    );

    if (task == null) return;

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete == true) {
      TemporaryStorage.instance.deleteDailyTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task Deleted Successfully')),
        );
        setState(() {});
      }
    }
  }

  Future<void> _editGoal(Goal goal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddGoalScreen(goal: goal)),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openDeleteGoalFlow() async {
    final goals = TemporaryStorage.instance.goals;
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No goals to delete')),
      );
      return;
    }

    final goal = await showDialog<Goal>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Delete Goal'),
        children: goals.map((item) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(item),
            child: Text(item.name),
          );
        }).toList(),
      ),
    );

    if (goal == null) return;

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete == true) {
      TemporaryStorage.instance.deleteGoal(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal Deleted Successfully')),
        );
        setState(() {});
      }
    }
  }

  Future<void> _openAddTaskFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAddGoalFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }
}
