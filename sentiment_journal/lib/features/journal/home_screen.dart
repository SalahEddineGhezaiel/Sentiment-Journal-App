import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes.dart';
import '../../core/constants.dart';
import '../../core/cache_provider.dart';
import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/auth_provider.dart';
import 'journal_provider.dart';
import 'sentiment_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _journalController = TextEditingController();
  String? _cachedLastMood;
  String? _cachedLastMoodEmoji;
  double? _cachedLastMoodScore;

  @override
  void initState() {
    super.initState();
    _loadCachedMood();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  /// Load the last cached mood from CacheService
  Future<void> _loadCachedMood() async {
    try {
      final cacheService = await ref.read(cacheServiceProvider.future);
      final moodData = cacheService.getLastMoodData();
      if (moodData != null && mounted) {
        setState(() {
          _cachedLastMood = moodData['mood'];
          _cachedLastMoodScore = moodData['score'];
          _cachedLastMoodEmoji = AppConstants.moodEmojis[_cachedLastMood] ?? '😐';
        });
      }
    } catch (e) {
      debugPrint('Error loading cached mood: $e');
    }
  }

  /// Get personalized greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Cache the mood and metadata using CacheService
  Future<void> _cacheMood(String mood, double score, String summary) async {
    try {
      final cacheService = await ref.read(cacheServiceProvider.future);
      await cacheService.cacheMoodResult(
        mood: mood,
        score: score,
        summary: summary,
      );
      setState(() {
        _cachedLastMood = mood;
        _cachedLastMoodScore = score;
        _cachedLastMoodEmoji = AppConstants.moodEmojis[mood] ?? '😐';
      });
    } catch (e) {
      debugPrint('Error caching mood: $e');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Handle journal entry submission
  Future<void> _handleSubmit() async {
    final journalText = _journalController.text.trim();

    if (journalText.isEmpty) {
      _showErrorSnackBar('📝 Please write something in your journal entry');
      return;
    }

    if (journalText.length < 10) {
      _showErrorSnackBar('✍️ Please write at least 10 characters');
      return;
    }

    try {
      // Step 1: Analyze sentiment with Gemini
      await ref
          .read(sentimentNotifierProvider.notifier)
          .analyzeSentiment(journalText);

      // Get the sentiment result
      final sentimentResult = ref.read(sentimentNotifierProvider);

      sentimentResult.whenData((result) async {
        if (result != null) {
          // Step 2: Cache the mood with score and summary
          await _cacheMood(result.mood, result.score, result.summary);

          // Step 3: Save to Firestore
          try {
            await ref.read(journalNotifierProvider.notifier).saveEntry(
              text: journalText,
              mood: result.mood,
              moodScore: result.score,
              moodSummary: result.summary,
            );

            _showSuccessSnackBar('Journal entry saved! 🎉');

            // Step 4: Clear the text field
            _journalController.clear();

            // Step 5: Navigate to sentiment result screen
            if (mounted) {
              Navigator.of(context).pushNamed(AppRoutes.sentimentResult);
            }
          } catch (e) {
            if (mounted) {
              final errorMsg = ErrorHandler.handleFirestoreError(e);
              _showErrorSnackBar(errorMsg);
            }
          }
        }
      }).maybeWhen(
        error: (error, stackTrace) {
          if (mounted) {
            final errorMsg = ErrorHandler.handleSentimentError(error);
            _showErrorSnackBar(errorMsg);
          }
        },
        orElse: () {},
      );
    } catch (e) {
      _showErrorSnackBar(ErrorHandler.handleSentimentError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentimentState = ref.watch(sentimentNotifierProvider);
    final isAnalyzing = sentimentState.isLoading;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Journal'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personalized greeting
                currentUser.whenData((user) {
                  if (user != null) {
                    final userName =
                        user.email.split('@').first; // Get username part of email
                    final greeting = _getGreeting();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$greeting, ',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                              ),
                              TextSpan(
                                text: userName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                              ),
                              TextSpan(
                                text: ' 👋',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How are you feeling today?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }).maybeWhen(
                  data: (widget) => widget,
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                // Last mood section (if available)
                if (_cachedLastMood != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _cachedLastMoodScore! >= 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          _cachedLastMoodScore! >= 0
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _cachedLastMoodScore! >= 0
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_cachedLastMoodScore! >= 0
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _cachedLastMoodEmoji ?? '😐',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your last mood was',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey.shade700,
                                        ),
                                  ),
                                  Text(
                                    _cachedLastMood ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Show mood percentage if available
                        if (_cachedLastMoodScore != null) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (_cachedLastMoodScore! + 1) / 2,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation(
                              _cachedLastMoodScore! >= 0
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Positivity: ${((_cachedLastMoodScore! + 1) / 2 * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 28),

                // Text field for journal entry - styled like a diary
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _journalController,
                    maxLines: 12,
                    minLines: 8,
                    enabled: !isAnalyzing,
                    cursorColor: AppTheme.primaryColor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: Colors.black87,
                        ),
                    decoration: InputDecoration(
                      hintText:
                          'Write your thoughts and feelings here. Let it flow... ✍️',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        height: 1.6,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit button with gradient
                if (isAnalyzing)
                  SizedBox(
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Analyzing mood...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  GradientButton(
                    label: 'Analyze & Save',
                    icon: Icons.auto_awesome,
                    gradient: AppTheme.primaryGradient,
                    onPressed: _handleSubmit,
                    height: 56,
                  ),
                const SizedBox(height: 20),
                sentimentState.whenData((_) => const SizedBox.shrink())
                    .maybeWhen(
                      error: (error, stackTrace) => Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            error.toString(),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
