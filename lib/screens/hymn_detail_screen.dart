import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hymn.dart';
import '../providers/hymnal_providers.dart';
import '../services/hymn_midi_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/home_button.dart';

/// Shows a hymn and lets the user swipe left/right to move through the
/// rest of the hymnal in number order.
class HymnDetailScreen extends ConsumerStatefulWidget {
  final String hymnalId;
  final String numberLabel;

  const HymnDetailScreen({super.key, required this.hymnalId, required this.numberLabel});

  @override
  ConsumerState<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends ConsumerState<HymnDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    final hymns = ref.read(hymnRepositoryProvider).getHymns(widget.hymnalId);
    final index = hymns.indexWhere((h) => h.numberLabel == widget.numberLabel);
    _currentIndex = index >= 0 ? index : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HymnMidiService.instance.stop();
    setState(() {
      _currentIndex = index;
      _playing = false;
    });
  }

  Future<void> _togglePlay(Hymn hymn) async {
    if (_playing) {
      await HymnMidiService.instance.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    try {
      await HymnMidiService.instance.play(hymn);
    } on HymnMidiUnavailableException {
      if (mounted) {
        setState(() => _playing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MIDI not available for this hymn yet')),
        );
      }
      return;
    }
    if (mounted) setState(() => _playing = false);
  }

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
  Widget build(BuildContext context) {
    final hymns = ref.watch(hymnRepositoryProvider).getHymns(widget.hymnalId);
    final fontScale = ref.watch(fontScaleProvider);

    if (hymns.isEmpty) {
      return const Scaffold(body: Center(child: Text('Hymn not found')));
    }

    final index = _currentIndex.clamp(0, hymns.length - 1);
    final hymn = hymns[index];
    final hymnId = hymn.id;
    final collections = ref.watch(collectionsProvider);
    final isFavorite = ref.watch(collectionsProvider.notifier).isFavorite(hymnId);
    final note = ref.watch(hymnNoteProvider(hymnId));
    // Rebuild when collections change so isFavorite stays fresh.
    collections;

    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: Text('HYMN ${hymn.numberLabel}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
        actions: [
          IconButton(
            onPressed: () => ref.read(collectionsProvider.notifier).toggleFavorite(hymnId),
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.redAccent : null,
            ),
          ),
          const AppHeaderActions(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () => _togglePlay(hymn),
              icon: Icon(_playing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded),
              tooltip: _playing ? 'Stop' : 'Play MIDI',
              color: AppColors.orange,
            ),
            IconButton(
              onPressed: () => AddToCollectionSheet.show(context, hymnId),
              icon: const Icon(Icons.playlist_add_rounded),
              tooltip: 'Add to collection',
            ),
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
        child: PageView.builder(
          controller: _pageController,
          itemCount: hymns.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, i) => _HymnPageBody(hymn: hymns[i], fontScale: fontScale),
        ),
      ),
    );
  }
}

class _HymnPageBody extends ConsumerWidget {
  final Hymn hymn;
  final double fontScale;

  const _HymnPageBody({required this.hymn, required this.fontScale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(hymnNoteProvider(hymn.id));

    return ListView(
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
