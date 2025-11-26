import 'package:flutter/widgets.dart';
import 'pin_grid.dart';

/// A widget that displays a grid with pinnable items.
///
/// Items can be pinned to the top of the grid with special layouts for 1-2 pinned items.
/// Uses generic type [K] for item keys to uniquely identify each item.
class PinGridView<K> extends StatefulWidget {
  /// List of unique keys for each item
  final List<K> items;

  /// Builder function for each grid item
  /// Parameters:
  /// - context: BuildContext
  /// - itemKey: The unique key for this item
  /// - index: The current index in the ordered list
  /// - isPinned: Whether this item is currently pinned
  /// - onTogglePin: Callback to toggle the pin state
  final Widget Function(
    BuildContext context,
    K itemKey,
    int index,
    bool isPinned,
    VoidCallback onTogglePin,
  ) itemBuilder;

  /// Base dimension for grid cells (width/height)
  final double dimension;

  /// Spacing between items horizontally
  final double crossAxisSpacing;

  /// Spacing between items vertically
  final double mainAxisSpacing;

  /// Maximum number of items that can be pinned (1 or 2)
  final int maxPinnedItems;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Aspect ratio for grid cells (width/height)
  final double childAspectRatio;

  const PinGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.dimension = 100.0,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
    this.maxPinnedItems = 2,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
  }) : assert(
         maxPinnedItems >= 0 && maxPinnedItems <= 2,
         'maxPinnedItems must be between 0 and 2',
       );

  @override
  State<PinGridView<K>> createState() => _PinGridViewState<K>();
}

class _PinGridViewState<K> extends State<PinGridView<K>> {
  /// Set of item keys that are currently pinned
  final Set<K> _pinnedKeys = {};

  @override
  void didUpdateWidget(PinGridView<K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clean up pinned keys that are no longer in the items list
    if (oldWidget.items != widget.items) {
      final itemSet = widget.items.toSet();
      _pinnedKeys.removeWhere((key) => !itemSet.contains(key));
    }
  }

  /// Toggles the pinned state of an item with the given key
  void _togglePinned(K itemKey) {
    if (!widget.items.contains(itemKey)) {
      return; // Item not in list, do nothing
    }
    setState(() {
      if (_pinnedKeys.contains(itemKey)) {
        _pinnedKeys.remove(itemKey);
      } else {
        // Only add if we haven't reached the maximum
        if (_pinnedKeys.length < widget.maxPinnedItems) {
          _pinnedKeys.add(itemKey);
        }
      }
    });
  }

  /// Checks if an item is currently pinned
  bool _isPinned(K itemKey) => _pinnedKeys.contains(itemKey);

  /// Returns a list of item keys sorted with pinned items first
  List<K> get _orderedItems {
    // Clean up invalid pinned keys
    final itemSet = widget.items.toSet();
    _pinnedKeys.removeWhere((key) => !itemSet.contains(key));
    
    final List<K> unpinned = [];
    for (final item in widget.items) {
      if (!_pinnedKeys.contains(item)) {
        unpinned.add(item);
      }
    }
    
    // Keep pinned items in the order they appear in the original list
    final List<K> sortedPinned = [];
    for (final item in widget.items) {
      if (_pinnedKeys.contains(item)) {
        sortedPinned.add(item);
      }
    }
    
    return [...sortedPinned, ...unpinned];
  }

  @override
  Widget build(BuildContext context) {
    final orderedItems = _orderedItems;

    return GridView.builder(
      itemCount: orderedItems.length,
      itemBuilder: (context, index) {
        final K itemKey = orderedItems[index];
        final bool isPinned = _isPinned(itemKey);

        return KeyedSubtree(
          key: ValueKey<K>(itemKey),
          child: widget.itemBuilder(
            context,
            itemKey,
            index,
            isPinned,
            () => _togglePinned(itemKey),
          ),
        );
      },
      gridDelegate: PinGridDelegate(
        dimension: widget.dimension,
        pinnedCount: _pinnedKeys.length,
        totalItemCount: orderedItems.length,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
    );
  }
}
