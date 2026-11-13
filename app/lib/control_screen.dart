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

  Future<void> _pushColor() => widget.controller.setColor(_r.toInt(), _g.toInt(), _b.toInt());

  Future<void> _applySelectedPattern() async {
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
          _colorSlider('R', _r, Colors.red, (v) => setState(() => _r = v)),
          _colorSlider('G', _g, Colors.green, (v) => setState(() => _g = v)),
          _colorSlider('B', _b, Colors.blue, (v) => setState(() => _b = v)),
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
        ],
      ),
    );
  }

  Widget _colorSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
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
            onChangeEnd: (_) => _pushColor(),
          ),
        ),
      ],
    );
  }
}
