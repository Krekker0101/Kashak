import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scetch/features/tracing/domain/trace_transform.dart';
import 'package:scetch/features/tracing/domain/trace_settings.dart';

void main() {
  const image = Size(1000, 500);
  test('fit centers reference without distortion', () {
    final matrix = const TraceTransform().matrix(const Size(400, 800), image);
    expect(
      MatrixUtils.transformPoint(matrix, const Offset(500, 250)),
      const Offset(200, 400),
    );
    expect(
      MatrixUtils.transformPoint(matrix, Offset.zero),
      const Offset(0, 300),
    );
  });
  test('translation survives proportional viewport resizing', () {
    const transform = TraceTransform(
      x: 0.2,
      y: -0.3,
      scale: 1.8,
      rotation: 0.7,
      flipX: true,
    );
    const point = Offset(150, 60);
    final a = MatrixUtils.transformPoint(
      transform.matrix(const Size(400, 800), image),
      point,
    );
    final b = MatrixUtils.transformPoint(
      transform.matrix(const Size(800, 1600), image),
      point,
    );
    expect((a * 2 - b).distance, lessThan(0.00001));
  });
  test('gesture keeps touched reference point under focal point', () {
    const transform = TraceTransform(
      x: 0.2,
      y: 0.1,
      rotation: 0.5,
      flipY: true,
    );
    const viewport = Size(400, 800),
        anchor = Offset(200, 150),
        focal = Offset(90, 320);
    final next = transform.gesture(
      anchor: anchor,
      focal: focal,
      gestureScale: 1.5,
      gestureRotation: 0.2,
      viewport: viewport,
      reference: image,
    );
    expect(
      (MatrixUtils.transformPoint(next.matrix(viewport, image), anchor) - focal)
          .distance,
      lessThan(0.00001),
    );
  });
  test('lock rejects transforms and opacity is bounded', () {
    const locked = TraceSettings(locked: true);
    expect(locked.setTransform(const TraceTransform(x: 2)), locked);
    expect(locked.setOpacity(5).opacity, 1);
    expect(locked.setOpacity(-2).opacity, 0);
    expect(
      const TraceSettings()
          .setTransform(const TraceTransform(x: 2))
          .transform
          .x,
      2,
    );
  });
  test('transform JSON round trip includes both mirrors', () {
    const value = TraceTransform(
      x: 0.3,
      y: 0.4,
      scale: 2,
      rotation: 1,
      flipX: true,
      flipY: true,
    );
    expect(TraceTransform.fromJson(value.toJson()), value);
  });
}
