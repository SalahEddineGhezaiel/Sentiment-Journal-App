import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/journal_entry.dart';
import '../auth/auth_provider.dart';
import 'journal_service.dart';

/// Journal service provider
final journalServiceProvider = Provider<JournalService>((ref) {
  return JournalService();
});

/// Stream of journal entries for the current user
final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) async* {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) {
    yield [];
    return;
  }

  final journalService = ref.watch(journalServiceProvider);
  yield* journalService.watchEntriesByUserId(currentUser.uid);
});

/// Get all entries for current user (one-time fetch)
final allEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) {
    return [];
  }

  final journalService = ref.watch(journalServiceProvider);
  return journalService.getEntriesByUserId(currentUser.uid);
});

/// Get latest entry for current user
final latestEntryProvider = FutureProvider<JournalEntry?>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) {
    return null;
  }

  final journalService = ref.watch(journalServiceProvider);
  return journalService.getLatestEntry(currentUser.uid);
});

/// Notifier for managing journal entry operations (save, update, delete)
class JournalNotifier extends AsyncNotifier<void> {
  late JournalService _journalService;

  @override
  Future<void> build() async {
    _journalService = ref.watch(journalServiceProvider);
  }

  /// Save a new journal entry
  Future<void> saveEntry({
    required String text,
    required String mood,
    required double moodScore,
    String? moodSummary,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final newEntry = JournalEntry(
        id: '', // Firestore will generate the ID
        userId: currentUser.uid,
        text: text,
        mood: mood,
        moodScore: moodScore,
        moodSummary: moodSummary,
        date: DateTime.now(),
      );

      await _journalService.saveEntry(newEntry);
      // Invalidate entries provider to refresh the list
      ref.invalidate(journalEntriesProvider);
    });
  }

  /// Update an existing journal entry
  Future<void> updateEntry(JournalEntry entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _journalService.updateEntry(entry);
    });
  }

  /// Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _journalService.deleteEntry(entryId);
    });
  }
}

final journalNotifierProvider = AsyncNotifierProvider<JournalNotifier, void>(
  () => JournalNotifier(),
);

/// Get entries for a specific date range
final entriesByDateRangeProvider = FutureProvider.family<
    List<JournalEntry>,
    ({DateTime startDate, DateTime endDate})>((ref, dateRange) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) {
    return [];
  }

  final journalService = ref.watch(journalServiceProvider);
  return journalService.getEntriesByDateRange(
    userId: currentUser.uid,
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});
