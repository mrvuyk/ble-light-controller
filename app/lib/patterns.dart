import 'package:flutter/material.dart';

import 'bledom_protocol.dart';

/// One selectable pattern. Either a plain static color (staticColor set,
/// effectCode null) or an animated effect (effectCode set).
class LightPattern {
  final String name;
  final int? effectCode;
  final Color? staticColor;

  const LightPattern(this.name, {this.effectCode, this.staticColor});
}

class PatternGroup {
  final String name;
  final List<LightPattern> patterns;

  const PatternGroup(this.name, this.patterns);
}

/// Mirrors the "Pattern group" / "Pattern" structure shown in the Elkotrol
/// app for this chipset. The Static group's colors are just presets you can
/// customize freely — the RGB sliders on the control screen do the same
/// thing. The Jump/Cross fade/Blink codes come from a reverse-engineered,
/// tested-on-hardware protocol implementation for this exact chip family.
const List<PatternGroup> kPatternGroups = [
  PatternGroup('Static', [
    LightPattern('Static Red', staticColor: Color(0xFFFF0000)),
    LightPattern('Static Green', staticColor: Color(0xFF00FF00)),
    LightPattern('Static Blue', staticColor: Color(0xFF0000FF)),
    LightPattern('Static Yellow', staticColor: Color(0xFFFFFF00)),
    LightPattern('Static Cyan', staticColor: Color(0xFF00FFFF)),
    LightPattern('Static Magenta', staticColor: Color(0xFFFF00FF)),
    LightPattern('Static White', staticColor: Color(0xFFFFFFFF)),
    LightPattern('Static Orange', staticColor: Color(0xFFFFA500)),
    LightPattern('Static Purple', staticColor: Color(0xFF800080)),
  ]),
  PatternGroup('Jump', [
    LightPattern('Red Green Blue Jump', effectCode: BledomEffects.jumpRedGreenBlue),
    LightPattern('Seven Color Jump', effectCode: BledomEffects.jumpSevenColor),
  ]),
  PatternGroup('Cross fade', [
    LightPattern('Red Cross Fade', effectCode: BledomEffects.crossFadeRed),
    LightPattern('Green Cross Fade', effectCode: BledomEffects.crossFadeGreen),
    LightPattern('Blue Cross Fade', effectCode: BledomEffects.crossFadeBlue),
    LightPattern('Yellow Cross Fade', effectCode: BledomEffects.crossFadeYellow),
    LightPattern('Cyan Cross Fade', effectCode: BledomEffects.crossFadeCyan),
    LightPattern('Magenta Cross Fade', effectCode: BledomEffects.crossFadeMagenta),
    LightPattern('White Cross Fade', effectCode: BledomEffects.crossFadeWhite),
    LightPattern('Red Green Cross Fade', effectCode: BledomEffects.crossFadeRedGreen),
    LightPattern('Red Blue Cross Fade', effectCode: BledomEffects.crossFadeRedBlue),
    LightPattern('Green Blue Cross Fade', effectCode: BledomEffects.crossFadeGreenBlue),
    LightPattern('Red Green Blue Cross Fade', effectCode: BledomEffects.crossFadeRedGreenBlue),
    LightPattern('Seven Color Cross Fade', effectCode: BledomEffects.crossFadeSevenColor),
  ]),
  PatternGroup('Blink', [
    LightPattern('Red Blink', effectCode: BledomEffects.blinkRed),
    LightPattern('Green Blink', effectCode: BledomEffects.blinkGreen),
    LightPattern('Blue Blink', effectCode: BledomEffects.blinkBlue),
    LightPattern('Yellow Blink', effectCode: BledomEffects.blinkYellow),
    LightPattern('Cyan Blink', effectCode: BledomEffects.blinkCyan),
    LightPattern('Magenta Blink', effectCode: BledomEffects.blinkMagenta),
    LightPattern('White Blink', effectCode: BledomEffects.blinkWhite),
    LightPattern('Seven Color Blink', effectCode: BledomEffects.blinkSevenColor),
  ]),
];
