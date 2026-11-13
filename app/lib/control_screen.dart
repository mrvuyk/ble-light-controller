import 'dart:async';

import 'package:flutter/material.dart';

import 'ble_controller.dart';
import 'patterns.dart';

class ControlScreen extends StatefulWidget {
  final BleLightController controller;
  final String deviceName;

  const ControlScreen({
    super.key,
    required this.controller,
    required this.deviceName,
  });

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _on = true;
  double _r = 255, _g = 120, _b = 0;
  double _brightness = 100;
  double _speed = 50;

  PatternGroup _selectedGroup = kPatternGroups.first;
  late LightPattern _selectedPattern = _selectedGroup.patterns.first;

  Color get _current => Color.fromARGB(255, _r.toInt(), _g.toInt(), _b.toInt());

  // Two-color blink. The strip has no built-in "blink between any two
  // colors" mode, so the app does it: a timer alternates two solid colors.
  double _c1r = 255, _c1g = 0, _c1b = 0;
  double _c2r = 0, _c2g = 0, _c2b = 255;
  double _blinkMs = 500;
  Timer? _blinkTimer;
  bool _blinkShowFirst = true;
  bool _blinkSending = false;

  bool get _blinking => _blinkTimer != null;

  Future<void> _pushColor() {
    _stopBlink();
    return widget.controller.setColor(_r.toInt(), _g.toInt(), _b.toInt());
  }

  void _startBlink() {
    _blinkTimer?.cancel();
    _blinkShowFirst = true;
    setState(() {
      _blinkTimer = Timer.periodic(
        Duration(milliseconds: _blinkMs.round()),
        (_) => _blinkTick(),
      );
    });
    _blinkTick();
  }

  void _stopBlink() {
    final t = _blinkTimer;
    if (t == null) return;
    t.cancel();
    if (mounted) {
      setState(() => _blinkTimer = null);
    } else {
      _blinkTimer = null;
    }
  }

  Future<void> _blinkTick() async {
    // Skip a beat rather than queue up writes if the last one is still going.
    if (_blinkSending) return;
    _blinkSending = true;
    final first = _blinkShowFirst;
    _blinkShowFirst = !first;
    try {
      if (first) {
        await widget.controller.setColor(_c1r.toInt(), _c1g.toInt(), _c1b.toInt());
      } else {
        await widget.controller.setColor(_c2r.toInt(), _c2g.toInt(), _c2b.toInt());
      }
    } catch (e) {
      _stopBlink();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Blink stopped: $e')));
      }
    } finally {
      _blinkSending = false;
    }
  }

  Future<void> _applySelectedPattern() async {
    _stopBlink();
    final p = _selectedPattern;
    if (p.effectCode != null) {
      await widget.controller.setEffect(p.effectCode!);
    } else if (p.staticColor != null) {
      final c = p.staticColor!;
      setState(() {
        _r = c.red.toDouble();
        _g = c.green.toDouble();
        _b = c.blue.toDouble();
      });
      await widget.controller.setColor(c.red, c.green, c.blue);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    widget.controller.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Power', style: TextStyle(fontSize: 18)),
              Switch(
                value: _on,
                onChanged: (v) async {
                  if (!v) _stopBlink();
                  setState(() => _on = v);
                  v ? await widget.controller.powerOn() : await widget.controller.powerOff();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: _current,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(height: 16),
          _colorSlider('R', _r, Colors.red, (v) => setState(() => _r = v), onChangeEnd: _pushColor),
          _colorSlider('G', _g, Colors.green, (v) => setState(() => _g = v), onChangeEnd: _pushColor),
          _colorSlider('B', _b, Colors.blue, (v) => setState(() => _b = v), onChangeEnd: _pushColor),
          const SizedBox(height: 8),
          const Text('Brightness'),
          Slider(
            value: _brightness,
            min: 0,
            max: 100,
            label: '${_brightness.round()}%',
            onChanged: (v) => setState(() => _brightness = v),
            onChangeEnd: (v) => widget.controller.setBrightness(v.round()),
          ),
          const Divider(height: 32),
          Text('Pattern Options', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Pattern group'),
                  DropdownButton<PatternGroup>(
                    isExpanded: true,
                    value: _selectedGroup,
                    items: kPatternGroups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                        .toList(),
                    onChanged: (g) {
                      if (g == null) return;
                      setState(() {
                        _selectedGroup = g;
                        _selectedPattern = g.patterns.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Pattern'),
                  DropdownButton<LightPattern>(
                    isExpanded: true,
                    value: _selectedPattern,
                    items: _selectedGroup.patterns
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (p) {
                      if (p == null) return;
                      setState(() => _selectedPattern = p);
                    },
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _applySelectedPattern,
                      child: const Text('Set Pattern'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Speed (for the active pattern)'),
                  Slider(
                    value: _speed,
                    min: 0,
                    max: 100,
                    label: '${_speed.round()}%',
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => widget.controller.setEffectSpeed(_speed.round()),
                      child: const Text('Set speed'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Text('Two-Color Blink', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rgbPicker(
                    title: 'Color 1',
                    r: _c1r,
                    g: _c1g,
                    b: _c1b,
                    onChanged: (r, g, b) => setState(() {
                      _c1r = r;
                      _c1g = g;
                      _c1b = b;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _rgbPicker(
                    title: 'Color 2',
                    r: _c2r,
                    g: _c2g,
                    b: _c2b,
                    onChanged: (r, g, b) => setState(() {
                      _c2r = r;
                      _c2g = g;
                      _c2b = b;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text('Switch every ${(_blinkMs / 1000).toStringAsFixed(2)} s'),
                  Slider(
                    value: _blinkMs,
                    min: 150,
                    max: 2000,
                    onChanged: (v) => setState(() => _blinkMs = v),
                    onChangeEnd: (_) {
                      if (_blinking) _startBlink();
                    },
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: _blinking ? _stopBlink : _startBlink,
                      child: Text(_blinking ? 'Stop blink' : 'Start blink'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rgbPicker({
    required String title,
    required double r,
    required double g,
    required double b,
    required void Function(double r, double g, double b) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            Container(
              width: 64,
              height: 28,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt()),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ],
        ),
        _colorSlider('R', r, Colors.red, (v) => onChanged(v, g, b)),
        _colorSlider('G', g, Colors.green, (v) => onChanged(r, v, b)),
        _colorSlider('B', b, Colors.blue, (v) => onChanged(r, g, v)),
      ],
    );
  }

  Widget _colorSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged, {
    VoidCallback? onChangeEnd,
  }) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd == null ? null : (_) => onChangeEnd(),
          ),
        ),
      ],
    );
  }
}
