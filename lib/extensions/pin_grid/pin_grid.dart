import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// A grid delegate that creates a custom layout with pinned items.
///
/// This delegate supports pinning 0, 1, or 2 items at the top of the grid:
/// - 0 pinned: Regular grid layout
/// - 1 pinned: Full-width item with 2x height at the top
/// - 2 pinned: Two items side-by-side (or stacked on narrow screens) at the top
///
/// Remaining items are arranged in a regular grid below the pinned section.
class PinGridDelegate extends SliverGridDelegate {
  /// Creates a pin grid delegate.
  ///
  /// The [dimension] must be positive and represents the base size for grid cells.
  /// [pinnedCount] should be 0, 1, or 2.
  const PinGridDelegate({
    required this.dimension,
    required this.pinnedCount,
    required this.totalItemCount,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
  })  : assert(dimension > 0, 'Dimension must be positive'),
        assert(pinnedCount >= 0 && pinnedCount <= 2,
            'Pinned count must be between 0 and 2'),
        assert(totalItemCount >= 0, 'Total item count cannot be negative');

  /// The spacing between items on the cross axis.
  final double crossAxisSpacing;

  /// The spacing between items on the main axis.
  final double mainAxisSpacing;

  /// The base size for a single grid cell (both width and height).
  final double dimension;

  /// The number of items pinned at the top (0, 1, or 2).
  final int pinnedCount;

  /// The total number of items in the grid.
  final int totalItemCount;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final crossAxisCount =
        math.max(1, (constraints.crossAxisExtent / dimension).floor());
    
    // Calculate the actual dimension accounting for spacing
    // Total width = crossAxisCount * dimension + (crossAxisCount - 1) * spacing
    // Therefore: dimension = (totalWidth - (crossAxisCount - 1) * spacing) / crossAxisCount
    final totalSpacing = (crossAxisCount - 1) * crossAxisSpacing;
    final adjustedDimension = 
        (constraints.crossAxisExtent - totalSpacing) / crossAxisCount;

    return PinGridLayout(
      crossAxisCount: crossAxisCount,
      dimension: adjustedDimension,
      pinnedCount: pinnedCount,
      totalItemCount: totalItemCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  @override
  bool shouldRelayout(covariant PinGridDelegate oldDelegate) {
    return dimension != oldDelegate.dimension ||
        pinnedCount != oldDelegate.pinnedCount ||
        totalItemCount != oldDelegate.totalItemCount ||
        crossAxisSpacing != oldDelegate.crossAxisSpacing ||
        mainAxisSpacing != oldDelegate.mainAxisSpacing;
  }
}

/// Layout implementation for the pin grid.
///
/// Handles the positioning and sizing of pinned and unpinned items.
class PinGridLayout extends SliverGridLayout {
  /// Creates a pin grid layout.
  const PinGridLayout({
    required this.crossAxisCount,
    required this.dimension,
    required this.pinnedCount,
    required this.totalItemCount,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
  })  : assert(crossAxisCount > 0, 'Cross axis count must be positive'),
        assert(dimension > 0, 'Dimension must be positive'),
        assert(pinnedCount >= 0, 'Pinned count cannot be negative'),
        assert(totalItemCount >= 0, 'Total item count cannot be negative');

  /// The number of cells that fit across the cross axis.
  final int crossAxisCount;

  /// The size of a single grid cell.
  final double dimension;

  /// The number of pinned items.
  final int pinnedCount;

  /// The total number of items.
  final int totalItemCount;

  /// The spacing between items on the cross axis.
  final double crossAxisSpacing;

  /// The spacing between items on the main axis.
  final double mainAxisSpacing;

  /// Calculates the height of the pinned items section.
  double get _pinnedSectionHeight {
    switch (pinnedCount) {
      case 0:
        return 0.0;
      case 1:
        // One large item: 2x height + spacing
        return 2 * dimension + mainAxisSpacing;
      case 2:
        // Two items side-by-side (if space) or stacked
        if (crossAxisCount >= 2) {
          return dimension + mainAxisSpacing;
        } else {
          return 2 * dimension + 2 * mainAxisSpacing;
        }
      default:
        return 0.0;
    }
  }

  /// Gets the geometry for a pinned item at the given index.
  SliverGridGeometry? _getPinnedItemGeometry(int index) {
    if (index >= pinnedCount) return null;

    if (pinnedCount == 1 && index == 0) {
      // Single pinned item: full width, double height
      final totalWidth = crossAxisCount * dimension +
          (crossAxisCount - 1) * crossAxisSpacing;
      
      return SliverGridGeometry(
        scrollOffset: 0.0,
        crossAxisOffset: 0.0,
        mainAxisExtent: 2 * dimension,
        crossAxisExtent: totalWidth,
      );
    }

    if (pinnedCount == 2) {
      final hasSpaceForTwoColumns = crossAxisCount >= 2;

      if (hasSpaceForTwoColumns) {
        // Distribute cells between two items
        final firstCellCount = crossAxisCount ~/ 2;
        final secondCellCount = crossAxisCount - firstCellCount;
        
        // Calculate the actual width each item should occupy
        // Total width = crossAxisCount * dimension + (crossAxisCount - 1) * spacing
        // We need: firstWidth + spacing + secondWidth = totalWidth
        final firstItemWidth = firstCellCount * dimension + 
            (firstCellCount - 1) * crossAxisSpacing;
        final secondItemWidth = secondCellCount * dimension + 
            (secondCellCount - 1) * crossAxisSpacing;

        if (index == 0) {
          // First pinned item
          return SliverGridGeometry(
            scrollOffset: 0.0,
            crossAxisOffset: 0.0,
            mainAxisExtent: dimension,
            crossAxisExtent: firstItemWidth,
          );
        } else {
          // Second pinned item - offset by first item width + one spacing
          return SliverGridGeometry(
            scrollOffset: 0.0,
            crossAxisOffset: firstItemWidth + crossAxisSpacing,
            mainAxisExtent: dimension,
            crossAxisExtent: secondItemWidth,
          );
        }
      } else {
        // Single column layout - stack items vertically
        if (index == 0) {
          return SliverGridGeometry(
            scrollOffset: 0.0,
            crossAxisOffset: 0.0,
            mainAxisExtent: dimension,
            crossAxisExtent: dimension,
          );
        } else {
          return SliverGridGeometry(
            scrollOffset: dimension + mainAxisSpacing,
            crossAxisOffset: 0.0,
            mainAxisExtent: dimension,
            crossAxisExtent: dimension,
          );
        }
      }
    }

    return null;
  }

  /// Gets the geometry for an unpinned item at the given index.
  SliverGridGeometry _getUnpinnedItemGeometry(int index) {
    final relativeIndex = index - pinnedCount;
    final row = relativeIndex ~/ crossAxisCount;
    final col = relativeIndex % crossAxisCount;

    return SliverGridGeometry(
      scrollOffset:
          _pinnedSectionHeight + row * (dimension + mainAxisSpacing),
      crossAxisOffset: col * (dimension + crossAxisSpacing),
      mainAxisExtent: dimension,
      crossAxisExtent: dimension,
    );
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    assert(index >= 0 && index < totalItemCount, 'Index out of bounds');

    return _getPinnedItemGeometry(index) ?? _getUnpinnedItemGeometry(index);
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount == 0) return 0.0;

    final unpinnedCount = math.max(0, childCount - pinnedCount);
    if (unpinnedCount == 0) return _pinnedSectionHeight;

    final unpinnedRows = (unpinnedCount + crossAxisCount - 1) ~/ crossAxisCount;
    final unpinnedHeight = unpinnedRows * dimension +
        math.max(0, unpinnedRows - 1) * mainAxisSpacing;

    return _pinnedSectionHeight + unpinnedHeight;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (totalItemCount == 0) return 0;

    // Within pinned section
    if (scrollOffset < _pinnedSectionHeight) {
      if (pinnedCount <= 1) return 0;

      // Two pinned items, single column, check if scrolled past first
      if (crossAxisCount == 1 &&
          scrollOffset >= dimension + mainAxisSpacing) {
        return 1;
      }
      return 0;
    }

    // Within unpinned section
    final relativeOffset = scrollOffset - _pinnedSectionHeight;
    final row = (relativeOffset / (dimension + mainAxisSpacing)).floor();
    final minIndex = pinnedCount + row * crossAxisCount;

    return math.min(minIndex, totalItemCount - 1);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (totalItemCount == 0) return -1;

    final lastIndex = totalItemCount - 1;
    final viewportBottom = scrollOffset + dimension;

    // Within pinned section
    if (viewportBottom <= _pinnedSectionHeight) {
      if (pinnedCount == 0) return -1;
      if (pinnedCount == 1) return math.min(0, lastIndex);

      // Two pinned items
      if (crossAxisCount == 1 &&
          viewportBottom <= dimension + mainAxisSpacing) {
        return math.min(0, lastIndex);
      }
      return math.min(1, lastIndex);
    }

    // Within unpinned section
    final relativeOffset = viewportBottom - _pinnedSectionHeight;
    final row =
        math.max(0, (relativeOffset / (dimension + mainAxisSpacing)).ceil() - 1);
    final maxIndex = pinnedCount + (row + 1) * crossAxisCount - 1;

    return math.min(maxIndex, lastIndex);
  }
}
