import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gridexts/extensions/pin_grid/pin_grid_view.dart';

void main() => runApp(const GridViewExampleApp());

/// The main application widget for the custom grid view example.
class GridViewExampleApp extends StatelessWidget {
  const GridViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pin Grid Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GridViewExamplePage(),
    );
  }
}

class GridViewExamplePage extends StatefulWidget {
  const GridViewExamplePage({super.key});

  @override
  State<GridViewExamplePage> createState() => _GridViewExamplePageState();
}

class _GridViewExamplePageState extends State<GridViewExamplePage> {
  // Generate a list of unique item IDs (keys)
  final List<String> _items = List.generate(30, (index) => 'item_$index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Grid Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _items.add('item_${_items.length}');
              });
            },
            tooltip: 'Add Item',
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              if (_items.isNotEmpty) {
                setState(() {
                  _items.removeLast();
                });
              }
            },
            tooltip: 'Remove Item',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: PinGridView<String>(
          items: _items,
          dimension: 150.0,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          maxPinnedItems: 2,
          itemBuilder: (context, itemKey, index, isPinned, onTogglePin) {
            // Extract the numeric part from the key for the random seed
            final int itemNumber = int.parse(itemKey.split('_').last);
            final math.Random random = math.Random(itemNumber);
            
            return GridTile(
              header: GridTileBar(
                backgroundColor: Colors.black45,
                title: Text(
                  'Item $itemNumber',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? Colors.amber : Colors.white,
                  ),
                  onPressed: onTogglePin,
                  tooltip: isPinned ? 'Unpin' : 'Pin',
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: RadialGradient(
                    colors: [
                      Color(0x0F88EEFF),
                      Color(0x2F0099BB),
                    ],
                  ),
                  boxShadow: isPinned
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: FlutterLogo(
                  style: FlutterLogoStyle.values[
                      random.nextInt(FlutterLogoStyle.values.length)],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}