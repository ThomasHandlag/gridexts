import 'package:flutter/widgets.dart';
import 'pin_grid.dart';

/// A widget that displays a grid with pinnable items.
///
/// Items can be pinned to the top of the grid with special layouts for 1-2 pinned items.
class PinGridView extends StatefulWidget {
  /// Total number of items to display in the grid
  final int itemCount;

  /// Builder function for each grid item
  /// Parameters:
  /// - context: BuildContext
  /// - originalIndex: The original index of the item in the data
  /// - isPinned: Whether this item is currently pinned
  /// - onTogglePin: Callback to toggle the pin state
  final Widget Function(
    BuildContext context,
    int originalIndex,
    bool isPinned,
    VoidCallback onTogglePin,
  )
  itemBuilder;

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
    required this.itemCount,
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
  State<PinGridView> createState() => _PinGridViewState();
}

class _PinGridViewState extends State<PinGridView> {
  /// Set of original indices that are currently pinned
  final Set<int> _pinnedIndices = {};

  @override
  void didUpdateWidget(PinGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clean up invalid pinned indices when item count changes
    if (oldWidget.itemCount != widget.itemCount) {
      _pinnedIndices.removeWhere((index) => index >= widget.itemCount);
    }
  }

  /// Toggles the pinned state of an item at the given original index
  void _togglePinned(int originalIndex) {
    if (originalIndex < 0 || originalIndex >= widget.itemCount) {
      return; // Invalid index, do nothing
    }
    setState(() {
      if (_pinnedIndices.contains(originalIndex)) {
        _pinnedIndices.remove(originalIndex);
      } else {
        // Only add if we haven't reached the maximum
        if (_pinnedIndices.length < widget.maxPinnedItems) {
          _pinnedIndices.add(originalIndex);
        }
      }
    });
  }

  /// Checks if an item is currently pinned
  bool _isPinned(int originalIndex) => _pinnedIndices.contains(originalIndex);

  /// Returns a list of original indices sorted with pinned items first
  List<int> get _orderedIndices {
    // Filter out any invalid indices before building the list
    _pinnedIndices.removeWhere((index) => index >= widget.itemCount);
    
    final List<int> unpinned = [];
    for (int i = 0; i < widget.itemCount; i++) {
      if (!_pinnedIndices.contains(i)) {
        unpinned.add(i);
      }
    }
    final List<int> sortedPinned = _pinnedIndices.toList()..sort();
    return [...sortedPinned, ...unpinned];
  }

  @override
  Widget build(BuildContext context) {
    final orderedIndices = _orderedIndices;

    return GridView.builder(
      itemCount: widget.itemCount,
      itemBuilder: (context, logicalIndex) {
        // Map logical index (position in grid) to original index (data)
        final int originalIndex = orderedIndices[logicalIndex];
        final bool isPinned = _isPinned(originalIndex);

        return KeyedSubtree(
          key: ValueKey<int>(originalIndex),
          child: widget.itemBuilder(
            context,
            originalIndex,
            isPinned,
            () => _togglePinned(originalIndex),
          ),
        );
      },
      gridDelegate: PinGridDelegate(
        dimension: widget.dimension,
        pinnedCount: _pinnedIndices.length,
        totalItemCount: widget.itemCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
    );
  }
}
