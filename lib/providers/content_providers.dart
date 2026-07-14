import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/beliefs_repository.dart';
import '../data/devotion_repository.dart';
import '../data/scripture_ref.dart';
import '../models/belief.dart';
import '../models/bible.dart';
import '../models/devotion.dart';
import 'hymnal_providers.dart';

final devotionRepositoryProvider = Provider<DevotionRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

final beliefsRepositoryProvider = Provider<BeliefsRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

final devotionForDateProvider = FutureProvider.family<Devotion?, DateTime>((ref, date) {
  ref.watch(devotionCacheVersionProvider); // refetch when the feed adds entries
  return ref.watch(devotionRepositoryProvider).forDate(date);
});

/// Bumped whenever the online feed adds newly cached devotions, so lists
/// depending on the cache recompute.
final devotionCacheVersionProvider = StateProvider<int>((ref) => 0);

/// Most recent past studies (fetched devotions) for the home screen.
final recentDevotionsProvider = Provider<List<Devotion>>((ref) {
  ref.watch(devotionCacheVersionProvider);
  return ref.watch(devotionRepositoryProvider).pastStudies(limit: 5);
});

/// Full past-studies history, newest first.
final pastStudiesProvider = Provider<List<Devotion>>((ref) {
  ref.watch(devotionCacheVersionProvider);
  return ref.watch(devotionRepositoryProvider).pastStudies();
});

/// Favorited devotion dates (`yyyy-MM-dd` keys).
class DevotionFavoritesNotifier extends StateNotifier<Set<String>> {
  final DevotionRepository _repo;

  DevotionFavoritesNotifier(this._repo) : super(_repo.favoriteDateKeys);

  Future<void> toggle(String dateKey) async {
    await _repo.setFavorite(dateKey, !state.contains(dateKey));
    state = _repo.favoriteDateKeys;
  }
}

final devotionFavoritesProvider =
    StateNotifierProvider<DevotionFavoritesNotifier, Set<String>>((ref) {
  return DevotionFavoritesNotifier(ref.watch(devotionRepositoryProvider));
});

/// Read-progress state: set of `yyyy-MM-dd` keys plus derived streak.
class DevotionProgress {
  final Set<String> readDates;
  final int streak;

  const DevotionProgress({required this.readDates, required this.streak});

  bool isRead(DateTime date) => readDates.contains(DevotionRepository.dateKey(date));
}

class DevotionProgressNotifier extends StateNotifier<DevotionProgress> {
  final DevotionRepository _repo;

  DevotionProgressNotifier(this._repo) : super(const DevotionProgress(readDates: {}, streak: 0)) {
    _refreshFor(DateTime.now());
  }

  void _refreshFor(DateTime around) {
    final read = <String>{};
    for (var offset = -370; offset <= 1; offset++) {
      final day = around.add(Duration(days: offset));
      if (_repo.isRead(day)) read.add(DevotionRepository.dateKey(day));
    }
    state = DevotionProgress(readDates: read, streak: _repo.currentStreak(DateTime.now()));
  }

  Future<void> toggleRead(DateTime date) async {
    await _repo.setRead(date, !_repo.isRead(date));
    _refreshFor(date);
  }
}

final devotionProgressProvider =
    StateNotifierProvider<DevotionProgressNotifier, DevotionProgress>((ref) {
  return DevotionProgressNotifier(ref.watch(devotionRepositoryProvider));
});

/// Reminder settings as simple immutable state.
class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  /// Weekdays the reminder fires on (DateTime.monday..sunday = 1..7).
  final Set<int> days;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.days,
  });
}

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  final DevotionRepository _repo;

  ReminderSettingsNotifier(this._repo)
      : super(ReminderSettings(
          enabled: _repo.reminderEnabled,
          hour: _repo.reminderHour,
          minute: _repo.reminderMinute,
          days: _repo.reminderDays,
        ));

  Future<void> update({
    required bool enabled,
    required int hour,
    required int minute,
    required Set<int> days,
  }) async {
    await _repo.setReminder(enabled: enabled, hour: hour, minute: minute, days: days);
    state = ReminderSettings(enabled: enabled, hour: hour, minute: minute, days: days);
  }
}

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>((ref) {
  return ReminderSettingsNotifier(ref.watch(devotionRepositoryProvider));
});

// --- Beliefs ---

final beliefsProvider = FutureProvider<List<Belief>>((ref) {
  return ref.watch(beliefsRepositoryProvider).getAll();
});

class ViewedBeliefsNotifier extends StateNotifier<Set<int>> {
  final BeliefsRepository _repo;

  ViewedBeliefsNotifier(this._repo) : super(_repo.viewedNumbers);

  Future<void> markViewed(int number) async {
    await _repo.markViewed(number);
    state = _repo.viewedNumbers;
  }
}

final viewedBeliefsProvider = StateNotifierProvider<ViewedBeliefsNotifier, Set<int>>((ref) {
  return ViewedBeliefsNotifier(ref.watch(beliefsRepositoryProvider));
});

// --- Scripture reference resolution (shared by devotion + beliefs) ---

/// Resolves a textual reference like `John 3:16-17` to the verses' text.
final versesForRefProvider =
    FutureProvider.family<({BibleBook book, ScriptureRef ref, List<BibleVerse> verses})?, String>(
        (ref, rawRef) async {
  final parsed = ScriptureRef.parse(rawRef);
  if (parsed == null) return null;
  final books = await ref.watch(bibleBooksProvider.future);
  final book = parsed.resolveBook(books);
  if (book == null) return null;
  final chapter = await ref
      .watch(bibleChapterProvider((bookId: book.id, chapterNum: parsed.chapter)).future);
  final start = parsed.verse;
  final end = parsed.endVerse ?? parsed.verse;
  final verses = start == null
      ? chapter
      : chapter.where((v) => v.verseNumber >= start && v.verseNumber <= end!).toList();
  return (book: book, ref: parsed, verses: verses);
});
