import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/hymnal_providers.dart';
import '../screens/collections_screen.dart';
import '../theme/app_theme.dart';

const String _kApplicationId = 'com.example.sifahymns';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SvgPicture.asset('assets/branding/logo.svg', width: 52, height: 52, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 14),
                  const Text('SDA Pack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmarks_rounded),
              title: const Text('My Collections'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CollectionsScreen()),
                );
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
            const Spacer(),
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
              'Developed by Orin Digital Tz © ${DateTime.now().year}',
              style: TextStyle(fontSize: 12, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
