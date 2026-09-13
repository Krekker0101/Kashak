import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scetch/core/camera/camera_session.dart';
import 'package:scetch/core/errors/app_failure.dart';

const description = CameraDescription(
  name: 'test',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

class FakeCamera extends CameraController {
  FakeCamera(this.gate)
    : super(description, ResolutionPreset.high, enableAudio: false);
  final Completer<void> gate;
  int disposals = 0;
  @override
  Future<void> initialize() => gate.future;
  @override
  Future<double> getMinZoomLevel() async => 1;
  @override
  Future<double> getMaxZoomLevel() async => 4;
  @override
  Future<double> getMinExposureOffset() async => -2;
  @override
  Future<double> getMaxExposureOffset() async => 2;
  @override
  Future<void> dispose() async {
    disposals++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'route exit during initialization never publishes disposed camera',
    () async {
      final gate = Completer<void>();
      final fake = FakeCamera(gate);
      final session = CameraSession(
        requestPermission: () async {},
        discoverCameras: () async => [description],
        createController: (_) => fake,
      );
      final start = session.start();
      await Future<void>.delayed(Duration.zero);
      final closing = session.close();
      gate.complete();
      await start;
      await closing;
      expect(session.controller, isNull);
      expect(fake.disposals, 1);
    },
  );
  test('denied permission remains a recoverable typed failure', () async {
    var discovered = false;
    final session = CameraSession(
      requestPermission: () async => throw const AppFailure(
        FailureKind.permissionPermanent,
        'Camera permission required',
      ),
      discoverCameras: () async {
        discovered = true;
        return [];
      },
    );
    await session.start();
    expect(session.failure, isA<AppFailure>());
    expect(discovered, isFalse);
    await session.close();
  });
}
