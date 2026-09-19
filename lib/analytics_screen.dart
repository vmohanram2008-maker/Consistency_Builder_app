import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _showTasks = true;
  AnalyticsPeriod _period = AnalyticsPeriod.daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: TemporaryStorage.instance.changeNotifier,
      builder: (context, _, _) {
        final tasks = TemporaryStorage.instance.dailyTasks;
        final goals = TemporaryStorage.instance.goals;
        final data = _showTasks
            ? TemporaryStorage.instance.getTaskCompletionSeries(_period)
            : TemporaryStorage.instance.getGoalCompletionSeries(_period);
        final completedCount = _showTasks
            ? tasks.where((task) => task.isCompleted).length
            : goals.where((goal) => goal.isCompleted).length;
        final totalCount = _showTasks ? tasks.length : goals.length;
        final completionRate = totalCount == 0 ? 0.0 : (completedCount / totalCount) * 100;
        final streak = TemporaryStorage.instance.getCurrentStreak();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Text(
                  'Analytics',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: true, label: Text('Daily Tasks')),
                    ButtonSegment<bool>(value: false, label: Text('Goals')),
                  ],
                  selected: {_showTasks},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _showTasks = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<AnalyticsPeriod>(
                  segments: const [
                    ButtonSegment<AnalyticsPeriod>(value: AnalyticsPeriod.daily, label: Text('Daily')),
                    ButtonSegment<AnalyticsPeriod>(value: AnalyticsPeriod.weekly, label: Text('Weekly')),
                    ButtonSegment<AnalyticsPeriod>(value: AnalyticsPeriod.monthly, label: Text('Monthly')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _period = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            title: _showTasks ? 'Tasks Completed' : 'Goals Completed',
                            value: '$completedCount / $totalCount',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryTile(
                            title: 'Completion Rate',
                            value: '${completionRate.toStringAsFixed(0)}%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryTile(
                            title: 'Current Streak',
                            value: '$streak Days',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 280,
                      child: data.isEmpty
                          ? Center(child: Text('No data available yet', style: theme.textTheme.bodyLarge))
                          : LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, _) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= data.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(data[index].label, style: theme.textTheme.bodySmall);
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                minY: 0,
                                maxY: 100,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(data.length, (index) {
                                      return FlSpot(index.toDouble(), data[index].value);
                                    }),
                                    isCurved: true,
                                    color: theme.colorScheme.primary,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
