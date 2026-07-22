import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/hymnal_providers.dart';
import '../screens/beliefs_screen.dart';
import '../screens/bible_books_screen.dart';
import '../screens/collections_screen.dart';
import '../screens/devotion_calendar_screen.dart';
import '../screens/devotion_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/songs_screen.dart';
import '../screens/study_guides_screen.dart';
import '../theme/app_theme.dart';

const String _kApplicationId = 'com.example.sifahymns';

const String _kMixxNumber = '+255703540517';
const String _kAirtelNumber = '+255786540517';

class AppSideDrawer extends ConsumerWidget {
  const AppSideDrawer({super.key});

  Future<void> _rateUs(BuildContext context) async {
    final marketUri = Uri.parse('market://details?id=$_kApplicationId');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$_kApplicationId');

    final launched = await launchUrl(marketUri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!launched) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  'assets/branding/splash_logo.svg',
                  width: 220,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Bibles'),
              onTap: () => _navigate(context, const BibleBooksScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded),
              title: const Text('Devotions'),
              onTap: () => _navigate(context, const DevotionScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.library_music_rounded),
              title: const Text('Songs'),
              onTap: () => _navigate(context, const SongsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories_rounded),
              title: const Text('Study Guide'),
              onTap: () => _navigate(context, const StudyGuidesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.church_rounded),
              title: const Text('SDA Believe'),
              onTap: () => _navigate(context, const BeliefsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded),
              title: const Text('My Favorite'),
              onTap: () => _navigate(context, const CollectionsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Calendar'),
              onTap: () => _navigate(context, const DevotionCalendarScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () => _navigate(context, const SettingsScreen()),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_rounded, color: AppColors.orange),
              title: const Text('Donate'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(context: context, builder: (context) => const _DonateDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded),
              title: const Text('Rate us'),
              onTap: () => _rateUs(context),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark mode'),
              value: isDark,
              onChanged: (value) => ref.read(themeModeProvider.notifier).setDark(value),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: _DrawerFooter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonateDialog extends StatelessWidget {
  const _DonateDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Support SDA Pack'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SDA Pack is built to bless you with the Bible, hymns, and daily '
            'devotions wherever you are. If it has been a blessing to you, '
            'please prayerfully consider supporting its development and '
            'hosting costs so it can keep reaching more people. Thank you '
            'and God bless you!',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          _DonationNumberRow(label: 'Mixx by YAS', number: _kMixxNumber),
          const SizedBox(height: 10),
          _DonationNumberRow(label: 'Airtel Money', number: _kAirtelNumber),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DonationNumberRow extends StatelessWidget {
  final String label;
  final String number;

  const _DonationNumberRow({required this.label, required this.number});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Number copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(number, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6) ?? AppColors.inkSoft;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data != null
            ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : 'Version…';
        return Column(
          children: [
            Text(version, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(
              'Copyright to Orion Digital Tanzania. Developed by Innocent Metumba.',
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
