import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bible_repository.dart';
import '../data/collections_repository.dart';
import '../data/hymn_repository.dart';
import '../data/notes_repository.dart';
import '../models/bible.dart';
import '../models/collection.dart';
import '../models/hymn.dart';
import '../models/hymnal.dart';

final hymnRepositoryProvider = Provider<HymnRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

final hymnsForHymnalProvider = FutureProvider.family<List<Hymn>, String>((ref, hymnalId) async {
  final repo = ref.watch(hymnRepositoryProvider);
  final hymnal = hymnalRegistry.firstWhere((h) => h.id == hymnalId);
  await repo.ensureLoaded(hymnal);
  return repo.getHymns(hymnalId);
});

final allHymnsProvider = FutureProvider<List<Hymn>>((ref) async {
  final lists = await Future.wait([
    for (final hymnal in hymnalRegistry.where((h) => h.available))
      ref.watch(hymnsForHymnalProvider(hymnal.id).future),
  ]);
  return [for (final list in lists) ...list];
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredHymnsProvider = Provider.family<AsyncValue<List<Hymn>>, String>((ref, hymnalId) {
  final hymnsAsync = ref.watch(hymnsForHymnalProvider(hymnalId));
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return hymnsAsync.whenData((hymns) => _filterHymns(hymns, query));
});

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final globalFilteredHymnsProvider = Provider<AsyncValue<List<Hymn>>>((ref) {
  final hymnsAsync = ref.watch(allHymnsProvider);
  final query = ref.watch(globalSearchQueryProvider).trim().toLowerCase();
  return hymnsAsync.whenData((hymns) => query.isEmpty ? const [] : _filterHymns(hymns, query));
});

List<Hymn> _filterHymns(List<Hymn> hymns, String query) {
  if (query.isEmpty) return hymns;
  return hymns.where((h) {
    if (h.numberLabel.toLowerCase() == query) return true;
    if (h.title.toLowerCase().contains(query)) return true;
    if (h.searchableLyrics.contains(query)) return true;
    return false;
  }).toList();
}

class CollectionsNotifier extends StateNotifier<List<Collection>> {
  final CollectionsRepository _repo;

  CollectionsNotifier(this._repo) : super(_repo.all);

  void _refresh() => state = _repo.all;

  bool isFavorite(String hymnId) => _repo.isFavorite(hymnId);

  Future<void> toggleFavorite(String hymnId) async {
    await _repo.toggleFavorite(hymnId);
    _refresh();
  }

  Future<void> toggleHymn(String collectionId, String hymnId) async {
    await _repo.toggleHymn(collectionId, hymnId);
    _refresh();
  }

  Future<Collection> create(String name) async {
    final collection = await _repo.create(name);
    _refresh();
    return collection;
  }

  Future<void> rename(String id, String name) async {
    await _repo.rename(id, name);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _refresh();
  }
}

final collectionsProvider = StateNotifierProvider<CollectionsNotifier, List<Collection>>((ref) {
  return CollectionsNotifier(ref.watch(collectionsRepositoryProvider));
});

class FontScaleNotifier extends StateNotifier<double> {
  final HymnRepository _repo;

  FontScaleNotifier(this._repo) : super(_repo.fontScale);

  static const double _min = 0.75;
  static const double _max = 2.0;
  static const double _step = 0.1;

  Future<void> increase() async {
    state = (state + _step).clamp(_min, _max);
    await _repo.setFontScale(state);
  }

  Future<void> decrease() async {
    state = (state - _step).clamp(_min, _max);
    await _repo.setFontScale(state);
  }
}

final fontScaleProvider = StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier(ref.watch(hymnRepositoryProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final HymnRepository _repo;

  ThemeModeNotifier(this._repo) : super(_fromStored(_repo.themeMode));

  static ThemeMode _fromStored(String? mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await _repo.setThemeMode(dark ? 'dark' : 'light');
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(hymnRepositoryProvider));
});

class HymnNoteNotifier extends StateNotifier<String?> {
  final NotesRepository _repo;
  final String hymnId;

  HymnNoteNotifier(this._repo, this.hymnId) : super(_repo.get(hymnId));

  Future<void> save(String note) async {
    await _repo.set(hymnId, note);
    state = note.trim().isEmpty ? null : note;
  }

  Future<void> clear() async {
    await _repo.clear(hymnId);
    state = null;
  }
}

final hymnNoteProvider =
    StateNotifierProvider.family<HymnNoteNotifier, String?, String>((ref, hymnId) {
  return HymnNoteNotifier(ref.watch(notesRepositoryProvider), hymnId);
});

final bibleSearchQueryProvider = StateProvider<String>((ref) => '');

/// Minimum query length before a Bible full-text scan is run.
const int kMinBibleSearchLength = 3;

final bibleSearchResultsProvider = FutureProvider<List<BibleSearchResult>>((ref) async {
  final query = ref.watch(bibleSearchQueryProvider).trim();
  if (query.length < kMinBibleSearchLength) return const [];
  // Small debounce so we don't scan the whole Bible on every keystroke;
  // if the query changed while waiting, skip the stale scan.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  if (ref.read(bibleSearchQueryProvider).trim() != query) return const [];
  return ref.read(bibleRepositoryProvider).search(query);
});

final bibleBooksProvider = FutureProvider<List<BibleBook>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBooks();
});

final bibleChapterProvider =
    FutureProvider.family<List<BibleVerse>, ({int bookId, int chapterNum})>((ref, args) {
  return ref.watch(bibleRepositoryProvider).getChapter(args.bookId, args.chapterNum);
});
