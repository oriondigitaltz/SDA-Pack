import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Floating "go home" button shown bottom-left on every screen. Pops the
/// whole stack back to the first route instead of pushing a new Home,
/// so it never stacks duplicate screens.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'homeButton',
      mini: true,
      tooltip: 'Home',
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: const Icon(Icons.home_rounded),
    );
  }
}
