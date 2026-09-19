import 'package:flutter/material.dart';
import 'package:consistency_builder/models/achievement.dart';
import 'package:consistency_builder/services/temporary_storage.dart';
import 'package:consistency_builder/widgets/task_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: TemporaryStorage.instance.changeNotifier,
      builder: (context, _, _) {
        final tasks = TemporaryStorage.instance.getTodayTasks(DateTime.now());

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ListView(
              children: [
                Text(
                  'Your consistency workspace',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build the day you want.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF102A2A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<AchievementProgress>(
                  future: TemporaryStorage.instance.getAchievementProgress(),
                  builder: (context, snapshot) {
                    final streak = snapshot.data?.currentStreak ?? 0;
                    final completed = tasks
                        .where((task) => task.isCompleted)
                        .length;
                    final completion = tasks.isEmpty
                        ? 0
                        : completed / tasks.length;
                    return Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Streak',
                            value: '$streak d',
                            icon: Icons.local_fire_department_outlined,
                            color: const Color(0xFFEA8C55),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Today',
                            value: '${(completion * 100).round()}%',
                            icon: Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Today\'s tasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102A2A),
                  ),
                ),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  Card(
                    child: SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          'No tasks available',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskListItem(
                        task: task,
                        onToggle: () {},
                        showCheckbox: false,
                        onTap: () {},
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
