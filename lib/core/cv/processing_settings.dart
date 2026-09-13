import 'package:freezed_annotation/freezed_annotation.dart';
part 'processing_settings.freezed.dart';
part 'processing_settings.g.dart';

enum ProcessingMode { original, grayscale, highContrast, outline, sketch }

@freezed
abstract class ProcessingSettings with _$ProcessingSettings {
  const factory ProcessingSettings({
    @Default(ProcessingMode.original) ProcessingMode mode,
    @Default(0) double brightness,
    @Default(1) double contrast,
    @Default(0.5) double details,
    @Default(1) double edgeStrength,
    @Default(0) double smoothing,
    @Default(1) double lineWidth,
    @Default(0) int quarterTurns,
    @Default(false) bool mirror,
    @Default(0) double cropLeft,
    @Default(0) double cropTop,
    @Default(1) double cropRight,
    @Default(1) double cropBottom,
  }) = _ProcessingSettings;
  factory ProcessingSettings.fromJson(Map<String, dynamic> json) =>
      _$ProcessingSettingsFromJson(json);
}
