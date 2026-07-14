import 'package:flutter/material.dart';

/// Draggable index rail on the right edge of a fixed-item-extent list,
/// letting the user jump straight to a hymn by number.
class FastScrollbar extends StatefulWidget {
  final ScrollController controller;
  final int itemCount;
  final double itemExtent;
  final String Function(int index) labelBuilder;

  const FastScrollbar({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemExtent,
    required this.labelBuilder,
  });

  @override
  State<FastScrollbar> createState() => _FastScrollbarState();
}

class _FastScrollbarState extends State<FastScrollbar> {
  bool _dragging = false;
  String? _label;

  void _handleDrag(double dy, double height) {
    if (widget.itemCount == 0) return;
    final fraction = (dy / height).clamp(0.0, 1.0);
    final index = (fraction * (widget.itemCount - 1)).round();
    final offset = (index * widget.itemExtent).clamp(
      0.0,
      widget.controller.position.maxScrollExtent,
    );
    widget.controller.jumpTo(offset);
    setState(() => _label = widget.labelBuilder(index));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final railColor = isDark ? Colors.white24 : Colors.black26;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (details) {
            setState(() => _dragging = true);
            _handleDrag(details.localPosition.dy, constraints.maxHeight);
          },
          onVerticalDragUpdate: (details) {
            _handleDrag(details.localPosition.dy, constraints.maxHeight);
          },
          onVerticalDragEnd: (_) => setState(() => _dragging = false),
          child: SizedBox(
            width: 36,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: railColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (_dragging && _label != null)
                  Positioned(
                    right: 44,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _label!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
