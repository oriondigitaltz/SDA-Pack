import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/study_guide_repository.dart';
import '../models/study_guide.dart';

final studyGuideRepositoryProvider = Provider<StudyGuideRepository>((ref) {
  throw UnimplementedError('Overridden in main() after Hive init');
});

/// Study guide language: `sw` (Kiswahili) or `en` (English).
final studyGuideLanguageProvider = StateProvider<String>((ref) => 'sw');

final studyQuarterliesProvider = FutureProvider<List<StudyQuarterly>>((ref) {
  final lang = ref.watch(studyGuideLanguageProvider);
  return ref.watch(studyGuideRepositoryProvider).quarterlies(lang);
});

final studyLessonsProvider =
    FutureProvider.family<List<StudyLesson>, String>((ref, quarterlyId) {
  final lang = ref.watch(studyGuideLanguageProvider);
  return ref.watch(studyGuideRepositoryProvider).lessons(lang, quarterlyId);
});

final studyDaysProvider = FutureProvider.family<List<StudyDay>, String>((ref, lessonPath) {
  return ref.watch(studyGuideRepositoryProvider).days(lessonPath);
});

final studyDayReadProvider =
    FutureProvider.family<StudyDayRead, String>((ref, readPath) {
  return ref.watch(studyGuideRepositoryProvider).dayRead(readPath);
});
