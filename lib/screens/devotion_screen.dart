import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/devotion.dart';
import '../providers/content_providers.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/app_side_drawer.dart';
import '../widgets/home_button.dart';
import 'bible_verse_screen.dart';
import 'settings_screen.dart';

const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _kWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class DevotionScreen extends ConsumerStatefulWidget {
  /// Day to open on; defaults to today.
  final DateTime? initialDate;

  const DevotionScreen({super.key, this.initialDate});

  @override
  ConsumerState<DevotionScreen> createState() => _DevotionScreenState();
}

class _DevotionScreenState extends ConsumerState<DevotionScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year && _date.month == now.month && _date.day == now.day;
  }

  bool get _isFutureOrToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !_date.isBefore(today);
  }

  void _shiftDay(int days) => setState(() => _date = _date.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final devotionAsync = ref.watch(devotionForDateProvider(_date));
    final progress = ref.watch(devotionProgressProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: const Text('Morning Devotion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          if (progress.streak > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('🔥 ${progress.streak}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          IconButton(
            tooltip: 'Daily reminder',
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          const AppHeaderActions(),
        ],
      ),
      drawer: const AppSideDrawer(),
      body: devotionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load devotion: $err')),
        data: (devotion) => devotion == null
            ? const Center(child: Text('No devotion for this day'))
            : _DevotionBody(
                date: _date,
                devotion: devotion,
                fontScale: fontScale,
                isRead: progress.isRead(_date),
                isToday: _isToday,
                onPrev: () => _shiftDay(-1),
                onNext: _isFutureOrToday ? null : () => _shiftDay(1),
                onToggleRead: () => ref.read(devotionProgressProvider.notifier).toggleRead(_date),
              ),
      ),
    );
  }
}

class _DevotionBody extends ConsumerWidget {
  final DateTime date;
  final Devotion devotion;
  final double fontScale;
  final bool isRead;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onToggleRead;

  const _DevotionBody({
    required this.date,
    required this.devotion,
    required this.fontScale,
    required this.isRead,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onToggleRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final softColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded, size: 30)),
            Expanded(
              child: Column(
                children: [
                  Text(
                    isToday ? 'Today' : _kWeekdays[date.weekday - 1],
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: softColor),
                  ),
                  Text(
                    '${date.day} ${_kMonths[date.month - 1]} ${date.year}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded, size: 30)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          devotion.titleEn,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22 * fontScale, fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 4),
        Text(
          devotion.titleSw,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15 * fontScale, fontStyle: FontStyle.italic, color: softColor),
        ),
        const SizedBox(height: 16),
        _VerseCard(verseRef: devotion.verseRef, fontScale: fontScale),
        const SizedBox(height: 18),
        Text(
          devotion.bodyEn,
          style: TextStyle(fontSize: 16 * fontScale, height: 1.65),
        ),
        const SizedBox(height: 14),
        Text(
          devotion.bodySw,
          style: TextStyle(
            fontSize: 15.5 * fontScale,
            height: 1.65,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onToggleRead,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: isRead ? Colors.green.shade700 : null,
          ),
          icon: Icon(isRead ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
          label: Text(
            isRead ? 'Read ✓ — tap to undo' : 'Mark as read',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _VerseCard extends ConsumerWidget {
  final String verseRef;
  final double fontScale;

  const _VerseCard({required this.verseRef, required this.fontScale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(versesForRefProvider(verseRef));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final data = resolved.valueOrNull;
          if (data == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BibleVerseScreen(
                book: data.book,
                chapterNum: data.ref.chapter,
                initialVerse: data.ref.verse,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: resolved.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (err, _) => Text(verseRef, style: const TextStyle(fontWeight: FontWeight.w700)),
            data: (data) {
              if (data == null || data.verses.isEmpty) {
                return Text(verseRef, style: const TextStyle(fontWeight: FontWeight.w700));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(fontSize: 15.5 * fontScale, height: 1.55),
                      children: [
                        for (final verse in data.verses) ...[
                          if (data.verses.length > 1)
                            TextSpan(
                              text: '${verse.verseNumber} ',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ...verse.english,
                          if (verse.hasSwahili)
                            TextSpan(
                              text: '\n${verse.swahili}',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          if (verse != data.verses.last) const TextSpan(text: '\n\n'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '— ${data.ref.label}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded, size: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
