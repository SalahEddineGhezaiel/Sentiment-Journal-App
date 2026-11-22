/// App-wide constants
class AppConstants {
  // Gemini API Configuration
  // Supply at build time: flutter run --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiApiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';
  static const String geminiModel = 'gemini-3.1-flash-lite';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Mood labels
  static const List<String> validMoods = [
    'Positive',
    'Negative',
    'Neutral',
    'Mixed',
  ];

  // Emoji mappings for moods
  static const Map<String, String> moodEmojis = {
    'Positive': '😊',
    'Negative': '😢',
    'Neutral': '😐',
    'Mixed': '🤔',
  };

  // Color mappings for moods (hex strings)
  static const Map<String, String> moodColors = {
    'Positive': '#27AE60', // Green
    'Negative': '#E74C3C', // Red
    'Neutral': '#95A5A6', // Grey
    'Mixed': '#F39C12', // Orange
  };
}
