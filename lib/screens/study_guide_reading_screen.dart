import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../models/study_guide.dart';
import '../providers/hymnal_providers.dart';
import '../providers/study_guide_providers.dart';
import '../theme/app_theme.dart';

class StudyGuideReadingScreen extends ConsumerStatefulWidget {
  final StudyLesson lesson;

  const StudyGuideReadingScreen({super.key, required this.lesson});

  @override
  ConsumerState<StudyGuideReadingScreen> createState() =>
      _StudyGuideReadingScreenState();
}

class _StudyGuideReadingScreenState extends ConsumerState<StudyGuideReadingScreen> {
  int _dayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(studyDaysProvider(widget.lesson.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: daysAsync.when(
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
                  onPressed: () => ref.invalidate(studyDaysProvider(widget.lesson.path)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (days) {
          if (days.isEmpty) {
            return const Center(child: Text('No readings in this lesson'));
          }
          final index = _dayIndex.clamp(0, days.length - 1);
          final day = days[index];

          return Column(
            children: [
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: days.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ChoiceChip(
                    label: Text('Day ${i + 1}'),
                    selected: i == index,
                    selectedColor: AppColors.orange,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == index
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    onSelected: (_) => setState(() => _dayIndex = i),
                  ),
                ),
              ),
              Expanded(child: _DayReading(day: day)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      if (index > 0)
                        TextButton.icon(
                          onPressed: () => setState(() => _dayIndex = index - 1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Previous',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      const Spacer(),
                      if (index < days.length - 1)
                        TextButton.icon(
                          onPressed: () => setState(() => _dayIndex = index + 1),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.chevron_right_rounded),
                          label: const Text('Next',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayReading extends ConsumerWidget {
  final StudyDay day;

  const _DayReading({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readAsync = ref.watch(studyDayReadProvider(day.readPath));
    final fontScale = ref.watch(fontScaleProvider);
    final softColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return readAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            '$err'.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ),
      data: (read) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        children: [
          Text(
            read.title,
            style: TextStyle(
                fontSize: 21 * fontScale, fontWeight: FontWeight.w800, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            read.date,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: softColor),
          ),
          const SizedBox(height: 14),
          HtmlWidget(
            read.content,
            textStyle: TextStyle(fontSize: 15.5 * fontScale, height: 1.65),
            customStylesBuilder: (element) {
              if (element.localName == 'blockquote') {
                return {
                  'margin': '12px 0',
                  'padding': '10px 14px',
                  'background-color': isDark ? '#33291B' : '#F5E9D4',
                  'border-radius': '10px',
                };
              }
              if (element.classes.contains('verse')) {
                return {
                  'color': '#D97706',
                  'font-weight': '700',
                  'text-decoration': 'none',
                };
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
