class Belief {
  final int number;
  final String category;
  final String titleEn;
  final String titleSw;
  final String summaryEn;
  final String summarySw;
  final String bodyEn;
  final String bodySw;

  /// Scripture references resolvable against the bundled Bible DB,
  /// e.g. `John 3:16` (book titles match the `chapters` table).
  final List<String> references;

  const Belief({
    required this.number,
    required this.category,
    required this.titleEn,
    required this.titleSw,
    required this.summaryEn,
    required this.summarySw,
    required this.bodyEn,
    required this.bodySw,
    required this.references,
  });

  factory Belief.fromJson(Map<String, dynamic> json) {
    return Belief(
      number: json['number'] as int,
      category: json['category'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleSw: json['title_sw'] as String? ?? '',
      summaryEn: json['summary_en'] as String? ?? '',
      summarySw: json['summary_sw'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      bodySw: json['body_sw'] as String? ?? '',
      references: [for (final r in (json['references'] as List? ?? const [])) r as String],
    );
  }
}
