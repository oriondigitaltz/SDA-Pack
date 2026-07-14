import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/belief.dart';
import '../providers/content_providers.dart';
import 'belief_detail_screen.dart';

class BeliefsScreen extends ConsumerWidget {
  const BeliefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beliefsAsync = ref.watch(beliefsProvider);
    final viewed = ref.watch(viewedBeliefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SDA Beliefs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: beliefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load beliefs: $err')),
        data: (beliefs) {
          final categories = <String, List<Belief>>{};
          for (final belief in beliefs) {
            categories.putIfAbsent(belief.category, () => []).add(belief);
          }
          final exploredCount = viewed.where((n) => n >= 1 && n <= beliefs.length).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _ProgressHeader(explored: exploredCount, total: beliefs.length),
              for (final entry in categories.entries) ...[
                _SectionHeader(entry.key),
                for (final belief in entry.value)
                  _BeliefCard(
                    belief: belief,
                    viewed: viewed.contains(belief.number),
                    onTap: () {
                      ref.read(viewedBeliefsProvider.notifier).markViewed(belief.number);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BeliefDetailScreen(beliefs: beliefs, initialNumber: belief.number),
                        ),
                      );
                    },
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int explored;
  final int total;

  const _ProgressHeader({required this.explored, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The 28 Fundamental Beliefs',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'What Seventh-day Adventists believe, grounded in Scripture. '
              'Tap a belief to explore it with its Bible references.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : explored / total,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$explored of $total explored',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _BeliefCard extends StatelessWidget {
  final Belief belief;
  final bool viewed;
  final VoidCallback onTap;

  const _BeliefCard({required this.belief, required this.viewed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: viewed ? 1 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: viewed
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                    : Text(
                        '${belief.number}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: primary),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${belief.number}. ${belief.titleEn}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      belief.summaryEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
