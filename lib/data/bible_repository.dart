import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bible.dart';
import 'bible_markup_parser.dart';

const String _kAssetDbPath = 'assets/bible/bible_eng_swa_n.sqlite';
const String _kDbFileName = 'bible_eng_swa_n.sqlite';

class BibleRepository {
  final Database _db;

  BibleRepository(this._db);

  static Future<BibleRepository> open() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbDir.path, _kDbFileName);

    if (!await File(dbPath).exists()) {
      final bytes = await rootBundle.load(_kAssetDbPath);
      await File(dbPath).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    final db = await openDatabase(dbPath, readOnly: true);
    return BibleRepository(db);
  }

  Future<List<BibleBook>> getBooks() async {
    final rows = await _db.query('chapters', orderBy: '_id ASC');
    return [
      for (final row in rows)
        BibleBook(
          id: row['_id'] as int,
          title: row['title'] as String? ?? '',
          chapterCount: row['num'] as int? ?? 0,
          testament: (row['mode'] as int? ?? 1) == 1 ? Testament.old : Testament.newTestament,
        ),
    ];
  }

  List<BibleBook>? _booksCache;

  Future<Map<int, BibleBook>> _booksById() async {
    _booksCache ??= await getBooks();
    return {for (final book in _booksCache!) book.id: book};
  }

  /// Case-insensitive word/phrase search across all verse text
  /// (both the English and Swahili portions live in the same column).
  Future<List<BibleSearchResult>> search(String query, {int limit = 100}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final escaped = trimmed.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
    final rows = await _db.query(
      'texts',
      columns: ['chapter_id', 'chapter_num', 'rank', 'text'],
      where: "text LIKE ? ESCAPE '\\'",
      whereArgs: ['%$escaped%'],
      orderBy: 'chapter_id ASC, chapter_num ASC, rank ASC',
      limit: limit,
    );

    final books = await _booksById();
    final results = <BibleSearchResult>[];
    for (final row in rows) {
      final book = books[row['chapter_id'] as int?];
      if (book == null) continue;
      final parsed = BibleMarkupParser.parsePlain(row['text'] as String? ?? '');
      results.add(BibleSearchResult(
        book: book,
        chapterNum: row['chapter_num'] as int? ?? 0,
        verseNum: row['rank'] as int? ?? 0,
        english: parsed.english,
        swahili: parsed.swahili,
      ));
    }
    return results;
  }

  Future<List<BibleVerse>> getChapter(int bookId, int chapterNum) async {
    final rows = await _db.query(
      'texts',
      where: 'chapter_id = ? AND chapter_num = ?',
      whereArgs: [bookId, chapterNum],
      orderBy: 'rank ASC',
    );
    final verses = <BibleVerse>[];
    for (final row in rows) {
      final parsed = BibleMarkupParser.parse(row['text'] as String? ?? '');
      verses.add(BibleVerse(
        verseNumber: row['rank'] as int? ?? 0,
        english: parsed.english,
        swahili: parsed.swahili,
      ));
    }
    return verses;
  }
}
