import '../models/bible.dart';

/// A parsed scripture reference like `John 3:16`, `Psalms 23:1-3`,
/// or `1 Corinthians 13:4`. Book names match the bundled Bible DB titles.
class ScriptureRef {
  final String book;
  final int chapter;
  final int? verse;
  final int? endVerse;

  const ScriptureRef({required this.book, required this.chapter, this.verse, this.endVerse});

  static final _pattern = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

  static ScriptureRef? parse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    return ScriptureRef(
      book: match.group(1)!.trim(),
      chapter: int.parse(match.group(2)!),
      verse: match.group(3) != null ? int.parse(match.group(3)!) : null,
      endVerse: match.group(4) != null ? int.parse(match.group(4)!) : null,
    );
  }

  /// Finds the referenced book in [books] (case-insensitive title match).
  BibleBook? resolveBook(List<BibleBook> books) {
    final lower = book.toLowerCase();
    for (final b in books) {
      if (b.title.toLowerCase() == lower) return b;
    }
    return null;
  }

  String get label => verse == null
      ? '$book $chapter'
      : endVerse == null
          ? '$book $chapter:$verse'
          : '$book $chapter:$verse-$endVerse';
}
