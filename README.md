# GridExts

A Flutter package providing custom grid layout.

## Usage

### Simple Usage with PinGridView


```dart
import 'package:flutter/material.dart';
import 'package:gridexts/extensions/pin_grid/pin_grid.dart';

class MyGridPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PinGridView(
        itemCount: 20,
        crossAxisCount: 3,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 1.0,
        maxPinnedItems: 2,
        itemBuilder: (context, originalIndex, isPinned, onTogglePin) {
          return Card(
            elevation: isPinned ? 8 : 2,
            child: InkWell(
              onTap: onTogglePin, // Toggle pin on tap
              child: Stack(
                children: [
                  Center(
                    child: Text('Item $originalIndex'),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isPinned ? Colors.amber : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```