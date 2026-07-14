import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/content_providers.dart';
import 'home_screen.dart' show RecentDevotionCard;

/// Every devotion the app has pulled from the online feed, newest first.
class PastStudiesScreen extends ConsumerStatefulWidget {
  const PastStudiesScreen({super.key});

  @override
  ConsumerState<PastStudiesScreen> createState() => _PastStudiesScreenState();
}

class _PastStudiesScreenState extends ConsumerState<PastStudiesScreen> {
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(pastStudiesProvider);
    final favorites = ref.watch(devotionFavoritesProvider);
    final studies = _favoritesOnly
        ? [for (final d in all) if (favorites.contains(d.date)) d]
        : all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Studies',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Favorites'),
                  avatar: Icon(
                    _favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 16,
                  ),
                  selected: _favoritesOnly,
                  onSelected: (value) => setState(() => _favoritesOnly = value),
                ),
                const Spacer(),
                Text(
                  '${studies.length} ${studies.length == 1 ? 'study' : 'studies'}',
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
          Expanded(
            child: studies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _favoritesOnly
                            ? 'No favorite studies yet.\nTap the heart on any devotion to save it here.'
                            : 'No past studies yet.\nDevotions are saved here automatically once the app fetches them online.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: studies.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        RecentDevotionCard(devotion: studies[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
