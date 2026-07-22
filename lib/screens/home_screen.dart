import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/devotion.dart';
import '../providers/content_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_side_drawer.dart';
import '../widgets/home_button.dart';
import 'beliefs_screen.dart';
import 'bible_books_screen.dart';
import 'collections_screen.dart';
import 'devotion_calendar_screen.dart';
import 'devotion_screen.dart';
import 'past_studies_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'songs_screen.dart';
import 'study_guides_screen.dart';

const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _kWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const _GreetingHeader(),
            const SizedBox(height: 20),
            const _DevotionHeroCard(),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.25,
              children: [
                _CategoryTile(
                  title: 'Bible',
                  subtitle: 'English & Kiswahili',
                  icon: Icons.book_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BibleBooksScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'Songs',
                  subtitle: 'Hymns & worship',
                  icon: Icons.music_note_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SongsScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'Devotion',
                  subtitle: 'Daily studies',
                  icon: Icons.menu_book_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const DevotionScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'Study Guide',
                  subtitle: 'Kiswahili & English',
                  icon: Icons.auto_stories_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const StudyGuidesScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'SDA Believe',
                  subtitle: '28 Fundamentals',
                  icon: Icons.church_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BeliefsScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'Favorites',
                  subtitle: 'Saved for you',
                  icon: Icons.favorite_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CollectionsScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'Calendar',
                  subtitle: 'Stay consistent',
                  icon: Icons.calendar_month_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const DevotionCalendarScreen()),
                  ),
                ),
                _CategoryTile(
                  title: 'Settings',
                  subtitle: 'Preferences',
                  icon: Icons.settings_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _RecentDevotionsSection(),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${_kWeekdays[now.weekday - 1]}, ${_kMonths[now.month - 1]} ${now.day}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _greeting,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
              ),
            ],
          ),
        ),
        Builder(
          builder: (context) => _RoundIconButton(
            icon: Icons.menu_rounded,
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: Icons.search_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      shape: CircleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _DevotionHeroCard extends ConsumerWidget {
  const _DevotionHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final devotionAsync =
        ref.watch(devotionForDateProvider(DateTime(today.year, today.month, today.day)));
    final devotion = devotionAsync.valueOrNull;
    final progress = ref.watch(devotionProgressProvider);

    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DevotionScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "TODAY'S DEVOTION",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    if (progress.streak > 0)
                      Text(
                        '🔥 ${progress.streak}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  devotion?.titleEn ?? 'Morning Devotion',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  devotion?.verseRef ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Text(
                      'Read Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.orange.withValues(alpha: 0.18)
                      : AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.orange, size: 23),
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDevotionsSection extends ConsumerWidget {
  const _RecentDevotionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentDevotionsProvider);
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Devotions',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PastStudiesScreen()),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.orange),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final devotion in recent) ...[
          RecentDevotionCard(devotion: devotion),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Card used on Home (Recent Devotions) and in Past Studies.
class RecentDevotionCard extends ConsumerWidget {
  final Devotion devotion;

  const RecentDevotionCard({super.key, required this.devotion});

  static const _chipColors = <String, Color>{
    'Love': Color(0xFFE11D48),
    'Peace': Color(0xFF059669),
    'Faith': Color(0xFF2563EB),
    'Hope': Color(0xFF7C3AED),
    'Prayer': Color(0xFF0891B2),
    'Grace': Color(0xFFDB2777),
    'Joy': Color(0xFFF59E0B),
    'Light': Color(0xFFD97706),
    'Trust': Color(0xFF4F46E5),
    'Mercy': Color(0xFF9333EA),
  };

  Color _chipColor(String category) =>
      _chipColors[category] ??
      Colors.primaries[category.hashCode.abs() % Colors.primaries.length].shade700;

  String _dateLabel(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return '${months[month - 1]} $day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(devotionFavoritesProvider);
    final dateKey = devotion.date ?? '';
    final isFavorite = favorites.contains(dateKey);
    final category = devotion.category ?? 'Devotion';
    final chipColor = _chipColor(category);
    final softColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.55);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final parts = dateKey.split('-').map(int.tryParse).toList();
          if (parts.length == 3 && !parts.contains(null)) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DevotionScreen(
                  initialDate: DateTime(parts[0]!, parts[1]!, parts[2]!),
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: chipColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _dateLabel(dateKey),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: softColor),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: dateKey.isEmpty
                        ? null
                        : () => ref.read(devotionFavoritesProvider.notifier).toggle(dateKey),
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: isFavorite ? const Color(0xFFE11D48) : softColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                devotion.titleEn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 16, color: softColor),
                  const SizedBox(width: 6),
                  Text(
                    devotion.verseRef,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: softColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
