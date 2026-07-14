import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible.dart';
import '../models/hymn.dart';
import '../models/hymnal.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/app_side_drawer.dart';
import '../widgets/search_field.dart';
import 'bible_verse_screen.dart';
import 'hymn_detail_screen.dart';

enum SearchScope { songs, bible }

final searchScopeProvider = StateProvider<SearchScope>((ref) => SearchScope.songs);

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(searchScopeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24))),
      drawer: const AppSideDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchField(
              hintText: scope == SearchScope.songs ? 'Search songs by number, title, or lyrics' : 'Search words in the Bible',
              onChanged: (value) {
                ref.read(globalSearchQueryProvider.notifier).state = value;
                ref.read(bibleSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<SearchScope>(
              segments: const [
                ButtonSegment(value: SearchScope.songs, label: Text('Songs'), icon: Icon(Icons.music_note_rounded)),
                ButtonSegment(value: SearchScope.bible, label: Text('Bible'), icon: Icon(Icons.menu_book_rounded)),
              ],
              selected: {scope},
              onSelectionChanged: (selection) => ref.read(searchScopeProvider.notifier).state = selection.first,
            ),
          ),
          Expanded(
            child: scope == SearchScope.songs ? const _SongResults() : const _BibleResults(),
          ),
        ],
      ),
    );
  }
}

class _SongResults extends ConsumerWidget {
  const _SongResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(globalFilteredHymnsProvider);
    final hasQuery = ref.watch(globalSearchQueryProvider).trim().isNotEmpty;

    if (!hasQuery) {
      return const _SearchHint(
        icon: Icons.music_note_rounded,
        message: 'Search all songs by number,\ntitle, or lyrics',
      );
    }
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Search failed: $err')),
      data: (hymns) => hymns.isEmpty
          ? const _SearchHint(icon: Icons.search_off_rounded, message: 'No songs found')
          : ListView.builder(
              itemCount: hymns.length,
              itemBuilder: (context, index) {
                final hymn = hymns[index];
                return ListTile(
                  leading: SizedBox(
                    width: 32,
                    child: Text(hymn.numberLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  title: Text(hymn.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_hymnalName(hymn)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          HymnDetailScreen(hymnalId: hymn.hymnalId, numberLabel: hymn.numberLabel),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _hymnalName(Hymn hymn) {
    return hymnalRegistry.firstWhere((h) => h.id == hymn.hymnalId).displayName;
  }
}

class _BibleResults extends ConsumerWidget {
  const _BibleResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(bibleSearchQueryProvider).trim();
    final resultsAsync = ref.watch(bibleSearchResultsProvider);

    if (query.length < kMinBibleSearchLength) {
      return const _SearchHint(
        icon: Icons.menu_book_rounded,
        message: 'Type at least 3 letters to search\nthe Bible in English or Swahili',
      );
    }
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Search failed: $err')),
      data: (results) => results.isEmpty
          ? const _SearchHint(icon: Icons.search_off_rounded, message: 'No verses found')
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) => _VerseResultTile(result: results[index], query: query),
            ),
    );
  }
}

class _VerseResultTile extends StatelessWidget {
  final BibleSearchResult result;
  final String query;

  const _VerseResultTile({required this.result, required this.query});

  @override
  Widget build(BuildContext context) {
    final snippetSource = _matchingText();
    return ListTile(
      isThreeLine: true,
      title: Text(result.reference, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: _HighlightedText(text: snippetSource, query: query),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BibleVerseScreen(
            book: result.book,
            chapterNum: result.chapterNum,
            initialVerse: result.verseNum,
          ),
        ),
      ),
    );
  }

  /// Prefer showing the language line that actually matched the query.
  String _matchingText() {
    final q = query.toLowerCase();
    if (result.english.toLowerCase().contains(q)) return result.english;
    if (result.swahili.toLowerCase().contains(q)) return result.swahili;
    return result.english.isNotEmpty ? result.english : result.swahili;
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.primary,
    );

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var cursor = 0;
    while (true) {
      final idx = lower.indexOf(q, cursor);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }
      if (idx > cursor) spans.add(TextSpan(text: text.substring(cursor, idx)));
      spans.add(TextSpan(text: text.substring(idx, idx + q.length), style: highlightStyle));
      cursor = idx + q.length;
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

class _SearchHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SearchHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 14.5)),
        ],
      ),
    );
  }
}
