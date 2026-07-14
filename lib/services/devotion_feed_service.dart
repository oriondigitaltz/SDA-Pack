import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/devotion_repository.dart';

/// Where the app pulls daily devotions from. Point this at any URL that
/// serves the feed JSON (see `feed/README.md` in the project root),
/// e.g. a GitHub raw URL:
/// `https://raw.githubusercontent.com/USER/REPO/main/devotions_feed.json`
const String kDevotionFeedUrl =
    'https://raw.githubusercontent.com/oriondigitaltz/sifahymns-feed/main/devotions_feed.json';

/// Pulls the devotion feed and stores every entry dated today or earlier
/// into the repository's cache, where it lives on as a "past study".
///
/// The feed is a JSON map keyed `yyyy-MM-dd`:
/// { "2026-07-14": { "title_en": …, "title_sw": …, "verse_ref": …,
///                   "body_en": …, "body_sw": …, "category": "Faith" } }
class DevotionFeedService {
  final DevotionRepository _repo;
  final http.Client _client;

  DevotionFeedService(this._repo, {http.Client? client})
      : _client = client ?? http.Client();

  static final _dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Returns the number of new entries cached; 0 on any failure
  /// (the app then falls back to bundled content).
  Future<int> refresh({DateTime? now}) async {
    final Map<String, dynamic> feed;
    try {
      final response = await _client
          .get(Uri.parse(kDevotionFeedUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return 0;
      feed = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return 0;
    }

    final today = DevotionRepository.dateKey(now ?? DateTime.now());
    var added = 0;
    for (final entry in feed.entries) {
      if (!_dateKeyPattern.hasMatch(entry.key)) continue;
      if (entry.key.compareTo(today) > 0) continue; // future entries wait their turn
      if (entry.value is! Map<String, dynamic>) continue;
      await _repo.cacheDevotion(entry.key, entry.value as Map<String, dynamic>);
      added++;
    }
    return added;
  }
}
