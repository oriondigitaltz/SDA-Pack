import 'package:flutter_test/flutter_test.dart';
import 'package:sifahymns/models/study_guide.dart';

void main() {
  test('StudyDayRead parses a real-shaped response where bible is a list', () {
    final read = StudyDayRead.fromJson({
      'id': '01',
      'date': '27/06/2026',
      'index': 'sw-2026-03-01-01',
      'title': 'Huduma ya Paulo Huko Korintho',
      'bible': [
        {
          'name': 'SUV',
          'verses': {'1Cor22': '<h2>1 Wakorintho 2:2</h2>'},
        },
      ],
      'content': '<h3>Somo la Juma Hili</h3>',
    });

    expect(read.title, 'Huduma ya Paulo Huko Korintho');
    expect(read.date, '27/06/2026');
    expect(read.content, contains('Somo'));
  });

  test('models tolerate missing optional fields', () {
    expect(StudyDayRead.fromJson({}).content, '');
    expect(StudyQuarterly.fromJson({}).title, '');
    expect(StudyLesson.fromJson({}).path, '');
    expect(StudyDay.fromJson({}).readPath, '');
  });
}
