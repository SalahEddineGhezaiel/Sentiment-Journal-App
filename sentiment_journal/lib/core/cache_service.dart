import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for managing app-level caching with SharedPreferences
class CacheService {
  static const String _lastMoodKey = 'lastMood';
  static const String _lastMoodScoreKey = 'lastMoodScore';
  static const String _lastMoodSummaryKey = 'lastMoodSummary';
  static const String _lastMoodTimestampKey = 'lastMoodTimestamp';
  static const String _recentMoodsKey = 'recentMoods'; // List of last 5 moods
  static const String _appThemeKey = 'appTheme';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // ==================== Mood Caching ====================

  /// Cache a mood result with score and summary
  Future<void> cacheMoodResult({
    required String mood,
    required double score,
    required String summary,
  }) async {
    try {
      await _prefs.setString(_lastMoodKey, mood);
      await _prefs.setDouble(_lastMoodScoreKey, score);
      await _prefs.setString(_lastMoodSummaryKey, summary);
      await _prefs.setInt(_lastMoodTimestampKey, DateTime.now().millisecondsSinceEpoch);

      // Add to recent moods list
      await _addToRecentMoods(mood);
    } catch (e) {
      debugPrint('Error caching mood result: $e');
    }
  }

  /// Get the last cached mood
  String? getLastMood() {
    return _prefs.getString(_lastMoodKey);
  }

  /// Get the last mood score
  double? getLastMoodScore() {
    return _prefs.getDouble(_lastMoodScoreKey);
  }

  /// Get the last mood summary
  String? getLastMoodSummary() {
    return _prefs.getString(_lastMoodSummaryKey);
  }

  /// Get the timestamp of last mood
  DateTime? getLastMoodTimestamp() {
    final ms = _prefs.getInt(_lastMoodTimestampKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Get all cached mood data at once
  Map<String, dynamic>? getLastMoodData() {
    final mood = getLastMood();
    if (mood == null) return null;

    return {
      'mood': mood,
      'score': getLastMoodScore(),
      'summary': getLastMoodSummary(),
      'timestamp': getLastMoodTimestamp(),
    };
  }

  /// Add mood to recent moods list (keeps last 5)
  Future<void> _addToRecentMoods(String mood) async {
    try {
      List<String> recentMoods = _prefs.getStringList(_recentMoodsKey) ?? [];
      
      // Add new mood to front
      recentMoods.insert(0, mood);
      
      // Keep only last 5
      if (recentMoods.length > 5) {
        recentMoods = recentMoods.sublist(0, 5);
      }
      
      await _prefs.setStringList(_recentMoodsKey, recentMoods);
    } catch (e) {
      debugPrint('Error adding to recent moods: $e');
    }
  }

  /// Get list of recent moods (last 5)
  List<String> getRecentMoods() {
    return _prefs.getStringList(_recentMoodsKey) ?? [];
  }

  // ==================== App Preferences Caching ====================

  /// Cache app theme preference
  Future<void> cacheThemePreference(String theme) async {
    try {
      await _prefs.setString(_appThemeKey, theme);
    } catch (e) {
      debugPrint('Error caching theme: $e');
    }
  }

  /// Get cached theme preference
  String? getThemePreference() {
    return _prefs.getString(_appThemeKey);
  }

  // ==================== Cache Management ====================

  /// Clear all mood-related cache
  Future<void> clearMoodCache() async {
    try {
      await _prefs.remove(_lastMoodKey);
      await _prefs.remove(_lastMoodScoreKey);
      await _prefs.remove(_lastMoodSummaryKey);
      await _prefs.remove(_lastMoodTimestampKey);
      await _prefs.remove(_recentMoodsKey);
    } catch (e) {
      debugPrint('Error clearing mood cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      await _prefs.clear();
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }

  /// Check if cache is stale (older than specified hours)
  bool isCacheStale({int hours = 24}) {
    final timestamp = getLastMoodTimestamp();
    if (timestamp == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    return difference.inHours > hours;
  }
}
