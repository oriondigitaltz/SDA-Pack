import 'package:flutter/material.dart';

import '../models/hymn.dart';
import '../theme/app_theme.dart';

class HymnListTile extends StatelessWidget {
  final Hymn hymn;
  final VoidCallback onTap;
  final String? subtitle;

  const HymnListTile({super.key, required this.hymn, required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final subColor = isDark ? Colors.white60 : AppColors.inkSoft;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    hymn.numberLabel,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hymn.title,
                        style: TextStyle(color: textColor, fontSize: 15.5, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(color: subColor, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
