import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scetch/core/camera/camera_session.dart';
import 'package:scetch/features/projects/domain/project.dart';
import 'package:scetch/features/tracing/presentation/trace_controller.dart';
import 'package:scetch/features/tracing/presentation/trace_tools.dart';
import 'support/memory_project_repository.dart';

void main() {
  testWidgets('single tap cannot unlock; long press restores controls', (
    tester,
  ) async {
    final now = DateTime.utc(2026);
    final trace = TraceController(
      Project(
        id: 'test',
        name: 'Drawing',
        createdAt: now,
        updatedAt: now,
        originalImage: 'original',
        processedImage: 'processed',
        imageWidth: 100,
        imageHeight: 100,
      ),
      MemoryProjectRepository(),
    );
    final camera = CameraSession();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: trace,
            builder: (context, _) => TraceTools(
              trace: trace,
              camera: camera,
              blinkSpeed: 0,
              onBlinkSpeed: (_) {},
              onExit: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Lock reference'));
    await tester.pump();
    expect(trace.settings.locked, isTrue);
    expect(find.byTooltip('Grid'), findsNothing);
    await tester.tap(find.text('Hold to unlock'));
    await tester.pump();
    expect(trace.settings.locked, isTrue);
    await tester.longPress(find.text('Hold to unlock'));
    await tester.pump();
    expect(trace.settings.locked, isFalse);
    expect(find.byTooltip('Grid'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    trace.dispose();
    await camera.close();
    await tester.pump(const Duration(seconds: 1));
  });
}
