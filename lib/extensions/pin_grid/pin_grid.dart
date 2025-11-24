import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A custom grid delegate that arranges items based on pinned status.
///
/// Supports special layouts for 0, 1, or 2 pinned items at the beginning of the grid.
class PinGridDelegate extends SliverGridDelegate {
  PinGridDelegate({
    required this.dimension,
    required this.pinnedCount,
    required this.totalItemCount,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
  }) : assert(dimension > 0);
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  /// The base desired height/width for a single grid cell.
  final double dimension;

  /// The number of currently pinned items (0, 1, or 2).
  final int pinnedCount;

  /// The total count of all items (pinned and unpinned).
  final int totalItemCount;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    // Determine how many square cells can fit across the cross-axis.
    int crossAxisCount = (constraints.crossAxisExtent / dimension).floor();
    if (crossAxisCount < 1) {
      crossAxisCount = 1; // Always fit at least one regardless.
    }
    // Adjust the actual cell dimension to perfectly fit the available cross-axis extent.
    final double actualDimension = constraints.crossAxisExtent / crossAxisCount;

    return PinGridLayout(
      crossAxisCount: crossAxisCount,
      dimension: actualDimension,
      pinnedCount: pinnedCount,
      totalItemCount: totalItemCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  @override
  bool shouldRelayout(PinGridDelegate oldDelegate) {
    // Relayout if any of the key properties change.
    return dimension != oldDelegate.dimension ||
        pinnedCount != oldDelegate.pinnedCount ||
        totalItemCount != oldDelegate.totalItemCount;
  }
}

/// Defines the geometry for each child in the custom grid layout.
class PinGridLayout extends SliverGridLayout {
  const PinGridLayout({
    required this.crossAxisCount,
    required this.dimension,
    required this.pinnedCount,
    required this.totalItemCount,
    this.crossAxisSpacing = 0,
    this.mainAxisSpacing = 0,
  }) : assert(crossAxisCount > 0),
       assert(dimension > 0),
       assert(pinnedCount >= 0),
       assert(totalItemCount >= 0);

  final int crossAxisCount;
  final double dimension;
  final int pinnedCount;
  final int totalItemCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  /// Calculates the total height occupied by the pinned section of the grid.
  double _getPinnedSectionHeight() {
    if (pinnedCount == 0) return 0;
    if (pinnedCount == 1) {
      return 2 * dimension +
          mainAxisSpacing; // One large pinned item (double height) + spacing after
    }
    // For 2 pinned items:
    // If crossAxisCount >= 2, they share the first row (one row height).
    // If crossAxisCount == 1, they occupy two distinct rows (two row heights).
    if (pinnedCount == 2) {
      return (crossAxisCount >= 2)
          ? (dimension + mainAxisSpacing)
          : (2 * dimension + 2 * mainAxisSpacing);
    }
    return 0; // Should not be reached with maxPinnedItems = 2.
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (index < pinnedCount) {
      // This is a pinned item (logical index refers to its position in the sorted list)
      if (pinnedCount == 1 && index == 0) {
        // Case 1: Only one item is pinned. It's large and takes the full width and double height.
        return SliverGridGeometry(
          scrollOffset: 0,
          crossAxisOffset: 0,
          mainAxisExtent: 2 * dimension,
          crossAxisExtent:
              crossAxisCount * dimension +
              (crossAxisCount - 1) * crossAxisSpacing,
        );
      } else if (pinnedCount == 2) {
        // Case 2: Two items are pinned. They take normal sizes in the first row(s).
        if (index == 0) {
          // First pinned item
          final int firstItemCells = (crossAxisCount >= 2)
              ? (crossAxisCount / 2).floor()
              : 1;
          final double firstItemSpacing = (crossAxisCount >= 2)
              ? (firstItemCells - 1) * crossAxisSpacing
              : 0;
          return SliverGridGeometry(
            scrollOffset: 0,
            crossAxisOffset: 0,
            mainAxisExtent: dimension,
            crossAxisExtent: (crossAxisCount >= 2)
                ? firstItemCells * dimension +
                      firstItemSpacing // Half width if enough space
                : dimension, // Full width if only one column
          );
        } else if (index == 1) {
          // Second pinned item
          final int firstItemCells = (crossAxisCount >= 2)
              ? (crossAxisCount / 2).floor()
              : 1;
          final int secondItemCells = (crossAxisCount >= 2)
              ? (crossAxisCount - firstItemCells)
              : 1;
          final double secondItemSpacing = (crossAxisCount >= 2)
              ? (secondItemCells - 1) * crossAxisSpacing
              : 0;
          return SliverGridGeometry(
            scrollOffset: (crossAxisCount >= 2)
                ? 0
                : (dimension +
                      mainAxisSpacing), // Same row if space, else next row
            crossAxisOffset: (crossAxisCount >= 2)
                ? (firstItemCells * dimension +
                      firstItemCells *
                          crossAxisSpacing) // Starts after first item + spacing
                : 0, // Starts at column 0 if on next row
            mainAxisExtent: dimension,
            crossAxisExtent: (crossAxisCount >= 2)
                ? (secondItemCells * dimension +
                      secondItemSpacing) // Fills remaining width
                : dimension, // Full width if only one column
          );
        }
      }
    }

    // Unpinned items: arranged in a regular grid after the pinned section.
    final double pinnedAreaHeight = _getPinnedSectionHeight();
    final int relativeIndex =
        index - pinnedCount; // Index relative to the start of unpinned items
    final int row = relativeIndex ~/ crossAxisCount;
    final int col = relativeIndex % crossAxisCount;

    return SliverGridGeometry(
      scrollOffset: pinnedAreaHeight + row * (dimension + mainAxisSpacing),
      crossAxisOffset: col * (dimension + crossAxisSpacing),
      mainAxisExtent: dimension,
      crossAxisExtent: dimension,
    );
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount == 0 || dimension == 0) {
      return 0;
    }

    final double pinnedHeight = _getPinnedSectionHeight();
    final int unpinnedCount = math.max(0, childCount - pinnedCount);

    if (unpinnedCount == 0) {
      return pinnedHeight; // Only pinned items, no scrolling beyond them.
    }

    // Calculate rows needed for unpinned items.
    final int unpinnedRows =
        (unpinnedCount + crossAxisCount - 1) ~/ crossAxisCount;
    final double unpinnedHeight =
        unpinnedRows * dimension +
        (unpinnedRows > 0 ? (unpinnedRows - 1) * mainAxisSpacing : 0);

    return pinnedHeight + unpinnedHeight;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (totalItemCount == 0) return 0; // No children.

    final double pinnedAreaHeight = _getPinnedSectionHeight();

    if (scrollOffset < pinnedAreaHeight) {
      // Scroll position is within the pinned section.
      if (pinnedCount == 0) return 0; // No pinned items, first item is 0.
      if (pinnedCount == 1) return 0; // Single pinned large item
      if (pinnedCount == 2) {
        // If 2 items pinned: if crossAxisCount == 1, they are stacked.
        // If scrollOffset is past the first item's height, the second is the min visible.
        if (crossAxisCount == 1 &&
            scrollOffset >= (dimension + mainAxisSpacing)) {
          return 1;
        }
        return 0; // Otherwise, the first pinned item is the min visible.
      }
      return 0; // Default for other cases (though we cap pinned items at 2).
    }

    // Scroll position is in the unpinned section.
    final double relativeScrollOffset = scrollOffset - pinnedAreaHeight;
    // Calculate which row in the unpinned section the scrollOffset corresponds to.
    final int relativeRow =
        (relativeScrollOffset / (dimension + mainAxisSpacing)).floor();
    final int minIndex = pinnedCount + relativeRow * crossAxisCount;

    // Ensure the returned index is within the valid range of total items.
    return math.min(minIndex, totalItemCount - 1);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (totalItemCount == 0) return -1; // No children.

    final double pinnedAreaHeight = _getPinnedSectionHeight();
    final int lastIndex = totalItemCount - 1;

    // Approximate the bottom of the visible viewport.
    // Using `dimension` as a minimum height to consider for visibility.
    final double viewportBottom = scrollOffset + dimension;

    // If the viewport bottom is still within or near the pinned area.
    if (viewportBottom <= pinnedAreaHeight) {
      if (pinnedCount == 0) return -1; // No pinned items.
      if (pinnedCount == 1) {
        return math.min(0, lastIndex);
      } // Only one pinned item.
      if (pinnedCount == 2) {
        // If two pinned items:
        // If crossAxisCount == 1 and viewport bottom is before the second pinned item.
        if (crossAxisCount == 1 &&
            viewportBottom <= (dimension + mainAxisSpacing)) {
          return math.min(0, lastIndex);
        }
        return math.min(
          1,
          lastIndex,
        ); // Otherwise, the second pinned item might be visible.
      }
      return math.min(
        pinnedCount - 1,
        lastIndex,
      ); // Fallback for more general pinned counts.
    }

    // If the viewport bottom extends into the unpinned section.
    final double relativeScrollOffset = viewportBottom - pinnedAreaHeight;
    // Determine the highest row (in the unpinned section) that intersects the viewport.
    final int relativeRow =
        (relativeScrollOffset / (dimension + mainAxisSpacing)).ceil() - 1;
    // Calculate the maximum logical index within that row.
    final int maxIndexInRow =
        pinnedCount + (relativeRow + 1) * crossAxisCount - 1;

    // Ensure the returned index is within the valid range of total items.
    return math.min(maxIndexInRow, lastIndex);
  }
}

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
    required this.itemCount,
    required this.itemBuilder,
    this.dimension = 100.0,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
    this.maxPinnedItems = 2,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
  }) : assert(maxPinnedItems >= 0 && maxPinnedItems <= 2,
            'maxPinnedItems must be between 0 and 2');

  @override
  State<PinGridView> createState() => _PinGridViewState();
}

class _PinGridViewState extends State<PinGridView> {
  /// Set of original indices that are currently pinned
  final Set<int> _pinnedIndices = {};

  /// Toggles the pinned state of an item at the given original index
  void _togglePinned(int originalIndex) {
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

        return widget.itemBuilder(
          context,
          originalIndex,
          isPinned,
          () => _togglePinned(originalIndex),
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
