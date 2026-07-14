import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchField({super.key, required this.onChanged, this.hintText = 'Search by number, title, or lyrics'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : AppColors.ink;
    final bg = isDark ? AppColors.darkGreenCard : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: fg.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(color: fg),
              cursorColor: fg,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: fg.withValues(alpha: 0.5), fontSize: 13.5),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
