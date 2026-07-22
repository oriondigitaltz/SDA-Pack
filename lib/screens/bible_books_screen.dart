import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible.dart';
import '../providers/hymnal_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/app_side_drawer.dart';
import '../widgets/home_button.dart';
import 'bible_chapter_screen.dart';

final bibleTestamentProvider = StateProvider<Testament>((ref) => Testament.old);

class BibleBooksScreen extends ConsumerWidget {
  const BibleBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bibleBooksProvider);
    final testament = ref.watch(bibleTestamentProvider);

    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        title: const Text('Bible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: const [AppHeaderActions()],
      ),
      drawer: const AppSideDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<Testament>(
              segments: const [
                ButtonSegment(value: Testament.old, label: Text('Old Testament')),
                ButtonSegment(value: Testament.newTestament, label: Text('New Testament')),
              ],
              selected: {testament},
              onSelectionChanged: (selection) =>
                  ref.read(bibleTestamentProvider.notifier).state = selection.first,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.orange,
                selectedForegroundColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load Bible: $err')),
              data: (books) {
                final shown = books.where((b) => b.testament == testament).toList();
                return ListView(
                  children: [for (final book in shown) _BookRow(book: book)],
                );
              },
            ),
          ),
        ],
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
