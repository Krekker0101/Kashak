import 'package:flutter/material.dart';
import '../domain/trace_settings.dart';

class GridPainter extends CustomPainter {
  const GridPainter(this.settings);
  final GridSettings settings;
  @override
  void paint(Canvas canvas, Size size) {
    if (settings.divisions < 2) {
      return;
    }
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: settings.opacity.clamp(0, 1))
      ..strokeWidth = settings.thickness;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: settings.opacity * 0.5)
      ..strokeWidth = settings.thickness + 1;
    for (var i = 1; i < settings.divisions; i++) {
      final x = size.width * i / settings.divisions,
          y = size.height * i / settings.divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), shadow);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), shadow);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.settings != settings;
}
