class Devotion {
  /// Key in the bundled content file, formatted `MM-DD`.
  final String monthDay;
  final String titleEn;
  final String titleSw;

  /// Scripture reference resolved against the bundled Bible DB,
  /// e.g. `Psalms 23:1` (book titles match the `chapters` table).
  final String verseRef;
  final String bodyEn;
  final String bodySw;

  /// Optional topical category from the online feed (e.g. `Love`, `Peace`).
  final String? category;

  /// Full `yyyy-MM-dd` date for devotions cached from the online feed;
  /// null for the bundled year-agnostic entries.
  final String? date;

  const Devotion({
    required this.monthDay,
    required this.titleEn,
    required this.titleSw,
    required this.verseRef,
    required this.bodyEn,
    required this.bodySw,
    this.category,
    this.date,
  });

  factory Devotion.fromJson(String monthDay, Map<String, dynamic> json, {String? date}) {
    return Devotion(
      monthDay: monthDay,
      titleEn: json['title_en'] as String? ?? '',
      titleSw: json['title_sw'] as String? ?? '',
      verseRef: json['verse_ref'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      bodySw: json['body_sw'] as String? ?? '',
      category: json['category'] as String?,
      date: date,
    );
  }

  Map<String, dynamic> toJson() => {
        'title_en': titleEn,
        'title_sw': titleSw,
        'verse_ref': verseRef,
        'body_en': bodyEn,
        'body_sw': bodySw,
        if (category != null) 'category': category,
      };
}
