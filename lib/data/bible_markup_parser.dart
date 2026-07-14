import 'package:flutter/material.dart';

final _brPattern = RegExp(r'<br\s*/?>', caseSensitive: false);
final _tagTokenPattern = RegExp(
  r'<em>|</em>|<font color="([^"]*)">|</font>|<i>|</i>',
  caseSensitive: false,
);
final _anyTagPattern = RegExp(r'<[^>]*>');

const _redLetter = Color(0xFFBF360C);

class ParsedVerseText {
  final List<InlineSpan> english;
  final String swahili;

  const ParsedVerseText({required this.english, required this.swahili});

  bool get hasSwahili => swahili.isNotEmpty;
}

/// Parses the lightweight HTML embedded in this Bible dataset's verse text:
/// `<em>` (translators' added words), `<font color="...">` (words of Christ),
/// `<br/>` (separates the English text from an `<i>`-wrapped Swahili line).
class BibleMarkupParser {
  static ParsedVerseText parse(String raw) {
    final brMatch = _brPattern.firstMatch(raw);
    final englishRaw = brMatch == null ? raw : raw.substring(0, brMatch.start);
    final swahiliRaw = brMatch == null ? '' : raw.substring(brMatch.end);

    return ParsedVerseText(
      english: _parseEnglishSpans(englishRaw.trim()),
      swahili: swahiliRaw.replaceAll(_anyTagPattern, '').trim(),
    );
  }

  /// Plain-text variant used by search: strips all markup from both the
  /// English and Swahili portions of the verse.
  static ({String english, String swahili}) parsePlain(String raw) {
    final brMatch = _brPattern.firstMatch(raw);
    final englishRaw = brMatch == null ? raw : raw.substring(0, brMatch.start);
    final swahiliRaw = brMatch == null ? '' : raw.substring(brMatch.end);
    return (
      english: englishRaw.replaceAll(_anyTagPattern, '').trim(),
      swahili: swahiliRaw.replaceAll(_anyTagPattern, '').trim(),
    );
  }

  static List<InlineSpan> _parseEnglishSpans(String text) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    FontStyle? activeStyle;
    Color? activeColor;

    void emit(String segment) {
      if (segment.isEmpty) return;
      spans.add(TextSpan(
        text: segment,
        style: TextStyle(fontStyle: activeStyle, color: activeColor),
      ));
    }

    for (final match in _tagTokenPattern.allMatches(text)) {
      emit(text.substring(cursor, match.start));
      cursor = match.end;
      final token = match.group(0)!.toLowerCase();
      if (token == '<em>') {
        activeStyle = FontStyle.italic;
      } else if (token == '</em>') {
        activeStyle = null;
      } else if (token.startsWith('<font')) {
        activeColor = _redLetter;
      } else if (token == '</font>') {
        activeColor = null;
      }
      // <i>/</i> around the English portion doesn't occur in this dataset;
      // ignored here (only meaningful in the Swahili line, handled above).
    }
    emit(text.substring(cursor));

    return spans;
  }
}
