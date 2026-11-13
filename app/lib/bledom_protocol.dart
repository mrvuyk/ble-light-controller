import 'dart:typed_data';

/// Packet builder for the "ELK-BLEDOM" family of generic BLE LED strip
/// controllers — the chipset behind apps like Lotus Lantern, elkotrol,
/// duoCo Strip, Happy Lighting, and many unbranded strips/bulbs.
///
/// This is a community-reverse-engineered protocol, not an official spec.
/// Frame layout (9 bytes total):
///
///   [0] 0x7E   start byte
///   [1] 0x00   always zero on this firmware family
///   [2] CMD    command id
///   [3..6]     up to 4 parameter bytes (unused ones are 0x00)
///   [7] 0x00
///   [8] 0xEF   end byte
///
/// Power, color, brightness, and the named effect codes below all match an
/// independently reverse-engineered, tested-on-hardware implementation
/// (elk-led-controller, Rust), and line up with the pattern names shown in
/// apps like Elkotrol/Lotus Lantern for this chipset family. Still,
/// firmware revisions vary, so if a command doesn't do what's expected on
/// your unit, that's the first thing to suspect.
class BledomProtocol {
  static const int _start = 0x7E;
  static const int _end = 0xEF;

  static Uint8List _frame(int cmd, List<int> params) {
    final bytes = List<int>.filled(9, 0);
    bytes[0] = _start;
    bytes[1] = 0x00;
    bytes[2] = cmd;
    for (var i = 0; i < params.length && i < 4; i++) {
      bytes[3 + i] = params[i] & 0xFF;
    }
    bytes[8] = _end;
    return Uint8List.fromList(bytes);
  }

  static Uint8List powerOn() => _frame(0x04, [0xF0, 0x00, 0x01, 0xFF]);

  static Uint8List powerOff() => _frame(0x04, [0x00, 0x00, 0x00, 0xFF]);

  /// Effects run until told otherwise; this drops the strip back into
  /// static-color mode. Send it before setColor()/setColorTempPercent()
  /// if an effect was last active, or the strip ignores the new color.
  static Uint8List disableEffect() => _frame(0x05, [0x01, 0x00, 0x00, 0x00]);

  /// r, g, b: 0-255
  static Uint8List setColor(int r, int g, int b) =>
      _frame(0x05, [0x03, r, g, b]);

  /// warmPercent: 0-100 (0 = coolest supported, 100 = warmest supported)
  static Uint8List setColorTempPercent(int warmPercent) {
    final warm = warmPercent.clamp(0, 100);
    final cold = 100 - warm;
    return _frame(0x05, [0x02, warm, cold, 0x00]);
  }

  /// percent: 0-100
  static Uint8List setBrightness(int percent) =>
      _frame(0x01, [percent.clamp(0, 100), 0x00, 0x00, 0x00]);

  /// effectCode: one of the named codes in [BledomEffects]
  static Uint8List setEffect(int effectCode) =>
      _frame(0x03, [effectCode, 0x03, 0x00, 0x00]);

  /// percent: 0-100, how fast the active effect animates
  static Uint8List setEffectSpeed(int percent) =>
      _frame(0x02, [percent.clamp(0, 100), 0x00, 0x00, 0x00]);
}

/// Named effect codes, matching the "Pattern" names shown in apps like
/// Elkotrol/Lotus Lantern for this chipset family.
class BledomEffects {
  static const int jumpRedGreenBlue = 0x87;
  static const int jumpSevenColor = 0x88;

  static const int crossFadeRed = 0x8b;
  static const int crossFadeGreen = 0x8c;
  static const int crossFadeBlue = 0x8d;
  static const int crossFadeYellow = 0x8e;
  static const int crossFadeCyan = 0x8f;
  static const int crossFadeMagenta = 0x90;
  static const int crossFadeWhite = 0x91;
  static const int crossFadeRedGreen = 0x92;
  static const int crossFadeRedBlue = 0x93;
  static const int crossFadeGreenBlue = 0x94;
  static const int crossFadeRedGreenBlue = 0x89;
  static const int crossFadeSevenColor = 0x8a;

  static const int blinkRed = 0x96;
  static const int blinkGreen = 0x97;
  static const int blinkBlue = 0x98;
  static const int blinkYellow = 0x99;
  static const int blinkCyan = 0x9a;
  static const int blinkMagenta = 0x9b;
  static const int blinkWhite = 0x9c;
  static const int blinkSevenColor = 0x95;
}
