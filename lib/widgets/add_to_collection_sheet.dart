import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/hymnal_providers.dart';

class AddToCollectionSheet extends ConsumerWidget {
  final String hymnId;

  const AddToCollectionSheet({super.key, required this.hymnId});

  static Future<void> show(BuildContext context, String hymnId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddToCollectionSheet(hymnId: hymnId),
    );
  }

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
    if (name == null || name.isEmpty) return;
    final collection = await ref.read(collectionsProvider.notifier).create(name);
    await ref.read(collectionsProvider.notifier).toggleHymn(collection.id, hymnId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Add to Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => _createCollection(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final collection in collections)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(collection.name),
                value: collection.contains(hymnId),
                onChanged: (_) => ref.read(collectionsProvider.notifier).toggleHymn(collection.id, hymnId),
              ),
          ],
        ),
      ),
    );
  }
}
