import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/content_providers.dart';
import '../theme/app_theme.dart';
import 'devotion_screen.dart';

const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class DevotionCalendarScreen extends ConsumerStatefulWidget {
  const DevotionCalendarScreen({super.key});

  @override
  ConsumerState<DevotionCalendarScreen> createState() => _DevotionCalendarScreenState();
}

class _DevotionCalendarScreenState extends ConsumerState<DevotionCalendarScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      final shifted = DateTime(_year, _month + delta);
      _year = shifted.year;
      _month = shifted.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Recompute marks when read progress changes.
    ref.watch(devotionProgressProvider);
    ref.watch(devotionCacheVersionProvider);
    final repo = ref.watch(devotionRepositoryProvider);
    final markedDays = repo.readDaysInMonth(_year, _month)
      ..addAll(repo.cachedDaysInMonth(_year, _month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devotion Calendar',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      ),
                      Expanded(
                        child: Text(
                          '${_kMonths[_month - 1]} $_year',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MonthGrid(
                    year: _year,
                    month: _month,
                    markedDays: markedDays,
                    onDayTap: (day) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            DevotionScreen(initialDate: DateTime(_year, _month, day)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded, size: 15, color: AppColors.orange),
              const SizedBox(width: 6),
              Text(
                'Devotion read or saved for that day',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final Set<int> markedDays;
  final ValueChanged<int> onDayTap;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.markedDays,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sunday-first column
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    final softColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.45);

    final cells = <Widget>[
      for (final label in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
        Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: softColor),
          ),
        ),
      for (var i = 0; i < firstWeekday; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          isToday: year == today.year && month == today.month && day == today.day,
          isMarked: markedDays.contains(day),
          onTap: () => onDayTap(day),
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 0.82,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isMarked;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isMarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isMarked
          ? (isDark ? AppColors.orange.withValues(alpha: 0.15) : AppColors.orangeSoft)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isToday ? Border.all(color: AppColors.orange, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isToday || isMarked ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (isMarked) ...[
                const SizedBox(height: 2),
                const Icon(Icons.menu_book_rounded, size: 12, color: AppColors.orange),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
