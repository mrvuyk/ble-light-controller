import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'bledom_protocol.dart';

/// GATT identifiers for ELK-BLEDOM-compatible strips. Most units use FFF3
/// as the write characteristic; some older/variant firmware uses FFE1
/// instead, so we accept either one found under the FFF0 service.
final Guid serviceUuid = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
final Guid writeCharPrimary = Guid('0000fff3-0000-1000-8000-00805f9b34fb');
final Guid writeCharFallback = Guid('0000ffe1-0000-1000-8000-00805f9b34fb');

class BleLightController {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  bool _effectActive = false;

  bool get isConnected => _device != null && _writeChar != null;

  Stream<List<ScanResult>> scan({Duration timeout = const Duration(seconds: 6)}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<void> connect(BluetoothDevice device) async {
    await device.connect(timeout: const Duration(seconds: 10));
    final services = await device.discoverServices();

    for (final service in services) {
      for (final c in service.characteristics) {
        if (c.uuid == writeCharPrimary || c.uuid == writeCharFallback) {
          _writeChar = c;
        }
      }
    }

    _device = device;

    if (_writeChar == null) {
      await device.disconnect();
      _device = null;
      throw Exception(
        'No FFF3/FFE1 write characteristic found — this device may use a '
        'different protocol than the ELK-BLEDOM family.',
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } finally {
      _device = null;
      _writeChar = null;
    }
  }

  Future<void> _send(List<int> bytes) async {
    final c = _writeChar;
    if (c == null) throw Exception('Not connected to a light.');
    await c.write(bytes, withoutResponse: c.properties.writeWithoutResponse);
  }

  Future<void> powerOn() => _send(BledomProtocol.powerOn());
  Future<void> powerOff() => _send(BledomProtocol.powerOff());

  Future<void> setBrightness(int percent) => _send(BledomProtocol.setBrightness(percent));

  /// Sets a solid RGB color. Automatically exits effect mode first if one
  /// was active, since the strip otherwise ignores the new color.
  Future<void> setColor(int r, int g, int b) async {
    if (_effectActive) {
      await _send(BledomProtocol.disableEffect());
      _effectActive = false;
    }
    await _send(BledomProtocol.setColor(r, g, b));
  }

  /// Sets white color temperature (0 = coolest, 100 = warmest).
  Future<void> setColorTemp(int warmPercent) async {
    if (_effectActive) {
      await _send(BledomProtocol.disableEffect());
      _effectActive = false;
    }
    await _send(BledomProtocol.setColorTempPercent(warmPercent));
  }

  /// Starts a named effect/pattern (see BledomEffects for codes).
  Future<void> setEffect(int effectCode) async {
    await _send(BledomProtocol.setEffect(effectCode));
    _effectActive = true;
  }

  /// Sets how fast the currently running effect animates (0-100).
  Future<void> setEffectSpeed(int percent) => _send(BledomProtocol.setEffectSpeed(percent));
}
