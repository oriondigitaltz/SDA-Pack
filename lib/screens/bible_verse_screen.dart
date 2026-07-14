import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/bible.dart';
import '../providers/hymnal_providers.dart';

class BibleVerseScreen extends ConsumerWidget {
  final BibleBook book;
  final int chapterNum;

  /// 1-based verse number to scroll to (and briefly highlight) on open.
  final int? initialVerse;

  const BibleVerseScreen({super.key, required this.book, required this.chapterNum, this.initialVerse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider);
    final versesAsync = ref.watch(bibleChapterProvider((bookId: book.id, chapterNum: chapterNum)));

    return Scaffold(
      appBar: AppBar(
        title: Text('${book.title} $chapterNum', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => ref.read(fontScaleProvider.notifier).decrease(),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            onPressed: () => ref.read(fontScaleProvider.notifier).increase(),
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      ),
      body: versesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load chapter: $err')),
        data: (verses) {
          var initialIndex = 0;
          if (initialVerse != null) {
            final idx = verses.indexWhere((v) => v.verseNumber == initialVerse);
            if (idx >= 0) initialIndex = idx;
          }
          return ScrollablePositionedList.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            initialScrollIndex: initialIndex,
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              final highlighted = initialVerse != null && verse.verseNumber == initialVerse;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: highlighted ? const EdgeInsets.all(10) : EdgeInsets.zero,
                decoration: highlighted
                    ? BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16 * fontScale, height: 1.6),
                    children: [
                      TextSpan(
                        text: '${verse.verseNumber}  ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      ...verse.english,
                      if (verse.hasSwahili) ...[
                        const TextSpan(text: '\n'),
                        TextSpan(
                          text: verse.swahili,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
