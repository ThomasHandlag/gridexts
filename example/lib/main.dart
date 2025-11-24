import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gridexts/extensions/pin_grid/pin_grid.dart';
import 'package:provider/provider.dart';

void main() => runApp(const GridViewExampleApp());

/// The main application widget for the custom grid view example.
class GridViewExampleApp extends StatelessWidget {
  const GridViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider<PinGridData>(
        create: (BuildContext context) =>
            PinGridData(totalItems: 30), // Manage 30 items
        builder: (BuildContext context, Widget? child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Custom Grid Layout')),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 8.0,
                child: Consumer<PinGridData>(
                  builder: (BuildContext context, PinGridData gridData, Widget? child) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      gridDelegate: PinGridDelegate(
                        dimension: 220.0, // Base dimension for grid cells
                        pinnedCount: gridData.pinnedCount,
                        totalItemCount: gridData.itemCount,
                      ),
                      itemCount: gridData
                          .itemCount, // Total number of items to display
                      itemBuilder: (BuildContext context, int logicalIndex) {
                        // Map the logical index (position in the displayed grid)
                        // to the original index (for data content and pinning).
                        final int originalIndex =
                            gridData.orderedOriginalIndices[logicalIndex];
                        final math.Random random = math.Random(originalIndex);
                        final bool isItemPinned = gridData.isPinned(
                          originalIndex,
                        );

                        return GridTile(
                          header: GridTileBar(
                            backgroundColor: Colors.black45,
                            title: Text(
                              'Item $originalIndex',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isItemPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: isItemPinned
                                    ? Colors.yellow
                                    : Colors.white,
                              ),
                              onPressed: () {
                                gridData.togglePinned(originalIndex);
                              },
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(12.0),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              gradient: const RadialGradient(
                                colors: <Color>[
                                  Color(0x0F88EEFF),
                                  Color(0x2F0099BB),
                                ],
                              ),
                            ),
                            child: FlutterLogo(
                              style:
                                  FlutterLogoStyle.values[random.nextInt(
                                    FlutterLogoStyle.values.length,
                                  )],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PinGridData extends ChangeNotifier {
  final int _totalItems;
  final Set<int> _pinnedIndices = <int>{};
  static const int maxPinnedItems =
      2; // Maximum number of items that can be pinned for special layout behavior.

  /// Initializes [PinGridData] with a total number of items.
  ///
  /// [totalItems] must be a non-negative integer.
  PinGridData({required int totalItems})
    : assert(totalItems >= 0),
      _totalItems = totalItems;

  /// The total number of items in the grid.
  int get itemCount => _totalItems;

  /// Checks if an item with the given [originalIndex] is currently pinned.
  bool isPinned(int originalIndex) => _pinnedIndices.contains(originalIndex);

  /// Toggles the pinned state of an item.
  ///
  /// If the item is already pinned, it will be unpinned.
  /// If the item is not pinned and the maximum number of pinned items has not been reached,
  /// it will be pinned. Otherwise, it will not be pinned.
  void togglePinned(int originalIndex) {
    if (originalIndex < 0 || originalIndex >= _totalItems) {
      return; // Invalid index
    }
    if (_pinnedIndices.contains(originalIndex)) {
      _pinnedIndices.remove(originalIndex);
    } else {
      if (_pinnedIndices.length < maxPinnedItems) {
        _pinnedIndices.add(originalIndex);
      }
      // If maxPinnedItems is reached, no action is taken to pin new items.
    }
    notifyListeners();
  }

  /// The current number of pinned items.
  int get pinnedCount => _pinnedIndices.length;

  /// Returns a list of original item indices, with pinned items appearing first,
  /// followed by unpinned items. Pinned items are sorted by their original index.
  /// Unpinned items maintain their original relative order.
  List<int> get orderedOriginalIndices {
    final List<int> unpinned = <int>[];
    for (int i = 0; i < _totalItems; i++) {
      if (!_pinnedIndices.contains(i)) {
        unpinned.add(i);
      }
    }
    final List<int> sortedPinned = _pinnedIndices.toList()..sort();
    return <int>[...sortedPinned, ...unpinned];
  }
}