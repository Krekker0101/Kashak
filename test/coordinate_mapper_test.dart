import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scetch/core/camera/camera_coordinate_mapper.dart';

void main() {
  test('portrait cover crops landscape sensor and maps center', () {
    final mapper = CameraCoordinateMapper(
      viewport: const Size(400, 800),
      previewPixels: const Size(1920, 1080),
    );
    expect(mapper.orientedPreview, const Size(1080, 1920));
    expect(mapper.previewRect.width, closeTo(450, 0.001));
    expect(
      mapper.viewToPreview(const Offset(200, 400)),
      const Offset(0.5, 0.5),
    );
    expect(mapper.viewToPreview(Offset.zero).dx, closeTo(25 / 450, 0.0001));
  });
  test('focus uses logical pixels independent of pixel density', () {
    final mapper = CameraCoordinateMapper(
      viewport: const Size(400, 800),
      previewPixels: const Size(1920, 1080),
    );
    expect(
      mapper.physicalToPreview(const Offset(600, 1200), 3),
      mapper.viewToPreview(const Offset(200, 400)),
    );
  });
  for (final rotation in [0, 90, 180, 270]) {
    test('preview round trip for device rotation $rotation', () {
      final mapper = CameraCoordinateMapper(
        viewport: const Size(800, 400),
        previewPixels: const Size(1920, 1080),
        deviceRotation: rotation,
      );
      const point = Offset(0.3, 0.7);
      expect(
        (mapper.viewToPreview(mapper.previewToView(point)) - point).distance,
        lessThan(0.00001),
      );
    });
  }
  test('sensor rotation and front mirror are explicit', () {
    final rear = CameraCoordinateMapper(
      viewport: const Size(1080, 1920),
      previewPixels: const Size(1920, 1080),
    );
    final front = CameraCoordinateMapper(
      viewport: const Size(1080, 1920),
      previewPixels: const Size(1920, 1080),
      frontFacing: true,
    );
    expect(rear.viewToSensor(Offset.zero), const Offset(0, 1));
    expect(front.viewToSensor(Offset.zero), Offset.zero);
  });
}
