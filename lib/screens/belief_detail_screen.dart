import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scripture_ref.dart';
import '../models/belief.dart';
import '../providers/content_providers.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/home_button.dart';
import 'bible_verse_screen.dart';

class BeliefDetailScreen extends ConsumerStatefulWidget {
  final List<Belief> beliefs;
  final int initialNumber;

  const BeliefDetailScreen({super.key, required this.beliefs, required this.initialNumber});

  @override
  ConsumerState<BeliefDetailScreen> createState() => _BeliefDetailScreenState();
}

class _BeliefDetailScreenState extends ConsumerState<BeliefDetailScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.beliefs.indexWhere((b) => b.number == widget.initialNumber).clamp(0, widget.beliefs.length - 1);
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.beliefs.length) return;
    setState(() => _index = next);
    ref.read(viewedBeliefsProvider.notifier).markViewed(widget.beliefs[next].number);
  }

  @override
  Widget build(BuildContext context) {
    final belief = widget.beliefs[_index];
    final fontScale = ref.watch(fontScaleProvider);
    final softColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.65);

    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: Text('Belief ${belief.number} of ${widget.beliefs.length}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            onPressed: () => ref.read(fontScaleProvider.notifier).decrease(),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            onPressed: () => ref.read(fontScaleProvider.notifier).increase(),
            icon: const Icon(Icons.text_increase_rounded),
          ),
          const AppHeaderActions(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Text(
            belief.category.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: softColor),
          ),
          const SizedBox(height: 6),
          Text(
            '${belief.number}. ${belief.titleEn}',
            style: TextStyle(fontSize: 23 * fontScale, fontWeight: FontWeight.w800, height: 1.25),
          ),
          Text(
            belief.titleSw,
            style: TextStyle(fontSize: 15 * fontScale, fontStyle: FontStyle.italic, color: softColor),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(belief.summaryEn,
                      style: TextStyle(fontSize: 15 * fontScale, height: 1.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    belief.summarySw,
                    style: TextStyle(
                        fontSize: 14 * fontScale, height: 1.5, fontStyle: FontStyle.italic, color: softColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(belief.bodyEn, style: TextStyle(fontSize: 15.5 * fontScale, height: 1.65)),
          const SizedBox(height: 12),
          Text(
            belief.bodySw,
            style: TextStyle(
              fontSize: 15 * fontScale,
              height: 1.65,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'BIBLE REFERENCES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: softColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reference in belief.references)
                _ReferenceChip(reference: reference),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _index > 0 ? () => _go(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _index < widget.beliefs.length - 1 ? () => _go(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferenceChip extends ConsumerWidget {
  final String reference;

  const _ReferenceChip({required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      avatar: const Icon(Icons.menu_book_rounded, size: 16),
      label: Text(reference, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      onPressed: () async {
        final parsed = ScriptureRef.parse(reference);
        if (parsed == null) return;
        final books = await ref.read(bibleBooksProvider.future);
        final book = parsed.resolveBook(books);
        if (book == null || !context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BibleVerseScreen(
              book: book,
              chapterNum: parsed.chapter,
              initialVerse: parsed.verse,
            ),
          ),
        );
      },
    );
  }
}
