import 'package:hive_flutter/hive_flutter.dart';

class BibleHighlightsRepository {
  final Box<String> _box;

  BibleHighlightsRepository(this._box);

  static Future<BibleHighlightsRepository> open() async {
    final box = await Hive.openBox<String>('bible_highlights');
    return BibleHighlightsRepository(box);
  }

  static String keyFor(int bookId, int chapterNum, int verseNumber) =>
      '$bookId:$chapterNum:$verseNumber';

  String? get(String key) => _box.get(key);

  Future<void> set(String key, String colorHex) => _box.put(key, colorHex);

  Future<void> clear(String key) => _box.delete(key);
}
