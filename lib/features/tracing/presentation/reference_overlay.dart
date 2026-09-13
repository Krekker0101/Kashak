import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/trace_settings.dart';
import 'grid_painter.dart';

class ReferenceOverlay extends StatelessWidget {
  const ReferenceOverlay({
    super.key,
    required this.path,
    required this.reference,
    required this.viewport,
    required this.settings,
    required this.visibility,
  });
  final String path;
  final Size reference, viewport;
  final TraceSettings settings;
  final Animation<double> visibility;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ClipRect(
      child: SizedBox.expand(
        child: Stack(
          children: [
            FadeTransition(
              opacity: visibility,
              child: Opacity(
                opacity: settings.opacity,
                child: Transform(
                  transform: settings.transform.matrix(viewport, reference),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: reference.width,
                    maxWidth: reference.width,
                    minHeight: reference.height,
                    maxHeight: reference.height,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: reference.width,
                        height: reference.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(path),
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                              errorBuilder: (_, error, stack) => const Center(
                                child: Text(
                                  'Image could not be loaded',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            if (settings.grid.referenceBound)
                              CustomPaint(painter: GridPainter(settings.grid)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!settings.grid.referenceBound)
              Positioned.fill(
                child: CustomPaint(painter: GridPainter(settings.grid)),
              ),
          ],
        ),
      ),
    ),
  );
}
