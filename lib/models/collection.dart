import 'package:hive/hive.dart';

part 'collection.g.dart';

@HiveType(typeId: 1)
class Collection extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final List<String> hymnIds;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  /// Built-in collections (e.g. "Favorite Hymns") can't be renamed/deleted.
  @HiveField(5)
  final bool builtin;

  Collection({
    required this.id,
    required this.name,
    List<String>? hymnIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.builtin = false,
  })  : hymnIds = hymnIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool contains(String hymnId) => hymnIds.contains(hymnId);
}
