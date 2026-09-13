import 'package:flutter/material.dart';
import '../../../core/cv/processing_settings.dart';
import '../../../shared/widgets/value_slider.dart';

class PreparationControls extends StatelessWidget {
  const PreparationControls({
    super.key,
    required this.settings,
    required this.onChanged,
  });
  final ProcessingSettings settings;
  final ValueChanged<ProcessingSettings> onChanged;
  static const labels = [
    'Original',
    'Grayscale',
    'High Contrast',
    'Outline',
    'Sketch',
  ];
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: ProcessingMode.values
              .map(
                (mode) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[mode.index]),
                    selected: mode == settings.mode,
                    onSelected: (_) => onChanged(settings.copyWith(mode: mode)),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      ValueSlider(
        label: 'Brightness',
        value: settings.brightness,
        min: -0.9,
        max: 1,
        onChanged: (v) => onChanged(settings.copyWith(brightness: v)),
      ),
      ValueSlider(
        label: 'Contrast',
        value: settings.contrast,
        min: 0.2,
        max: 3,
        onChanged: (v) => onChanged(settings.copyWith(contrast: v)),
      ),
      ValueSlider(
        label: 'Smoothing',
        value: settings.smoothing,
        onChanged: (v) => onChanged(settings.copyWith(smoothing: v)),
      ),
      if (settings.mode == ProcessingMode.outline ||
          settings.mode == ProcessingMode.sketch) ...[
        ValueSlider(
          label: 'Details',
          value: settings.details,
          onChanged: (v) => onChanged(settings.copyWith(details: v)),
        ),
        ValueSlider(
          label: 'Edge strength',
          value: settings.edgeStrength,
          min: 0.1,
          max: 3,
          onChanged: (v) => onChanged(settings.copyWith(edgeStrength: v)),
        ),
        ValueSlider(
          label: 'Line width',
          value: settings.lineWidth,
          min: 1,
          max: 4,
          divisions: 3,
          onChanged: (v) => onChanged(settings.copyWith(lineWidth: v)),
        ),
      ],
    ],
  );
}
