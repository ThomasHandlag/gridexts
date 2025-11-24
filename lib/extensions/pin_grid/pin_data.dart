part of 'pin_grid.dart';
// DATA_MODEL
/// Manages the state of grid items, including which ones are pinned.
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