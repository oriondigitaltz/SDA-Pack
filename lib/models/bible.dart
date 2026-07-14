import 'package:flutter/material.dart';

enum Testament { old, newTestament }

class BibleBook {
  final int id;
  final String title;
  final int chapterCount;
  final Testament testament;

  const BibleBook({
    required this.id,
    required this.title,
    required this.chapterCount,
    required this.testament,
  });
}

class BibleSearchResult {
  final BibleBook book;
  final int chapterNum;
  final int verseNum;
  final String english;
  final String swahili;

  const BibleSearchResult({
    required this.book,
    required this.chapterNum,
    required this.verseNum,
    required this.english,
    required this.swahili,
  });

  String get reference => '${book.title} $chapterNum:$verseNum';
}

class BibleVerse {
  final int verseNumber;
  final List<InlineSpan> english;
  final String swahili;

  const BibleVerse({
    required this.verseNumber,
    required this.english,
    this.swahili = '',
  });

  bool get hasSwahili => swahili.isNotEmpty;
}
