class JournalEntry {
  final String id;
  final String userId;
  final String text;
  final String mood; // Positive, Negative, Neutral, Mixed
  final double moodScore; // -1 to 1
  final String? moodSummary;
  final DateTime date;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.text,
    required this.mood,
    required this.moodScore,
    this.moodSummary,
    required this.date,
  });

  /// Convert JournalEntry to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'mood': mood,
      'moodScore': moodScore,
      'moodSummary': moodSummary,
      'date': date.toIso8601String(),
    };
  }

  /// Create JournalEntry from JSON (Firestore)
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      mood: json['mood'] as String,
      moodScore: (json['moodScore'] as num).toDouble(),
      moodSummary: json['moodSummary'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  /// Create a copy with modified fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? text,
    String? mood,
    double? moodScore,
    String? moodSummary,
    DateTime? date,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      moodScore: moodScore ?? this.moodScore,
      moodSummary: moodSummary ?? this.moodSummary,
      date: date ?? this.date,
    );
  }

  @override
  String toString() =>
      'JournalEntry(id: $id, mood: $mood, moodScore: $moodScore, date: $date)';
}
