import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/collection.dart';
import 'favorites_repository.dart';

const String favoritesCollectionId = 'favorites';

class CollectionsRepository {
  final Box<Collection> _box;

  CollectionsRepository(this._box);

  static Future<CollectionsRepository> open({FavoritesRepository? legacyFavorites}) async {
    final box = await Hive.openBox<Collection>('collections');
    final repo = CollectionsRepository(box);
    await repo._ensureFavoritesCollection(legacyFavorites);
    return repo;
  }

  Future<void> _ensureFavoritesCollection(FavoritesRepository? legacyFavorites) async {
    if (_box.containsKey(favoritesCollectionId)) return;
    final migrated = legacyFavorites?.all.toList() ?? <String>[];
    await _box.put(
      favoritesCollectionId,
      Collection(
        id: favoritesCollectionId,
        name: 'Favorite Hymns',
        hymnIds: migrated,
        builtin: true,
      ),
    );
  }

  List<Collection> get all {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.builtin != b.builtin) return a.builtin ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  Collection? get(String id) => _box.get(id);

  Future<Collection> create(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final collection = Collection(id: id, name: name);
    await _box.put(id, collection);
    return collection;
  }

  Future<void> rename(String id, String name) async {
    final collection = _box.get(id);
    if (collection == null || collection.builtin) return;
    collection.name = name;
    collection.updatedAt = DateTime.now();
    await collection.save();
  }

  Future<void> delete(String id) async {
    final collection = _box.get(id);
    if (collection == null || collection.builtin) return;
    await _box.delete(id);
  }

  Future<void> toggleHymn(String collectionId, String hymnId) async {
    final collection = _box.get(collectionId);
    if (collection == null) return;
    if (collection.hymnIds.contains(hymnId)) {
      collection.hymnIds.remove(hymnId);
    } else {
      collection.hymnIds.add(hymnId);
    }
    collection.updatedAt = DateTime.now();
    await collection.save();
  }

  bool isFavorite(String hymnId) => _box.get(favoritesCollectionId)?.contains(hymnId) ?? false;

  Future<void> toggleFavorite(String hymnId) => toggleHymn(favoritesCollectionId, hymnId);

  Listenable get listenable => _box.listenable();
}
