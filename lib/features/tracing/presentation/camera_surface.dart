import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/camera/camera_coordinate_mapper.dart';
import '../../../core/camera/camera_session.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/permissions/camera_permission.dart';
import '../../../shared/widgets/failure_view.dart';

int deviceDegrees(DeviceOrientation orientation) => switch (orientation) {
  DeviceOrientation.portraitUp => 0,
  DeviceOrientation.landscapeLeft => 90,
  DeviceOrientation.portraitDown => 180,
  DeviceOrientation.landscapeRight => 270,
};

CameraCoordinateMapper mapperFor(CameraController controller, Size viewport) =>
    CameraCoordinateMapper(
      viewport: viewport,
      previewPixels: controller.value.previewSize!,
      sensorOrientation: controller.description.sensorOrientation,
      deviceRotation: deviceDegrees(controller.value.deviceOrientation),
      frontFacing:
          controller.description.lensDirection == CameraLensDirection.front,
    );

class CameraSurface extends StatelessWidget {
  const CameraSurface({super.key, required this.session});
  final CameraSession session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      if (session.failure != null) {
        final error = session.failure;
        return ColoredBox(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FailureView(error: error!, retry: session.start),
              if (error is AppFailure &&
                  error.kind == FailureKind.permissionPermanent)
                TextButton(
                  onPressed: () async {
                    if (!await CameraPermission.openSettings() &&
                        context.mounted) {
                      showFailure(context, error);
                    }
                  },
                  child: const Text('Open Settings'),
                ),
            ],
          ),
        );
      }
      final controller = session.controller;
      if (controller == null) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (context, value, _) => LayoutBuilder(
          builder: (context, constraints) {
            final mapper = mapperFor(controller, constraints.biggest);
            return ClipRect(
              child: OverflowBox(
                maxWidth: mapper.previewRect.width,
                minWidth: mapper.previewRect.width,
                maxHeight: mapper.previewRect.height,
                minHeight: mapper.previewRect.height,
                child: CameraPreview(controller),
              ),
            );
          },
        ),
      );
    },
  );
}
