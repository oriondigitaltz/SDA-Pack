import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/study_guide.dart';
import '../providers/study_guide_providers.dart';
import '../theme/app_theme.dart';
import 'study_guide_lessons_screen.dart';

/// Sabbath School quarterly study guides in Kiswahili and English.
class StudyGuidesScreen extends ConsumerWidget {
  const StudyGuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(studyGuideLanguageProvider);
    final quarterliesAsync = ref.watch(studyQuarterliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Guides',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {lang},
              onSelectionChanged: (selection) =>
                  ref.read(studyGuideLanguageProvider.notifier).state = selection.first,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.orange,
                selectedForegroundColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: quarterliesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorRetry(
                message: '$err',
                onRetry: () => ref.invalidate(studyQuarterliesProvider),
              ),
              data: (quarterlies) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: quarterlies.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _QuarterlyCard(quarterly: quarterlies[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuarterlyCard extends StatelessWidget {
  final StudyQuarterly quarterly;

  const _QuarterlyCard({required this.quarterly});

  @override
  Widget build(BuildContext context) {
    final softColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudyGuideLessonsScreen(quarterly: quarterly),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 100,
                  child: quarterly.cover.isEmpty
                      ? Container(color: AppColors.orangeSoft)
                      : Image.network(
                          quarterly.cover,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            color: AppColors.orangeSoft,
                            child: const Icon(Icons.auto_stories_rounded,
                                color: AppColors.orange),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quarterly.humanDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quarterly.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quarterly.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: softColor),
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
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.orange),
            const SizedBox(height: 12),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
