import 'package:flutter/material.dart';
import 'package:gridexts/gridexts.dart';

void main() => runApp(const GridViewExampleApp());

/// The main application widget for the custom grid view example.
class GridViewExampleApp extends StatelessWidget {
  const GridViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pin Grid Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PinGrid(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.all(10),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Container(
            color: Colors.primaries[index % Colors.primaries.length],
            child: Center(child: Text('Item $index')),
          );
        },
      ),
    );
  }
}
