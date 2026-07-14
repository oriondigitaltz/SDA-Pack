import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hymn.dart';
import '../providers/hymnal_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/add_to_collection_sheet.dart';

class HymnDetailScreen extends ConsumerWidget {
  final String hymnalId;
  final String numberLabel;

  const HymnDetailScreen({super.key, required this.hymnalId, required this.numberLabel});

  Future<void> _editNote(BuildContext context, WidgetRef ref, String hymnId) async {
    final controller = TextEditingController(text: ref.read(hymnNoteProvider(hymnId)) ?? '');
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Add a note...'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
    if (note != null) {
      await ref.read(hymnNoteProvider(hymnId).notifier).save(note);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(hymnRepositoryProvider);
    final hymn = repo.getHymn(hymnalId, numberLabel);
    final fontScale = ref.watch(fontScaleProvider);

    if (hymn == null) {
      return const Scaffold(body: Center(child: Text('Hymn not found')));
    }

    final hymnId = hymn.id;
    final collections = ref.watch(collectionsProvider);
    final isFavorite = ref.watch(collectionsProvider.notifier).isFavorite(hymnId);
    final note = ref.watch(hymnNoteProvider(hymnId));
    // Rebuild when collections change so isFavorite stays fresh.
    collections;

    return Scaffold(
      appBar: AppBar(
        title: Text('HYMN $numberLabel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
        actions: [
          IconButton(
            onPressed: () => ref.read(collectionsProvider.notifier).toggleFavorite(hymnId),
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddToCollectionSheet.show(context, hymnId),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () => _editNote(context, ref, hymnId),
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit note',
            ),
            IconButton(
              onPressed: note == null ? null : () => ref.read(hymnNoteProvider(hymnId).notifier).clear(),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear note',
            ),
            IconButton(
              onPressed: () => Share.share('${hymn.title}\n\n${hymn.blocks.map((b) => b.text).join('\n\n')}'),
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              hymn.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _FontButton(
                  icon: Icons.text_decrease_rounded,
                  onTap: () => ref.read(fontScaleProvider.notifier).decrease(),
                ),
                const SizedBox(width: 10),
                _FontButton(
                  icon: Icons.text_increase_rounded,
                  onTap: () => ref.read(fontScaleProvider.notifier).increase(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (note != null) ...[
              _NoteCard(note: note),
              const SizedBox(height: 16),
            ],
            for (final block in hymn.blocks) ...[
              _HymnBlockView(block: block, fontScale: fontScale),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(note, style: const TextStyle(fontStyle: FontStyle.italic)),
    );
  }
}

class _FontButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FontButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}

class _HymnBlockView extends StatelessWidget {
  final HymnBlock block;
  final double fontScale;

  const _HymnBlockView({required this.block, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 17 * fontScale,
      height: 1.6,
      fontStyle: block.isChorus ? FontStyle.italic : FontStyle.normal,
      fontWeight: block.isChorus ? FontWeight.w600 : FontWeight.w400,
    );

    if (block.isChorus) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(block.text, style: textStyle),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(block.text, style: textStyle),
    );
  }
}
