import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/journal_entry.dart';
import '../journal/journal_provider.dart';

class MoodGraphScreen extends ConsumerWidget {
  const MoodGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Trends'),
        centerTitle: true,
        elevation: 0,
      ),
      body: entriesAsync.when(
        data: (entries) {
          // Get the start of the current week (Monday)
          final now = DateTime.now();
          final dayOfWeek = now.weekday; // Monday=1, Sunday=7
          final startOfWeek = now.subtract(Duration(days: dayOfWeek - 1));
          final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final endOfWeekDate = startOfWeekDate.add(const Duration(days: 7));

          // Filter entries to current week (Monday 00:00 to Sunday 23:59)
          final weekEntries = entries
              .where((entry) {
                final entryDateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
                return entryDateOnly.isAtSameMomentAs(startOfWeekDate) ||
                    (entryDateOnly.isAfter(startOfWeekDate) && entryDateOnly.isBefore(endOfWeekDate));
              })
              .toList();

          // Check if we have any data for the week
          if (weekEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No entries this week yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Write a journal entry to see your mood trends',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Sort by date ascending for graph display
          final sortedEntries = List<JournalEntry>.from(weekEntries)
            ..sort((a, b) => a.date.compareTo(b.date));

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary stats
                  _SummaryStats(entries: sortedEntries),
                  const SizedBox(height: 24),

                  // Graph
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _MoodChart(entries: sortedEntries),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legend
                  _GraphLegend(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading mood data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary statistics widget
class _SummaryStats extends StatelessWidget {
  final List<JournalEntry> entries;

  const _SummaryStats({required this.entries});

  @override
  Widget build(BuildContext context) {
    final avgScore = entries.map((e) => e.moodScore).reduce((a, b) => a + b) / entries.length;

    final moodCounts = <String, int>{};
    for (var entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    final mostCommonMood = moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Average Mood',
            value: '${(((avgScore + 1) / 2) * 100).toStringAsFixed(0)}%',
            icon: '😊',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Most Common',
            value: mostCommonMood,
            icon: '📈',
          ),
        ),
      ],
    );
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Line chart widget
class _MoodChart extends StatelessWidget {
  final List<JournalEntry> entries;

  const _MoodChart({required this.entries});

  // Build a map of day index (0-6) to average mood score
  Map<int, double> _buildWeeklyMoodMap() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // Monday=1, Sunday=7
    final startOfWeek = now.subtract(Duration(days: dayOfWeek - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    // Create map for grouping entries by day index (0=Mon, 1=Tue, ..., 6=Sun)
    final dailyMoodsByIndex = <int, List<double>>{};

    for (var entry in entries) {
      // Get date-only version of entry date
      final entryDateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
      
      // Calculate which day of the week this entry belongs to (0=Mon, 6=Sun)
      final dayIndex = entryDateOnly.difference(startOfWeekDate).inDays;
      
      if (dayIndex >= 0 && dayIndex <= 6) {
        dailyMoodsByIndex.putIfAbsent(dayIndex, () => []).add(entry.moodScore);
      }
    }

    // Calculate average for each day that has entries
    return dailyMoodsByIndex.map((dayIndex, scores) {
      final average = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(dayIndex, average);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build mood map for the week (only days with data)
    final weeklyMoods = _buildWeeklyMoodMap();

    // Create chart data points only for days with data
    final spots = <FlSpot>[];
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      if (weeklyMoods.containsKey(dayIndex)) {
        spots.add(FlSpot(dayIndex.toDouble(), weeklyMoods[dayIndex]!));
      }
    }

    // Determine line color based on overall trend
    final avgScore = spots.isEmpty 
        ? 0.0 
        : spots.map((spot) => spot.y).reduce((a, b) => a + b) / spots.length;
    final lineColor = avgScore >= 0
        ? const Color(0xFF27AE60) // Green for positive
        : const Color(0xFFE74C3C); // Red for negative

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final dayIndex = spot.x.toInt();
                  if (dayIndex < 0 || dayIndex >= dayLabels.length) {
                    return null;
                  }
                  final dayLabel = dayLabels[dayIndex];
                  final percentStr =
                      '${(((spot.y + 1) / 2) * 100).toStringAsFixed(0)}%';
                  return LineTooltipItem(
                    '$dayLabel\n$percentStr',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: 0.5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              if (value == 0) {
                return FlLine(
                  color: Colors.grey.shade400,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              }
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.5,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dayLabels.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dayLabels[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value == -1) return const Text('Very Low', style: TextStyle(fontSize: 10));
                  if (value == -0.5) return const Text('Low', style: TextStyle(fontSize: 10));
                  if (value == 0) return const Text('Neutral', style: TextStyle(fontSize: 10));
                  if (value == 0.5) return const Text('High', style: TextStyle(fontSize: 10));
                  if (value == 1) return const Text('Very High', style: TextStyle(fontSize: 10));
                  return const Text('', style: TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          minX: 0,
          maxX: 6,
          minY: -1,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: spot.y >= 0
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFE74C3C),
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Graph legend
class _GraphLegend extends StatelessWidget {
  const _GraphLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to read this chart:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Positive mood (above neutral)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Negative mood (below neutral)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
