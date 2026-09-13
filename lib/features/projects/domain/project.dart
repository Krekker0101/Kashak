import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/cv/processing_settings.dart';
import '../../tracing/domain/trace_settings.dart';
part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String originalImage,
    required String processedImage,
    required int imageWidth,
    required int imageHeight,
    @Default(ProcessingSettings()) ProcessingSettings processing,
    @Default(TraceSettings()) TraceSettings tracing,
  }) = _Project;
  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
