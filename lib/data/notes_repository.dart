import 'package:hive_flutter/hive_flutter.dart';

class NotesRepository {
  final Box<String> _box;

  NotesRepository(this._box);

  static Future<NotesRepository> open() async {
    final box = await Hive.openBox<String>('hymn_notes');
    return NotesRepository(box);
  }

  String? get(String hymnId) => _box.get(hymnId);

  Future<void> set(String hymnId, String note) async {
    if (note.trim().isEmpty) {
      await _box.delete(hymnId);
    } else {
      await _box.put(hymnId, note);
    }
  }

  Future<void> clear(String hymnId) => _box.delete(hymnId);
}
