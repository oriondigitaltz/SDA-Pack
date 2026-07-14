import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/study_guide.dart';

const String _kApiBase = 'https://sabbath-school.adventech.io/api/v2';

/// Fetches Sabbath School study guides (quarterlies → lessons → daily
/// readings) from the Adventech API in English (`en`) and Swahili (`sw`).
///
/// Every successful response is cached in Hive keyed by its API path, so
/// anything the user has opened before keeps working offline; on network
/// failure the cache is served instead.
class StudyGuideRepository {
  final Box<String> _cacheBox;
  final http.Client _client;

  StudyGuideRepository(this._cacheBox, {http.Client? client})
      : _client = client ?? http.Client();

  static Future<StudyGuideRepository> open() async {
    final box = await Hive.openBox<String>('study_guide_cache');
    return StudyGuideRepository(box);
  }

  Future<dynamic> _getJson(String path) async {
    final url = '$_kApiBase/$path/index.json';
    try {
      final response =
          await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        // The SPA host answers unknown paths with HTML, not a JSON error.
        final decoded = json.decode(body);
        await _cacheBox.put(path, body);
        return decoded;
      }
    } catch (_) {
      // Fall through to cache.
    }
    final cached = _cacheBox.get(path);
    if (cached != null) return json.decode(cached);
    throw Exception('No internet connection and no saved copy for this guide.');
  }

  Future<List<StudyQuarterly>> quarterlies(String lang) async {
    final decoded = await _getJson('$lang/quarterlies') as List<dynamic>;
    return [
      for (final item in decoded)
        StudyQuarterly.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<StudyLesson>> lessons(String lang, String quarterlyId) async {
    final decoded =
        await _getJson('$lang/quarterlies/$quarterlyId') as Map<String, dynamic>;
    return [
      for (final item in decoded['lessons'] as List<dynamic>? ?? [])
        StudyLesson.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// [lessonPath] is `StudyLesson.path`, e.g. `en/quarterlies/2026-03/lessons/01`.
  Future<List<StudyDay>> days(String lessonPath) async {
    final decoded = await _getJson(lessonPath) as Map<String, dynamic>;
    return [
      for (final item in decoded['days'] as List<dynamic>? ?? [])
        StudyDay.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// [readPath] is `StudyDay.readPath`, e.g. `…/days/01/read`.
  Future<StudyDayRead> dayRead(String readPath) async {
    final decoded = await _getJson(readPath) as Map<String, dynamic>;
    return StudyDayRead.fromJson(decoded);
  }
}
