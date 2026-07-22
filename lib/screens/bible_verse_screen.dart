import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../data/bible_highlights_repository.dart';
import '../models/bible.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/home_button.dart';

typedef _ChapterRef = (BibleBook book, int chapterNum);

List<_ChapterRef> _flattenChapters(List<BibleBook> books) {
  final flat = <_ChapterRef>[];
  for (final book in books) {
    for (var c = 1; c <= book.chapterCount; c++) {
      flat.add((book, c));
    }
  }
  return flat;
}

/// Shows a Bible chapter and lets the user swipe left/right to move
/// through the rest of the Bible, chapter by chapter (crossing book
/// boundaries at the start/end of each book).
class BibleVerseScreen extends ConsumerStatefulWidget {
  final BibleBook book;
  final int chapterNum;

  /// 1-based verse number to scroll to (and briefly highlight) on open.
  final int? initialVerse;

  const BibleVerseScreen({super.key, required this.book, required this.chapterNum, this.initialVerse});

  @override
  ConsumerState<BibleVerseScreen> createState() => _BibleVerseScreenState();
}

class _BibleVerseScreenState extends ConsumerState<BibleVerseScreen> {
  PageController? _pageController;
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(fontScaleProvider);
    final booksAsync = ref.watch(bibleBooksProvider);

    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: booksAsync.maybeWhen(
          data: (books) {
            final flat = _flattenChapters(books);
            final index = _currentIndex.clamp(0, flat.length - 1);
            final (book, chapterNum) = flat[index];
            return Text('${book.title} $chapterNum', style: const TextStyle(fontWeight: FontWeight.w700));
          },
          orElse: () => Text('${widget.book.title} ${widget.chapterNum}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(fontScaleProvider.notifier).decrease(),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            onPressed: () => ref.read(fontScaleProvider.notifier).increase(),
            icon: const Icon(Icons.text_increase_rounded),
          ),
          const AppHeaderActions(),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load Bible: $err')),
        data: (books) {
          final flat = _flattenChapters(books);
          final startIndex = flat.indexWhere((c) => c.$1.id == widget.book.id && c.$2 == widget.chapterNum);
          final initialPage = startIndex >= 0 ? startIndex : 0;
          _pageController ??= PageController(initialPage: initialPage);

          return PageView.builder(
            controller: _pageController,
            itemCount: flat.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              final (book, chapterNum) = flat[i];
              return _ChapterPage(
                book: book,
                chapterNum: chapterNum,
                fontScale: fontScale,
                initialVerse: i == initialPage ? widget.initialVerse : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChapterPage extends ConsumerWidget {
  final BibleBook book;
  final int chapterNum;
  final double fontScale;
  final int? initialVerse;

  const _ChapterPage({
    required this.book,
    required this.chapterNum,
    required this.fontScale,
    required this.initialVerse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(bibleChapterProvider((bookId: book.id, chapterNum: chapterNum)));

    return versesAsync.when(
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
            final jumpedTo = initialVerse != null && verse.verseNumber == initialVerse;
            return _VerseTile(
              book: book,
              chapterNum: chapterNum,
              verse: verse,
              fontScale: fontScale,
              jumpedTo: jumpedTo,
            );
          },
        );
      },
    );
  }
}

class _VerseTile extends ConsumerWidget {
  final BibleBook book;
  final int chapterNum;
  final BibleVerse verse;
  final double fontScale;
  final bool jumpedTo;

  const _VerseTile({
    required this.book,
    required this.chapterNum,
    required this.verse,
    required this.fontScale,
    required this.jumpedTo,
  });

  String get _key => BibleHighlightsRepository.keyFor(book.id, chapterNum, verse.verseNumber);

  String get _plainText {
    final buffer = StringBuffer();
    for (final span in verse.english) {
      buffer.write(span.toPlainText());
    }
    return buffer.toString();
  }

  Future<void> _copy(BuildContext context) async {
    final text = '${book.title} $chapterNum:${verse.verseNumber}  $_plainText';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verse copied')),
    );
  }

  Future<void> _pickColor(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(verseHighlightProvider(_key).notifier);
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final color in kBibleHighlightColors)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    notifier.setColor(color);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  notifier.clear();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                  ),
                  child: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightColor = ref.watch(verseHighlightProvider(_key));
    final background = highlightColor ??
        (jumpedTo ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : null);

    return GestureDetector(
      onTap: () => _copy(context),
      onLongPress: () => _pickColor(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: background != null ? const EdgeInsets.all(10) : EdgeInsets.zero,
        decoration: background != null
            ? BoxDecoration(color: background, borderRadius: BorderRadius.circular(12))
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
      ),
    );
  }
}
