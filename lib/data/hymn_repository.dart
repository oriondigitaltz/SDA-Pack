import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hymn.dart';
import '../models/hymnal.dart';
import 'markdown_hymn_parser.dart';

/// Content version bump forces a re-parse of bundled markdown into Hive.
/// Increment when the shipped .md/index.json assets change shape.
const int kContentVersion = 2;

class HymnRepository {
  final Box<Hymn> _hymnsBox;
  final Box _settingsBox;

  HymnRepository(this._hymnsBox, this._settingsBox);

  static Future<HymnRepository> open() async {
    final hymnsBox = await _openBoxOrReset<Hymn>('hymns');
    final settingsBox = await _openBoxOrReset('settings');
    return HymnRepository(hymnsBox, settingsBox);
  }

  /// Opens a box, discarding its contents if they were written by an
  /// older, incompatible version of a Hive model (e.g. a field was added).
  /// Hive has no schema migration, so a decode failure is unrecoverable
  /// other than by dropping the stale data and re-deriving it from assets.
  static Future<Box<T>> _openBoxOrReset<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name);
    }
  }

  Future<void> ensureLoaded(Hymnal hymnal) async {
    if (!hymnal.available) return;

    final versionKey = 'content_version_${hymnal.id}';
    final cachedVersion = _settingsBox.get(versionKey) as int?;
    final alreadyLoaded = _hymnsBox.values.any((h) => h.hymnalId == hymnal.id);

    if (alreadyLoaded && cachedVersion == kContentVersion) return;

    if (alreadyLoaded) {
      final staleKeys = _hymnsBox.keys.where((k) {
        final hymn = _hymnsBox.get(k);
        return hymn != null && hymn.hymnalId == hymnal.id;
      }).toList();
      await _hymnsBox.deleteAll(staleKeys);
    }

    final indexRaw = await rootBundle.loadString(hymnal.indexAssetPath);
    final index = jsonDecode(indexRaw) as Map<String, dynamic>;
    final files = (index['files'] as List).cast<String>();

    for (final filename in files) {
      final raw = await rootBundle.loadString(hymnal.assetPathFor(filename));
      final stem = filename.split('.').first;
      final digits = RegExp(r'\d+').firstMatch(stem);
      final fallbackNumber = digits != null ? int.parse(digits.group(0)!) : 0;
      final hymn = MarkdownHymnParser.parse(
        hymnalId: hymnal.id,
        fallbackNumber: fallbackNumber,
        raw: raw,
      );
      await _hymnsBox.put(hymn.id, hymn);
    }

    await _settingsBox.put(versionKey, kContentVersion);
  }

  List<Hymn> getHymns(String hymnalId) {
    final hymns = _hymnsBox.values.where((h) => h.hymnalId == hymnalId).toList();
    hymns.sort((a, b) {
      final byNumber = a.number.compareTo(b.number);
      if (byNumber != 0) return byNumber;
      return a.suffix.compareTo(b.suffix);
    });
    return hymns;
  }

  Hymn? getHymn(String hymnalId, String numberLabel) {
    return _hymnsBox.get('$hymnalId:$numberLabel');
  }

  double get fontScale => (_settingsBox.get('font_scale') as num?)?.toDouble() ?? 1.0;

  Future<void> setFontScale(double scale) => _settingsBox.put('font_scale', scale);

  /// Persisted as 'light'/'dark'; absent means "follow the system theme".
  String? get themeMode => _settingsBox.get('theme_mode') as String?;

  Future<void> setThemeMode(String? mode) {
    if (mode == null) return _settingsBox.delete('theme_mode');
    return _settingsBox.put('theme_mode', mode);
  }
}
