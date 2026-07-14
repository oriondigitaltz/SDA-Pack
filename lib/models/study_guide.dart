/// Models for the Adventech Sabbath School study guide API
/// (https://sabbath-school.adventech.io/api/v2/…).
class StudyQuarterly {
  final String id;
  final String title;
  final String description;
  final String humanDate;
  final String cover;
  final String colorPrimary;

  const StudyQuarterly({
    required this.id,
    required this.title,
    required this.description,
    required this.humanDate,
    required this.cover,
    required this.colorPrimary,
  });

  factory StudyQuarterly.fromJson(Map<String, dynamic> json) {
    return StudyQuarterly(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      humanDate: json['human_date'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      colorPrimary: json['color_primary'] as String? ?? '#D97706',
    );
  }
}

class StudyLesson {
  final String id;
  final String title;
  final String startDate;
  final String endDate;
  final String cover;

  /// API path like `en/quarterlies/2026-03/lessons/01`.
  final String path;

  const StudyLesson({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.cover,
    required this.path,
  });

  factory StudyLesson.fromJson(Map<String, dynamic> json) {
    return StudyLesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }
}

class StudyDay {
  final String id;
  final String title;
  final String date;

  /// API path like `en/quarterlies/2026-03/lessons/01/days/01/read`.
  final String readPath;

  const StudyDay({
    required this.id,
    required this.title,
    required this.date,
    required this.readPath,
  });

  factory StudyDay.fromJson(Map<String, dynamic> json) {
    return StudyDay(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      readPath: json['read_path'] as String? ?? '',
    );
  }
}

class StudyDayRead {
  final String title;
  final String date;
  final String bible;

  /// Sanitized HTML content of the day's reading.
  final String content;

  const StudyDayRead({
    required this.title,
    required this.date,
    required this.bible,
    required this.content,
  });

  factory StudyDayRead.fromJson(Map<String, dynamic> json) {
    return StudyDayRead(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      bible: json['bible'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
