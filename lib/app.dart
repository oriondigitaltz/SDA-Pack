import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/hymnal_providers.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class SdaPackApp extends ConsumerWidget {
  const SdaPackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SDA Pack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
