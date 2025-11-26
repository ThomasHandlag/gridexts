import 'package:flutter/widgets.dart';

import 'pin_grid.dart';

/// A widget that displays a grid with pinnable items.
///
/// Items can be pinned to the top of the grid with special layouts:
/// - 1 pinned item: Full-width with 2x height
/// - 2 pinned items: Side-by-side (or stacked on narrow screens)
///
/// Generic type [K] is used for item keys to uniquely identify each item.
/// All pinned items appear at the top, followed by unpinned items in a regular grid.
class PinGridView<K> extends StatefulWidget {
  /// Creates a pin grid view.
  ///
  /// The [items] list contains unique keys for each item to display.
  /// The [itemBuilder] creates the widget for each item.
  /// The [dimension] must be positive.
  /// The [maxPinnedItems] must be between 0 and 2.
  const PinGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.dimension = 100.0,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
    this.maxPinnedItems = 2,
  })  : assert(dimension > 0, 'Dimension must be positive'),
        assert(maxPinnedItems >= 0 && maxPinnedItems <= 2,
            'maxPinnedItems must be between 0 and 2');

  /// List of unique keys for each item in the grid.
  final List<K> items;

  /// Builder function for each grid item.
  ///
  /// Parameters:
  /// - [context]: The build context
  /// - [itemKey]: The unique key for this item
  /// - [index]: The current index in the ordered list (pinned items first)
  /// - [isPinned]: Whether this item is currently pinned
  /// - [onTogglePin]: Callback to toggle the pin state of this item
  final Widget Function(
    BuildContext context,
    K itemKey,
    int index,
    bool isPinned,
    VoidCallback onTogglePin,
  ) itemBuilder;

  /// Base dimension for grid cells (width and height).
  final double dimension;

  /// Horizontal spacing between items.
  final double crossAxisSpacing;

  /// Vertical spacing between items.
  final double mainAxisSpacing;

  /// Maximum number of items that can be pinned simultaneously (0-2).
  final int maxPinnedItems;

  @override
  State<PinGridView<K>> createState() => _PinGridViewState<K>();
}

/// State for [PinGridView] that manages pinned items.
class _PinGridViewState<K> extends State<PinGridView<K>> {
  /// Set of item keys that are currently pinned.
  final Set<K> _pinnedKeys = <K>{};

  @override
  void didUpdateWidget(covariant PinGridView<K> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clean up pinned keys that are no longer in the items list
    if (oldWidget.items != widget.items) {
      _cleanupInvalidPinnedKeys();
    }
  }

  /// Removes pinned keys that are no longer in the items list.
  void _cleanupInvalidPinnedKeys() {
    final itemSet = widget.items.toSet();
    _pinnedKeys.removeWhere((key) => !itemSet.contains(key));
  }

  /// Toggles the pinned state of an item.
  ///
  /// If the item is already pinned, it will be unpinned.
  /// If the item is not pinned and the maximum hasn't been reached, it will be pinned.
  /// Does nothing if the item is not in the items list.
  void _togglePinned(K itemKey) {
    if (!widget.items.contains(itemKey)) {
      return;
    }

    setState(() {
      if (_pinnedKeys.contains(itemKey)) {
        _pinnedKeys.remove(itemKey);
      } else if (_pinnedKeys.length < widget.maxPinnedItems) {
        _pinnedKeys.add(itemKey);
      }
      // If max reached and not already pinned, do nothing
    });
  }

  /// Returns whether an item is currently pinned.
  bool _isPinned(K itemKey) => _pinnedKeys.contains(itemKey);

  /// Returns items sorted with pinned items first, maintaining original order.
  ///
  /// Pinned items appear in the order they appear in [widget.items],
  /// followed by unpinned items in their original order.
  List<K> get _orderedItems {
    final pinnedItems = <K>[];
    final unpinnedItems = <K>[];

    for (final item in widget.items) {
      if (_pinnedKeys.contains(item)) {
        pinnedItems.add(item);
      } else {
        unpinnedItems.add(item);
      }
    }

    return [...pinnedItems, ...unpinnedItems];
  }

  @override
  Widget build(BuildContext context) {
    final orderedItems = _orderedItems;
    final pinnedCount = _pinnedKeys.length;

    return GridView.builder(
      itemCount: orderedItems.length,
      gridDelegate: PinGridDelegate(
        dimension: widget.dimension,
        pinnedCount: pinnedCount,
        totalItemCount: orderedItems.length,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemBuilder: (context, index) {
        final itemKey = orderedItems[index];
        final isPinned = _isPinned(itemKey);

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
    );
  }
}
