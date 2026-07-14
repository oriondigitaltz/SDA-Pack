import 'package:hive/hive.dart';

part 'hymn.g.dart';

class HymnBlock {
  final String text;
  final bool isChorus;

  const HymnBlock({required this.text, required this.isChorus});
}

@HiveType(typeId: 0)
class Hymn extends HiveObject {
  @HiveField(0)
  final String hymnalId;

  @HiveField(1)
  final int number;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final List<String> blockTexts;

  @HiveField(4)
  final List<bool> blockIsChorus;

  /// Distinguishes alternate-tune variants of the same hymn number,
  /// e.g. hymn 26 and its variant "26a". Empty for the primary hymn.
  @HiveField(5)
  final String suffix;

  Hymn({
    required this.hymnalId,
    required this.number,
    required this.title,
    required this.blockTexts,
    required this.blockIsChorus,
    this.suffix = '',
  });

  String get numberLabel => suffix.isEmpty ? '$number' : '$number$suffix';

  String get id => '$hymnalId:$numberLabel';

  List<HymnBlock> get blocks => [
        for (var i = 0; i < blockTexts.length; i++)
          HymnBlock(text: blockTexts[i], isChorus: blockIsChorus[i]),
      ];

  String get searchableLyrics => blockTexts.join(' ').toLowerCase();
}
