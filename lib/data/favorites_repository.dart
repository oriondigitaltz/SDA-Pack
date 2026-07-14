import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesRepository {
  final Box<bool> _box;

  FavoritesRepository(this._box);

  static Future<FavoritesRepository> open() async {
    final box = await Hive.openBox<bool>('favorites');
    return FavoritesRepository(box);
  }

  bool isFavorite(String hymnId) => _box.get(hymnId) ?? false;

  Future<void> toggle(String hymnId) async {
    final current = isFavorite(hymnId);
    if (current) {
      await _box.delete(hymnId);
    } else {
      await _box.put(hymnId, true);
    }
  }

  Set<String> get all => _box.keys.cast<String>().toSet();

  Listenable get listenable => _box.listenable();
}
