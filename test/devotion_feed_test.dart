import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sifahymns/data/devotion_repository.dart';
import 'package:sifahymns/services/devotion_feed_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DevotionRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('devotion_feed_test');
    Hive.init(tempDir.path);
    repo = DevotionRepository(
      await Hive.openBox<dynamic>('devotion_progress'),
      await Hive.openBox<String>('devotion_cache'),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Map<String, dynamic> entry(String title, {String category = 'Faith'}) => {
        'title_en': title,
        'title_sw': 'SW $title',
        'verse_ref': 'John 3:16',
        'body_en': 'Body of $title',
        'body_sw': 'Mwili wa $title',
        'category': category,
      };

  DevotionFeedService serviceWithFeed(Map<String, dynamic> feed) {
    return DevotionFeedService(
      repo,
      client: MockClient((request) async => http.Response(json.encode(feed), 200)),
    );
  }

  test('caches entries up to today and skips future ones', () async {
    final now = DateTime(2026, 7, 14);
    final feed = {
      '2026-07-13': entry('Yesterday', category: 'Peace'),
      '2026-07-14': entry('Today', category: 'Love'),
      '2026-07-15': entry('Tomorrow'),
      'not-a-date': entry('Garbage'),
    };

    final added = await serviceWithFeed(feed).refresh(now: now);

    expect(added, 2);
    expect(repo.hasCached(DateTime(2026, 7, 13)), isTrue);
    expect(repo.hasCached(DateTime(2026, 7, 14)), isTrue);
    expect(repo.hasCached(DateTime(2026, 7, 15)), isFalse);

    final studies = repo.pastStudies();
    expect(studies.map((d) => d.titleEn), ['Today', 'Yesterday']); // newest first
    expect(studies.first.category, 'Love');
    expect(studies.first.date, '2026-07-14');
  });

  test('forDate prefers the cached feed entry over bundled content', () async {
    final date = DateTime(2026, 7, 14);
    await serviceWithFeed({'2026-07-14': entry('From The Feed')})
        .refresh(now: date);

    final devotion = await repo.forDate(date);
    expect(devotion?.titleEn, 'From The Feed');
  });

  test('forDate falls back to bundled devotions when nothing is cached', () async {
    final devotion = await repo.forDate(DateTime(2026, 7, 14));
    expect(devotion, isNotNull);
    expect(devotion!.titleEn, isNotEmpty);
    expect(devotion.date, isNull); // bundled entries carry no full date
  });

  test('refresh returns 0 on server errors without touching the cache', () async {
    final failing = DevotionFeedService(
      repo,
      client: MockClient((request) async => http.Response('nope', 500)),
    );
    expect(await failing.refresh(), 0);
    expect(repo.pastStudies(), isEmpty);
  });

  test('favorites toggle round-trips through the progress box', () async {
    expect(repo.isFavorite('2026-07-14'), isFalse);
    await repo.setFavorite('2026-07-14', true);
    expect(repo.isFavorite('2026-07-14'), isTrue);
    expect(repo.favoriteDateKeys, {'2026-07-14'});
    await repo.setFavorite('2026-07-14', false);
    expect(repo.favoriteDateKeys, isEmpty);
  });
}
