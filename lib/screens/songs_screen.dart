import 'package:flutter/material.dart';

import '../models/hymnal.dart';
import '../widgets/app_side_drawer.dart';
import 'hymn_list_screen.dart';

const _kSwatches = [
  Color(0xFF4B3F72),
  Color(0xFF7A4B3F),
  Color(0xFF3F5A72),
  Color(0xFF6B7A3F),
];

const _kSubtitles = {
  'en': 'Seventh-day Adventist Hymnal in English',
  'sw': 'Nyimbo za Waadventista kwa Kiswahili',
};

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Songs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24))),
      drawer: const AppSideDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: hymnalRegistry.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hymnal = hymnalRegistry[index];
          return _HymnalCard(hymnal: hymnal, color: _kSwatches[index % _kSwatches.length]);
        },
      ),
    );
  }
}

class _HymnalCard extends StatelessWidget {
  final Hymnal hymnal;
  final Color color;

  const _HymnalCard({required this.hymnal, required this.color});

  Future<void> _handleTap(BuildContext context) async {
    if (!hymnal.available) {
      await showModalBottomSheet(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.schedule_rounded, size: 40),
              SizedBox(height: 12),
              Text('Inakuja hivi karibuni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Coming soon', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => HymnListScreen(hymnal: hymnal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hymnal.displayName,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _kSubtitles[hymnal.id] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hymnal.available ? Icons.chevron_right_rounded : Icons.lock_clock_rounded,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
