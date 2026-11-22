import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/journal_entry.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'journal_entries';

  /// Save a new journal entry to Firestore
  /// Returns the entry with the generated ID
  Future<JournalEntry> saveEntry(JournalEntry entry) async {
    try {
      // Generate document ID
      final docRef = _firestore.collection(_collectionName).doc();
      final entryWithId = entry.copyWith(id: docRef.id);

      // Save to Firestore
      await docRef.set(entryWithId.toJson());

      return entryWithId;
    } catch (e) {
      throw Exception('Failed to save journal entry: $e');
    }
  }

  /// Get all journal entries for a specific user, ordered by date (descending)
  Future<List<JournalEntry>> getEntriesByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => JournalEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch journal entries: $e');
    }
  }

  /// Get journal entries for a user within a date range
  Future<List<JournalEntry>> getEntriesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => JournalEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch entries by date range: $e');
    }
  }

  /// Stream all journal entries for a user
  Stream<List<JournalEntry>> watchEntriesByUserId(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JournalEntry.fromJson(doc.data())).toList())
        .handleError((e) {
      throw Exception('Failed to watch journal entries: $e');
    });
  }

  /// Update an existing journal entry
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(entry.id)
          .update(entry.toJson());
    } catch (e) {
      throw Exception('Failed to update journal entry: $e');
    }
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await _firestore.collection(_collectionName).doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  /// Get the latest entry for a user
  Future<JournalEntry?> getLatestEntry(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return JournalEntry.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to fetch latest entry: $e');
    }
  }
}
