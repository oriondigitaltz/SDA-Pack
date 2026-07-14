import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/app_side_drawer.dart';
import 'bible_chapter_screen.dart';

class BibleBooksScreen extends ConsumerWidget {
  const BibleBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bibleBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24))),
      drawer: const AppSideDrawer(),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load Bible: $err')),
        data: (books) {
          final oldTestament = books.where((b) => b.testament == Testament.old).toList();
          final newTestament = books.where((b) => b.testament == Testament.newTestament).toList();
          return ListView(
            children: [
              const _SectionHeader('Old Testament'),
              for (final book in oldTestament) _BookRow(book: book),
              const _SectionHeader('New Testament'),
              for (final book in newTestament) _BookRow(book: book),
            ],
          );
        },
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

class _BookRow extends StatelessWidget {
  final BibleBook book;

  const _BookRow({required this.book});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => BibleChapterScreen(book: book)),
      ),
    );
  }
}
