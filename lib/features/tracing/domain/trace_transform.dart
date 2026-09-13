import 'dart:math' as math;
import 'package:flutter/painting.dart'
    show Size, BoxFit, applyBoxFit, Offset, MatrixUtils;
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:freezed_annotation/freezed_annotation.dart';
part 'trace_transform.freezed.dart';
part 'trace_transform.g.dart';

/// Translation is measured in fitted reference widths/heights, never screen pixels.
@freezed
abstract class TraceTransform with _$TraceTransform {
  const TraceTransform._();
  const factory TraceTransform({
    @Default(0) double x,
    @Default(0) double y,
    @Default(1) double scale,
    @Default(0) double rotation,
    @Default(false) bool flipX,
    @Default(false) bool flipY,
  }) = _TraceTransform;
  factory TraceTransform.fromJson(Map<String, dynamic> json) =>
      _$TraceTransformFromJson(json);

  Matrix4 matrix(Size viewport, Size reference) {
    final fitted = applyBoxFit(BoxFit.contain, reference, viewport).destination;
    final factor = fitted.width / reference.width;
    return Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 + x * fitted.width,
        viewport.height / 2 + y * fitted.height,
        0,
        1,
      )
      ..rotateZ(rotation)
      ..scaleByDouble(
        factor * scale * (flipX ? -1 : 1),
        factor * scale * (flipY ? -1 : 1),
        1,
        1,
      )
      ..translateByDouble(-reference.width / 2, -reference.height / 2, 0, 1);
  }

  TraceTransform gesture({
    required Offset anchor,
    required Offset focal,
    required double gestureScale,
    required double gestureRotation,
    required Size viewport,
    required Size reference,
  }) {
    final next = copyWith(
      scale: (scale * gestureScale).clamp(0.1, 12).toDouble(),
      rotation: (rotation + gestureRotation) % (2 * math.pi),
    );
    final mapped = MatrixUtils.transformPoint(
      next.matrix(viewport, reference),
      anchor,
    );
    final fitted = applyBoxFit(BoxFit.contain, reference, viewport).destination;
    return next.copyWith(
      x: next.x + (focal.dx - mapped.dx) / fitted.width,
      y: next.y + (focal.dy - mapped.dy) / fitted.height,
    );
  }
}
