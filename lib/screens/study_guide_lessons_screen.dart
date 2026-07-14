import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/study_guide.dart';
import '../providers/study_guide_providers.dart';
import '../theme/app_theme.dart';
import 'study_guide_reading_screen.dart';

class StudyGuideLessonsScreen extends ConsumerWidget {
  final StudyQuarterly quarterly;

  const StudyGuideLessonsScreen({super.key, required this.quarterly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(studyLessonsProvider(quarterly.id));
    final softColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          quarterly.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.orange),
                const SizedBox(height: 12),
                Text(
                  '$err'.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(studyLessonsProvider(quarterly.id)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (lessons) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: lessons.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StudyGuideReadingScreen(lesson: lesson),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.orange.withValues(alpha: 0.18)
                              : AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${lesson.startDate} – ${lesson.endDate}',
                              style: TextStyle(fontSize: 12.5, color: softColor),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
