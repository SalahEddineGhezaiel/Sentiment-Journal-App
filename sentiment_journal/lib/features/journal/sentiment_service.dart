import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class SentimentAnalysisResult {
  final String mood;
  final double score; // -1 to 1
  final String summary;

  SentimentAnalysisResult({
    required this.mood,
    required this.score,
    required this.summary,
  });

  @override
  String toString() =>
      'SentimentAnalysisResult(mood: $mood, score: $score, summary: $summary)';
}

class SentimentService {
  /// Analyze the sentiment of a journal entry using Gemini API
  /// 
  /// Returns [SentimentAnalysisResult] with mood, score, and summary
  /// Throws [SentimentAnalysisException] on errors
  Future<SentimentAnalysisResult> analyzeSentiment(String journalText) async {
    if (journalText.trim().isEmpty) {
      throw SentimentAnalysisException('Journal text cannot be empty');
    }

    try {
      final result = await _callGeminiApi(journalText);
      return result;
    } on SocketException {
      throw SentimentAnalysisException(
        'No internet connection. Please check your connection and try again.',
      );
    } on TimeoutException {
      throw SentimentAnalysisException(
        'Request timed out. Please try again or check your internet connection.',
      );
    } on SentimentAnalysisException {
      rethrow;
    } catch (e) {
      // Handle other network-related errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        throw SentimentAnalysisException(
          'Network error: Please check your internet connection.',
        );
      }
      throw SentimentAnalysisException(
        'Failed to analyze sentiment: ${e.toString()}',
      );
    }
  }

  /// Call Gemini API and parse response
  Future<SentimentAnalysisResult> _callGeminiApi(String journalText) async {
    final url = Uri.parse(
      '${AppConstants.geminiApiEndpoint}?key=${AppConstants.geminiApiKey}',
    );

    final prompt = '''Analyze the sentiment of this journal entry and respond ONLY with a valid JSON object in this exact format: {"mood": "Positive", "score": 0.8, "summary": "one sentence summary"}. 

Mood must be one of: Positive, Negative, Neutral, Mixed.
Score must be a number between -1 (very negative) and 1 (very positive).
Summary must be a single sentence explaining the overall sentiment.

Journal entry:
$journalText''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        return _parseGeminiResponse(response.body);
      } else if (response.statusCode == 401) {
        throw SentimentAnalysisException(
          'API key is invalid. Please configure your Gemini API key.',
        );
      } else if (response.statusCode == 429) {
        throw SentimentAnalysisException(
          'API rate limit exceeded. Please try again later.',
        );
      } else {
        throw SentimentAnalysisException(
          'Gemini API error: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw SentimentAnalysisException(
        'Request timed out. Please try again or check your internet connection.',
      );
    } on SocketException {
      throw SentimentAnalysisException(
        'No internet connection. Please check your connection and try again.',
      );
    } on SentimentAnalysisException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        throw SentimentAnalysisException(
          'Network error: Please check your internet connection.',
        );
      }
      throw SentimentAnalysisException('Network error: ${e.toString()}');
    }
  }

  /// Parse Gemini API response and extract sentiment data
  SentimentAnalysisResult _parseGeminiResponse(String responseBody) {
    try {
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      // Navigate through Gemini API response structure
      if (!jsonResponse.containsKey('candidates') ||
          (jsonResponse['candidates'] as List).isEmpty) {
        throw SentimentAnalysisException('Invalid API response: no candidates found');
      }

      final candidate = jsonResponse['candidates'][0] as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;

      if (parts.isEmpty) {
        throw SentimentAnalysisException('Invalid API response: no text in parts');
      }

      final text = parts[0]['text'] as String;

      // Extract JSON from the response (it might be wrapped in markdown code blocks)
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw SentimentAnalysisException(
          'Could not parse sentiment data from response: $text',
        );
      }

      final sentimentJson = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      // Validate and extract fields
      final mood = sentimentJson['mood'] as String?;
      final score = sentimentJson['score'] as num?;
      final summary = sentimentJson['summary'] as String?;

      if (mood == null || score == null || summary == null) {
        throw SentimentAnalysisException(
          'Missing required fields in sentiment response',
        );
      }

      // Validate mood
      if (!AppConstants.validMoods.contains(mood)) {
        throw SentimentAnalysisException(
          'Invalid mood value: $mood. Must be one of ${AppConstants.validMoods.join(", ")}',
        );
      }

      // Validate score range
      final scoreDouble = score.toDouble();
      if (scoreDouble < -1 || scoreDouble > 1) {
        throw SentimentAnalysisException(
          'Invalid score value: $scoreDouble. Must be between -1 and 1',
        );
      }

      return SentimentAnalysisResult(
        mood: mood,
        score: scoreDouble,
        summary: summary.trim(),
      );
    } on SentimentAnalysisException {
      rethrow;
    } catch (e) {
      throw SentimentAnalysisException(
        'Failed to parse sentiment response: ${e.toString()}',
      );
    }
  }
}

/// Custom exception for sentiment analysis errors
class SentimentAnalysisException implements Exception {
  final String message;

  SentimentAnalysisException(this.message);

  @override
  String toString() => 'SentimentAnalysisException: $message';
}
