import 'package:permission_handler/permission_handler.dart';
import '../errors/app_failure.dart';

abstract final class CameraPermission {
  static Future<void> request() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      return;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw const AppFailure(
        FailureKind.permissionPermanent,
        'Camera permission required. Enable camera access in Settings.',
      );
    }
    throw const AppFailure(
      FailureKind.permission,
      'Camera permission required. Allow access to start tracing.',
    );
  }

  static Future<bool> openSettings() => openAppSettings();
}
