import 'package:flutter/material.dart';
import '../../../core/cv/processing_settings.dart';

/// Crop bounds are normalized in the EXIF-corrected original, before rotation.
class CropControls extends StatelessWidget {
  const CropControls({
    super.key,
    required this.settings,
    required this.onChanged,
  });
  final ProcessingSettings settings;
  final ValueChanged<ProcessingSettings> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Crop · horizontal'),
      RangeSlider(
        values: RangeValues(settings.cropLeft, settings.cropRight),
        min: 0,
        max: 1,
        divisions: 100,
        labels: RangeLabels(
          '${(settings.cropLeft * 100).round()}%',
          '${(settings.cropRight * 100).round()}%',
        ),
        onChanged: (v) {
          if (v.end - v.start >= 0.05) {
            onChanged(settings.copyWith(cropLeft: v.start, cropRight: v.end));
          }
        },
      ),
      const Text('Crop · vertical'),
      RangeSlider(
        values: RangeValues(settings.cropTop, settings.cropBottom),
        min: 0,
        max: 1,
        divisions: 100,
        labels: RangeLabels(
          '${(settings.cropTop * 100).round()}%',
          '${(settings.cropBottom * 100).round()}%',
        ),
        onChanged: (v) {
          if (v.end - v.start >= 0.05) {
            onChanged(settings.copyWith(cropTop: v.start, cropBottom: v.end));
          }
        },
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          IconButton(
            tooltip: 'Rotate 90 degrees',
            onPressed: () => onChanged(
              settings.copyWith(quarterTurns: (settings.quarterTurns + 1) % 4),
            ),
            icon: const Icon(Icons.rotate_right),
          ),
          IconButton(
            tooltip: 'Mirror',
            isSelected: settings.mirror,
            onPressed: () =>
                onChanged(settings.copyWith(mirror: !settings.mirror)),
            icon: const Icon(Icons.flip),
          ),
          TextButton(
            onPressed: () => onChanged(const ProcessingSettings()),
            child: const Text('Reset'),
          ),
        ],
      ),
    ],
  );
}
