import '../models/hymn.dart';

final _plainHeaderPattern = RegExp(r'^(\d+)([a-zA-Z]*)-\s*(.*)$');
final _chorusLabelPattern = RegExp(r'^(chorus|refrain)$', caseSensitive: false);

/// Parses a single hymn source file into a [Hymn].
///
/// Two header formats are supported:
///  - Markdown: first line is `## Title`; the hymn number comes from the
///    filename (passed in as [fallbackNumber]).
///  - Plain text (Swahili hymnal): first line is `NUMBER[suffix]-Title`
///    (e.g. `026a-Tupe Amani`), optionally followed by 1-2 metadata lines
///    (an English cross-reference title, a "Doh ni X" key signature) before
///    the first blank line. Those metadata lines are discarded.
///
/// In both formats the body is blank-line separated paragraphs, and a
/// paragraph whose first line is exactly `Chorus`/`CHORUS`/`Refrain` marks
/// the rest of that paragraph as the chorus.
class MarkdownHymnParser {
  static Hymn parse({
    required String hymnalId,
    required int fallbackNumber,
    required String raw,
  }) {
    final lines = raw.replaceFirst('﻿', '').split('\n').map((l) => l.trimRight()).toList();

    var i = 0;
    while (i < lines.length && lines[i].trim().isEmpty) {
      i++;
    }

    var title = '';
    var number = fallbackNumber;
    var suffix = '';

    if (i < lines.length && lines[i].trimLeft().startsWith('#')) {
      title = lines[i].replaceFirst(RegExp(r'^#+\s*'), '').trim();
      i++;
    } else if (i < lines.length && _plainHeaderPattern.hasMatch(lines[i].trim())) {
      final match = _plainHeaderPattern.firstMatch(lines[i].trim())!;
      number = int.parse(match.group(1)!);
      suffix = match.group(2)!;
      title = match.group(3)!.trim();
      i++;
      // Skip optional metadata lines (cross-reference title, key signature)
      // up to the first blank line.
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        i++;
      }
    }

    final paragraphs = <List<String>>[];
    var current = <String>[];
    for (; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (current.isNotEmpty) {
          paragraphs.add(current);
          current = [];
        }
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) {
      paragraphs.add(current);
    }

    final blockTexts = <String>[];
    final blockIsChorus = <bool>[];

    for (final para in paragraphs) {
      var body = para;
      var isChorus = false;
      if (para.isNotEmpty && _chorusLabelPattern.hasMatch(para.first)) {
        isChorus = true;
        body = para.sublist(1);
      }
      if (body.isEmpty) continue;
      blockTexts.add(body.join('\n'));
      blockIsChorus.add(isChorus);
    }

    return Hymn(
      hymnalId: hymnalId,
      number: number,
      suffix: suffix,
      title: title,
      blockTexts: blockTexts,
      blockIsChorus: blockIsChorus,
    );
  }
}
