import 'package:flutter/material.dart';

import 'scan_screen.dart';

void main() {
  runApp(const BleLightApp());
}

class BleLightApp extends StatelessWidget {
  const BleLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Light Control',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const ScanScreen(),
    );
  }
}
