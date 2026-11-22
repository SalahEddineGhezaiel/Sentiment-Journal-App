import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sentiment_service.dart';

/// Sentiment service provider
final sentimentServiceProvider = Provider<SentimentService>((ref) {
  return SentimentService();
});

/// Notifier for sentiment analysis operations
class SentimentNotifier extends AsyncNotifier<SentimentAnalysisResult?> {
  late SentimentService _sentimentService;

  @override
  Future<SentimentAnalysisResult?> build() async {
    _sentimentService = ref.watch(sentimentServiceProvider);
    return null;
  }

  /// Analyze sentiment for a given journal text
  Future<void> analyzeSentiment(String journalText) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _sentimentService.analyzeSentiment(journalText);
    });
  }

  /// Reset sentiment analysis
  void reset() {
    state = const AsyncValue.data(null);
  }
}

final sentimentNotifierProvider =
    AsyncNotifierProvider<SentimentNotifier, SentimentAnalysisResult?>(
  () => SentimentNotifier(),
);
