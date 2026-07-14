import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sifahymns/data/scripture_ref.dart';
import 'package:sifahymns/models/belief.dart';
import 'package:sifahymns/models/devotion.dart';

void main() {
  group('bundled content assets', () {
    test('devotions.json has 366 well-formed entries', () {
      final raw = File('assets/devotions/devotions.json').readAsStringSync();
      final decoded = json.decode(raw) as Map<String, dynamic>;
      expect(decoded.length, 366);

      for (final entry in decoded.entries) {
        final devotion = Devotion.fromJson(entry.key, entry.value as Map<String, dynamic>);
        expect(devotion.titleEn, isNotEmpty, reason: 'title_en missing for ${entry.key}');
        expect(devotion.titleSw, isNotEmpty, reason: 'title_sw missing for ${entry.key}');
        expect(devotion.bodyEn, isNotEmpty, reason: 'body_en missing for ${entry.key}');
        expect(devotion.bodySw, isNotEmpty, reason: 'body_sw missing for ${entry.key}');
        expect(ScriptureRef.parse(devotion.verseRef), isNotNull,
            reason: 'unparseable verse_ref "${devotion.verseRef}" for ${entry.key}');
      }

      // Every day of a leap year is covered, including Feb 29.
      final start = DateTime(2024, 1, 1);
      for (var d = start; d.year == 2024; d = d.add(const Duration(days: 1))) {
        final key = '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        expect(decoded.containsKey(key), isTrue, reason: 'missing devotion for $key');
      }
    });

    test('beliefs.json has 28 well-formed entries with parseable references', () {
      final raw = File('assets/beliefs/beliefs.json').readAsStringSync();
      final decoded = json.decode(raw) as List<dynamic>;
      expect(decoded.length, 28);

      final beliefs = [for (final b in decoded) Belief.fromJson(b as Map<String, dynamic>)];
      final numbers = beliefs.map((b) => b.number).toSet();
      expect(numbers, {for (var n = 1; n <= 28; n++) n});

      for (final belief in beliefs) {
        expect(belief.titleEn, isNotEmpty);
        expect(belief.titleSw, isNotEmpty);
        expect(belief.summaryEn, isNotEmpty);
        expect(belief.bodyEn, isNotEmpty);
        expect(belief.references, isNotEmpty);
        for (final ref in belief.references) {
          expect(ScriptureRef.parse(ref), isNotNull,
              reason: 'unparseable reference "$ref" in belief ${belief.number}');
        }
      }
    });
  });
}
