import 'package:flutter/material.dart';

import '../models/bible.dart';
import 'bible_verse_screen.dart';

class BibleChapterScreen extends StatelessWidget {
  final BibleBook book;

  const BibleChapterScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w700))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: book.chapterCount,
        itemBuilder: (context, index) {
          final chapterNum = index + 1;
          return Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BibleVerseScreen(book: book, chapterNum: chapterNum),
                ),
              ),
              child: Center(
                child: Text('$chapterNum', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          );
        },
      ),
    );
  }
}
