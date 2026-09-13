import 'package:flutter/material.dart';

class ValueSlider extends StatelessWidget {
  const ValueSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });
  final String label;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(label),
      ),
      Slider(
        semanticFormatterCallback: (v) => '$label ${v.toStringAsFixed(2)}',
        label: value.toStringAsFixed(2),
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    ],
  );
}
