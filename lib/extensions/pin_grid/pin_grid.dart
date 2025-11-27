import 'package:flutter/material.dart';

class PinGrid extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const PinGrid({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 10.0,
    this.crossAxisSpacing = 10.0,
    this.childAspectRatio = 1.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<PinGrid> createState() => _PinGridState();
}

class _PinGridState extends State<PinGrid> {
  late List<int> _itemIndices;
  bool _hasPinnedItem = false;

  @override
  void initState() {
    super.initState();
    _itemIndices = List.generate(widget.itemCount, (index) => index);
  }

  @override
  void didUpdateWidget(PinGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _itemIndices = List.generate(widget.itemCount, (index) => index);
      _hasPinnedItem = false;
    }
  }

  void _pinItem(int index) {
    setState(() {
      if (_hasPinnedItem && index == 0) {
        _hasPinnedItem = false;
      } else {
        final itemIndex = _itemIndices.removeAt(index);
        _itemIndices.insert(0, itemIndex);
        _hasPinnedItem = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = widget.padding.resolve(Directionality.of(context));

    return CustomScrollView(
      slivers: [
        if (_hasPinnedItem && _itemIndices.isNotEmpty)
          SliverPadding(
            padding: padding.copyWith(bottom: widget.mainAxisSpacing),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => _pinItem(0),
                child: AspectRatio(
                  aspectRatio: widget.childAspectRatio,
                  child: widget.itemBuilder(context, _itemIndices[0]),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: _hasPinnedItem ? padding.copyWith(top: 0) : padding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
              childAspectRatio: widget.childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final actualIndex = _hasPinnedItem ? index + 1 : index;
                if (actualIndex >= _itemIndices.length) return null;

                return GestureDetector(
                  onTap: () => _pinItem(actualIndex),
                  child: widget.itemBuilder(context, _itemIndices[actualIndex]),
                );
              },
              childCount: _hasPinnedItem
                  ? _itemIndices.length - 1
                  : _itemIndices.length,
            ),
          ),
        ),
      ],
    );
  }
}
