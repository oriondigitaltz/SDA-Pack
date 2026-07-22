import 'package:flutter/material.dart';

import '../screens/search_screen.dart';

/// Search action for the top header, shown on every screen now that
/// the bottom navigation bar has been removed.
class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search_rounded),
      tooltip: 'Search',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      ),
    );
  }
}
