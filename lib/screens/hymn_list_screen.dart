import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hymn.dart';
import '../models/hymnal.dart';
import '../providers/hymnal_providers.dart';
import '../widgets/fast_scrollbar.dart';
import '../widgets/hymn_list_tile.dart';
import '../widgets/search_field.dart';
import 'hymn_detail_screen.dart';

const double _kItemExtent = 68;

/// Shows either a full hymnal's hymns (search-as-you-type against the
/// hymnal, [hymnal] set) or an explicit, already-resolved list of hymns
/// (e.g. a collection's contents, [fixedHymns] set).
class HymnListScreen extends ConsumerStatefulWidget {
  final Hymnal? hymnal;
  final List<Hymn>? fixedHymns;
  final String? title;

  const HymnListScreen({super.key, this.hymnal, this.fixedHymns, this.title})
      : assert(hymnal != null || fixedHymns != null);

  @override
  ConsumerState<HymnListScreen> createState() => _HymnListScreenState();
}

class _HymnListScreenState extends ConsumerState<HymnListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _localQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? widget.hymnal?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchField(
              onChanged: (value) {
                if (widget.hymnal != null) {
                  ref.read(searchQueryProvider.notifier).state = value;
                } else {
                  setState(() => _localQuery = value.trim().toLowerCase());
                }
              },
            ),
          ),
          Expanded(
            child: widget.hymnal != null
                ? ref.watch(filteredHymnsProvider(widget.hymnal!.id)).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Failed to load hymns: $err')),
                      data: (hymns) => _HymnListBody(hymns: hymns, scrollController: _scrollController),
                    )
                : _HymnListBody(
                    hymns: _filterFixed(widget.fixedHymns!, _localQuery),
                    scrollController: _scrollController,
                  ),
          ),
        ],
      ),
    );
  }

  List<Hymn> _filterFixed(List<Hymn> hymns, String query) {
    if (query.isEmpty) return hymns;
    return hymns.where((h) {
      return h.numberLabel.toLowerCase() == query ||
          h.title.toLowerCase().contains(query) ||
          h.searchableLyrics.contains(query);
    }).toList();
  }
}

class _HymnListBody extends StatelessWidget {
  final List<Hymn> hymns;
  final ScrollController scrollController;

  const _HymnListBody({required this.hymns, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      return const Center(child: Text('No hymns found'));
    }

    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemExtent: _kItemExtent,
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            return HymnListTile(
              hymn: hymn,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HymnDetailScreen(hymnalId: hymn.hymnalId, numberLabel: hymn.numberLabel),
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 2,
          top: 0,
          bottom: 0,
          child: FastScrollbar(
            controller: scrollController,
            itemCount: hymns.length,
            itemExtent: _kItemExtent,
            labelBuilder: (index) => hymns[index].numberLabel,
          ),
        ),
      ],
    );
  }
}
