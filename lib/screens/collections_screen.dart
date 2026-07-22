import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hymn_repository.dart';
import '../models/collection.dart';
import '../models/hymn.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/app_header_actions.dart';
import '../widgets/app_side_drawer.dart';
import '../widgets/home_button.dart';
import 'hymn_list_screen.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(collectionsProvider.notifier).create(name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final hymnRepo = ref.watch(hymnRepositoryProvider);

    return Scaffold(
      floatingActionButton: const HomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      drawer: const AppSideDrawer(),
      appBar: AppBar(
        title: const Text('Collections', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          IconButton(
            onPressed: () => _createCollection(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
          const AppHeaderActions(),
        ],
      ),
      body: collections.isEmpty
          ? const Center(child: Text('No collections yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: collections.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final collection = collections[index];
                return _CollectionCard(
                  collection: collection,
                  onTap: () {
                    final hymns = _resolveHymns(hymnRepo, collection.hymnIds);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HymnListScreen(fixedHymns: hymns, title: collection.name),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

List<Hymn> _resolveHymns(HymnRepository hymnRepo, List<String> hymnIds) {
  final hymns = <Hymn>[];
  for (final hymnId in hymnIds) {
    final parts = hymnId.split(':');
    if (parts.length != 2) continue;
    final hymn = hymnRepo.getHymn(parts[0], parts[1]);
    if (hymn != null) hymns.add(hymn);
  }
  return hymns;
}

class _CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const _CollectionCard({required this.collection, required this.onTap});

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final softColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${collection.hymnIds.length} Hymns',
                      style: TextStyle(color: softColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                _relativeTime(collection.updatedAt),
                style: TextStyle(color: softColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
