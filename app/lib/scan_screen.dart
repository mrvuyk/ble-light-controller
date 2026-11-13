import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_controller.dart';
import 'control_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = BleLightController();
  final List<ScanResult> _results = [];
  StreamSubscription<List<ScanResult>>? _sub;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsThenScan();
  }

  Future<void> _requestPermissionsThenScan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _results.clear();
      _scanning = true;
    });
    _sub?.cancel();
    _sub = _controller.scan().listen((results) {
      setState(() {
        _results
          ..clear()
          ..addAll(results.where((r) => r.device.platformName.isNotEmpty));
      });
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    await _controller.stopScan();
    try {
      await _controller.connect(device);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ControlScreen(
          controller: _controller,
          deviceName: device.platformName,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Lights')),
      body: _results.isEmpty
          ? Center(
              child: Text(_scanning ? 'Scanning…' : 'No lights found. Pull refresh to retry.'),
            )
          : ListView(
              children: _results.map((r) {
                final name = r.device.platformName;
                return ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(name),
                  subtitle: Text(r.device.remoteId.str),
                  trailing: Text('${r.rssi} dBm'),
                  onTap: () => _connect(r.device),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanning ? null : _startScan,
        tooltip: 'Rescan',
        child: Icon(_scanning ? Icons.bluetooth_searching : Icons.refresh),
      ),
    );
  }
}
