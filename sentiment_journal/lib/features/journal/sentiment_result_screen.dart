import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';
import 'sentiment_provider.dart';

class SentimentResultScreen extends ConsumerWidget {
  const SentimentResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentimentResult = ref.watch(sentimentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentiment Analysis'),
        centerTitle: true,
        elevation: 0,
      ),
      body: sentimentResult.when(
        data: (result) {
          if (result == null) {
            return const Center(
              child: Text('No sentiment data available'),
            );
          }

          final moodEmoji = AppConstants.moodEmojis[result.mood] ?? '😐';
          final moodColor = _getMoodColor(result.mood);
          final displayDate = DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now());

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Animated mood emoji
                  Center(
                    child: AnimatedSentimentIcon(
                      emoji: moodEmoji,
                      backgroundColor: moodColor.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood label
                  Center(
                    child: Text(
                      result.mood,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: moodColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Score as percentage
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: moodColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Sentiment Score: ${(((result.score + 1) / 2) * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: moodColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Summary',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.summary,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date & time
                  Center(
                    child: Text(
                      displayDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button to view history
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'View History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button to write another entry
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Write Another Entry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error',
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
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
