import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bible_books_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'songs_screen.dart';

/// Selected bottom-nav tab; Home cards also drive this to jump to a tab.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = [
    HomeScreen(),
    SongsScreen(),
    BibleBooksScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(mainTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music_rounded), label: 'Songs'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Bible'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Search'),
        ],
      ),
    );
  }
}
