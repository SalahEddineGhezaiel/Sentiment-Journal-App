import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/routes.dart';
import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../models/journal_entry.dart';
import 'journal_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyStateWidget(
              title: 'No entries yet',
              message: 'Write your first journal entry to get started',
              emoji: '📝',
              actionButton: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.home);
                },
                icon: const Icon(Icons.add),
                label: const Text('Write an Entry'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryEntryCard(entry: entry);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorStateWidget(
          title: 'Error loading entries',
          message: error.toString(),
        ),
      ),
    );
  }
}

/// Individual history entry card
class _HistoryEntryCard extends StatelessWidget {
  final JournalEntry entry;

  const _HistoryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor(entry.mood);
    final moodEmoji = AppConstants.moodEmojis[entry.mood] ?? '😐';
    final dateString = DateFormat('MMM dd, yyyy').format(entry.date);
    final timeString = DateFormat('hh:mm a').format(entry.date);

    // Get first 50 chars of text
    final preview = entry.text.length > 50
        ? '${entry.text.substring(0, 50)}...'
        : entry.text;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: moodColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // Optional: show full entry in a dialog or details page
            _showEntryDetails(context, entry);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and mood emoji row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateString,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeString,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        moodEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mood label with color
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    entry.mood,
                    style: TextStyle(
                      color: moodColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Preview text
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Mood score bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (entry.moodScore + 1) / 2, // Convert -1 to 1 range to 0 to 1
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(((entry.moodScore + 1) / 2) * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Summary if available
                if (entry.moodSummary != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    entry.moodSummary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show full entry details in a dialog
  void _showEntryDetails(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              AppConstants.moodEmojis[entry.mood] ?? '😐',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(entry.mood),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM dd, yyyy – hh:mm a').format(entry.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                entry.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (entry.moodSummary != null) ...[
                const SizedBox(height: 12),
                Divider(),
                const SizedBox(height: 8),
                Text(
                  'AI Summary:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.moodSummary!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get color based on mood
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Positive':
        return const Color(0xFF27AE60); // Green
      case 'Negative':
        return const Color(0xFFE74C3C); // Red
      case 'Neutral':
        return const Color(0xFF95A5A6); // Grey
      case 'Mixed':
        return const Color(0xFFF39C12); // Orange
      default:
        return const Color(0xFF95A5A6);
    }
  }
}
