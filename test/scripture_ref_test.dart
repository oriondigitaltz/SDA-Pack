import 'package:flutter_test/flutter_test.dart';
import 'package:sifahymns/data/scripture_ref.dart';
import 'package:sifahymns/models/bible.dart';

void main() {
  group('ScriptureRef.parse', () {
    test('parses book chapter:verse', () {
      final ref = ScriptureRef.parse('John 3:16');
      expect(ref, isNotNull);
      expect(ref!.book, 'John');
      expect(ref.chapter, 3);
      expect(ref.verse, 16);
      expect(ref.endVerse, isNull);
    });

    test('parses numbered book with verse range', () {
      final ref = ScriptureRef.parse('1 Corinthians 13:4-7');
      expect(ref, isNotNull);
      expect(ref!.book, '1 Corinthians');
      expect(ref.chapter, 13);
      expect(ref.verse, 4);
      expect(ref.endVerse, 7);
    });

    test('parses chapter-only reference', () {
      final ref = ScriptureRef.parse('Psalms 23');
      expect(ref, isNotNull);
      expect(ref!.book, 'Psalms');
      expect(ref.chapter, 23);
      expect(ref.verse, isNull);
    });

    test('parses multi-word book names', () {
      final ref = ScriptureRef.parse('Song of Solomon 8:7');
      expect(ref, isNotNull);
      expect(ref!.book, 'Song of Solomon');
      expect(ref.chapter, 8);
      expect(ref.verse, 7);
    });

    test('returns null for garbage', () {
      expect(ScriptureRef.parse('not a reference'), isNull);
      expect(ScriptureRef.parse(''), isNull);
    });

    test('resolveBook matches case-insensitively', () {
      const books = [
        BibleBook(id: 1, title: 'Genesis', chapterCount: 50, testament: Testament.old),
        BibleBook(id: 2, title: '1 Corinthians', chapterCount: 16, testament: Testament.newTestament),
      ];
      final ref = ScriptureRef.parse('1 corinthians 13:4')!;
      expect(ref.resolveBook(books)?.id, 2);
      expect(ScriptureRef.parse('Exodus 1:1')!.resolveBook(books), isNull);
    });

    test('label round-trips', () {
      expect(ScriptureRef.parse('John 3:16-17')!.label, 'John 3:16-17');
      expect(ScriptureRef.parse('Psalms 23')!.label, 'Psalms 23');
    });
  });
}
