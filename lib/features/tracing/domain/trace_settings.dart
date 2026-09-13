import 'package:freezed_annotation/freezed_annotation.dart';
import 'trace_transform.dart';
part 'trace_settings.freezed.dart';
part 'trace_settings.g.dart';

@freezed
abstract class GridSettings with _$GridSettings {
  const factory GridSettings({
    @Default(0) int divisions,
    @Default(false) bool referenceBound,
    @Default(0.4) double opacity,
    @Default(1) double thickness,
  }) = _GridSettings;
  factory GridSettings.fromJson(Map<String, dynamic> json) =>
      _$GridSettingsFromJson(json);
}

@freezed
abstract class TraceSettings with _$TraceSettings {
  const TraceSettings._();
  const factory TraceSettings({
    @Default(TraceTransform()) TraceTransform transform,
    @Default(0.5) double opacity,
    @Default(false) bool locked,
    @Default(GridSettings()) GridSettings grid,
  }) = _TraceSettings;
  factory TraceSettings.fromJson(Map<String, dynamic> json) =>
      _$TraceSettingsFromJson(json);

  TraceSettings setOpacity(double value) =>
      copyWith(opacity: value.clamp(0, 1).toDouble());
  TraceSettings setTransform(TraceTransform value) =>
      locked ? this : copyWith(transform: value);
}
