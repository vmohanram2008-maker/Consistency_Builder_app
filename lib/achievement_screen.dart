import 'package:flutter/material.dart';
import 'package:consistency_builder/models/achievement.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  late Future<AchievementProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = TemporaryStorage.instance.getAchievementProgress();
    TemporaryStorage.instance.changeNotifier.addListener(_refreshProgress);
  }

  void _refreshProgress() {
    if (mounted) {
      setState(() {
        _progressFuture = TemporaryStorage.instance.getAchievementProgress();
      });
    }
  }

  @override
  void dispose() {
    TemporaryStorage.instance.changeNotifier.removeListener(_refreshProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<AchievementProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load achievements: ${snapshot.error}'),
              ),
            );
          }

          final progress = snapshot.data!;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Achievement', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Complete at least 75% of your tasks each day to keep your streak alive.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.workspace_premium, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        Text('${progress.currentStreak} days', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(progress.medal.label, style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (progress.nextMedal != null)
                  Text(
                    '${progress.daysUntilNextMedal} more consistent ${progress.daysUntilNextMedal == 1 ? 'day' : 'days'} for ${progress.nextMedal!.label}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  )
                else
                  Text('Gold medal unlocked', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ...AchievementMedal.values.where((medal) => medal != AchievementMedal.none).map(
                      (medal) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.emoji_events_outlined, color: _medalColor(medal)),
                        title: Text(medal.label),
                        subtitle: Text('${medal.requiredDays} consistent days'),
                        trailing: progress.currentStreak >= medal.requiredDays ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      ),
                    ),
              ],
            ),
          );
        },
    );
  }

  Color _medalColor(AchievementMedal medal) {
    if (medal.name.startsWith('bronze')) return Colors.brown;
    if (medal.name.startsWith('silver')) return Colors.blueGrey;
    return Colors.amber.shade700;
  }
}