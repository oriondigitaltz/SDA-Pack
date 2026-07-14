import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/belief.dart';

const String _kAssetPath = 'assets/beliefs/beliefs.json';

class BeliefsRepository {
  final Box<dynamic> _viewedBox;
  List<Belief>? _beliefs;

  BeliefsRepository(this._viewedBox);

  static Future<BeliefsRepository> open() async {
    final box = await Hive.openBox<dynamic>('beliefs_viewed');
    return BeliefsRepository(box);
  }

  Future<List<Belief>> getAll() async {
    if (_beliefs != null) return _beliefs!;
    final raw = await rootBundle.loadString(_kAssetPath);
    final decoded = json.decode(raw) as List<dynamic>;
    _beliefs = [for (final item in decoded) Belief.fromJson(item as Map<String, dynamic>)]
      ..sort((a, b) => a.number.compareTo(b.number));
    return _beliefs!;
  }

  bool isViewed(int number) => _viewedBox.get(number) == true;

  Set<int> get viewedNumbers =>
      {for (final key in _viewedBox.keys) if (key is int && _viewedBox.get(key) == true) key};

  Future<void> markViewed(int number) => _viewedBox.put(number, true);
}
