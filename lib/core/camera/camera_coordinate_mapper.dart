import 'package:flutter/painting.dart';

/// Preview geometry uses logical pixels; plugin preview dimensions use pixels.
/// The preview widget and tap-to-focus share this exact cover rectangle.
class CameraCoordinateMapper {
  CameraCoordinateMapper({
    required this.viewport,
    required this.previewPixels,
    this.sensorOrientation = 90,
    this.deviceRotation = 0,
    this.frontFacing = false,
    this.fit = BoxFit.cover,
  }) : assert(sensorOrientation % 90 == 0),
       assert(deviceRotation % 90 == 0);
  final Size viewport;
  final Size previewPixels;
  final int sensorOrientation;
  final int deviceRotation;
  final bool frontFacing;
  final BoxFit fit;

  int get rotation =>
      (sensorOrientation +
          (frontFacing ? deviceRotation : -deviceRotation) +
          360) %
      360;
  Size get orientedPreview => rotation % 180 == 0
      ? previewPixels
      : Size(previewPixels.height, previewPixels.width);
  Rect get previewRect {
    final size = orientedPreview;
    final factor = fit == BoxFit.contain
        ? (viewport.width / size.width < viewport.height / size.height
              ? viewport.width / size.width
              : viewport.height / size.height)
        : (viewport.width / size.width > viewport.height / size.height
              ? viewport.width / size.width
              : viewport.height / size.height);
    return Rect.fromCenter(
      center: viewport.center(Offset.zero),
      width: size.width * factor,
      height: size.height * factor,
    );
  }

  /// camera plugin expects normalized coordinates in the displayed preview.
  Offset viewToPreview(Offset logicalPoint) {
    final rect = previewRect;
    return Offset(
      ((logicalPoint.dx - rect.left) / rect.width).clamp(0, 1),
      ((logicalPoint.dy - rect.top) / rect.height).clamp(0, 1),
    );
  }

  Offset physicalToPreview(Offset pixels, double devicePixelRatio) =>
      viewToPreview(pixels / devicePixelRatio);
  Offset previewToView(Offset point) => Offset(
    previewRect.left + point.dx * previewRect.width,
    previewRect.top + point.dy * previewRect.height,
  );
  Offset viewToSensor(Offset point) {
    final p = viewToPreview(point);
    final x = frontFacing ? 1 - p.dx : p.dx;
    return switch (rotation) {
      90 => Offset(p.dy, 1 - x),
      180 => Offset(1 - x, 1 - p.dy),
      270 => Offset(1 - p.dy, x),
      _ => Offset(x, p.dy),
    };
  }
}
