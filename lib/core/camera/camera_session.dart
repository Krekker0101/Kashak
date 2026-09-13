import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import '../errors/app_failure.dart';
import '../logging/app_log.dart';
import '../permissions/camera_permission.dart';

/// All native operations are serialized, including initialization and disposal.
/// Generation invalidation prevents publishing a controller after route exit.
class CameraSession extends ChangeNotifier with WidgetsBindingObserver {
  CameraSession({
    Future<void> Function()? requestPermission,
    Future<List<CameraDescription>> Function()? discoverCameras,
    CameraController Function(CameraDescription)? createController,
  }) : _requestPermission = requestPermission ?? CameraPermission.request,
       _discoverCameras = discoverCameras ?? availableCameras,
       _createController = createController ?? _defaultController {
    WidgetsBinding.instance.addObserver(this);
  }
  final Future<void> Function() _requestPermission;
  final Future<List<CameraDescription>> Function() _discoverCameras;
  final CameraController Function(CameraDescription) _createController;
  static CameraController _defaultController(CameraDescription description) =>
      CameraController(description, ResolutionPreset.high, enableAudio: false);
  CameraController? controller;
  Object? failure;
  Object? controlFailure;
  bool loading = false,
      _closed = false,
      _active = false,
      _permissionInFlight = false;
  int _generation = 0;
  Future<void> _tail = Future.value();
  double minZoom = 1,
      maxZoom = 1,
      zoom = 1,
      minExposure = 0,
      maxExposure = 0,
      exposure = 0;
  bool torch = false;

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.catchError((Object error, StackTrace stack) {
      AppLog.error('Camera operation', error, stack);
      if (!_closed) {
        failure = _mapFailure(error);
        notifyListeners();
      }
    });
    return _tail;
  }

  Object _mapFailure(Object error) {
    if (error is AppFailure) {
      return error;
    }
    if (error is CameraException && error.code.contains('Access')) {
      return AppFailure(
        error.code == 'CameraAccessDenied'
            ? FailureKind.permission
            : FailureKind.permissionPermanent,
        'Camera permission required. Check camera access in Settings.',
        error,
      );
    }
    return AppFailure(
      FailureKind.camera,
      'Camera unavailable. Close other camera apps and try again.',
      error,
    );
  }

  Future<void> start() async {
    if (_closed || _permissionInFlight) {
      return;
    }
    _active = true;
    loading = true;
    failure = null;
    notifyListeners();
    _permissionInFlight = true;
    try {
      await _requestPermission();
    } catch (error, stack) {
      AppLog.error('Camera permission', error, stack);
      if (!_closed) {
        failure = error;
        loading = false;
        notifyListeners();
      }
      return;
    } finally {
      _permissionInFlight = false;
    }
    if (_closed || !_active) {
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      await suspend();
      return;
    }
    final token = ++_generation;
    await _enqueue(() async {
      await _release();
      if (_closed || !_active || token != _generation) {
        return;
      }
      CameraController? candidate;
      try {
        final cameras = await _discoverCameras();
        if (cameras.isEmpty) {
          throw const AppFailure(
            FailureKind.camera,
            'Camera unavailable. No camera was found.',
          );
        }
        final rear = cameras.where(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        candidate = _createController(
          rear.isNotEmpty ? rear.first : cameras.first,
        );
        await candidate.initialize();
        final lowZoom = await candidate.getMinZoomLevel();
        final highZoom = await candidate.getMaxZoomLevel();
        final lowExposure = await candidate.getMinExposureOffset();
        final highExposure = await candidate.getMaxExposureOffset();
        if (_closed || !_active || token != _generation) {
          await candidate.dispose();
          return;
        }
        minZoom = lowZoom;
        maxZoom = highZoom;
        zoom = lowZoom;
        minExposure = lowExposure;
        maxExposure = highExposure;
        exposure = 0;
        torch = false;
        controller = candidate;
        failure = null;
      } catch (error) {
        if (candidate != null) {
          await candidate.dispose();
        }
        rethrow;
      } finally {
        if (!_closed && token == _generation) {
          loading = false;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _release() async {
    final previous = controller;
    controller = null;
    if (!_closed) {
      notifyListeners();
    }
    if (previous != null) {
      // Remove CameraPreview before disposing its ValueNotifier.
      await WidgetsBinding.instance.endOfFrame;
      await previous.dispose();
    }
  }

  Future<void> suspend() {
    _active = false;
    ++_generation;
    return _enqueue(_release);
  }

  Future<void> command(
    Future<void> Function(CameraController controller) action,
  ) {
    final token = _generation;
    return _enqueue(() async {
      final current = controller;
      if (_closed || !_active || token != _generation || current == null) {
        return;
      }
      try {
        await action(current);
        controlFailure = null;
      } catch (error, stack) {
        AppLog.error('Camera control', error, stack);
        controlFailure = AppFailure(
          FailureKind.camera,
          'This camera could not apply that control.',
          error,
        );
      }
      if (!_closed) {
        notifyListeners();
      }
    });
  }

  Future<void> setZoom(double value) => command((c) async {
    final next = value.clamp(minZoom, maxZoom);
    await c.setZoomLevel(next);
    zoom = next;
  });
  Future<void> setExposure(double value) => command((c) async {
    exposure = await c.setExposureOffset(value.clamp(minExposure, maxExposure));
  });
  Future<void> toggleTorch() => command((c) async {
    await c.setFlashMode(torch ? FlashMode.off : FlashMode.torch);
    torch = !torch;
  });
  Future<void> focus(Offset point) => command((c) async {
    if (c.value.focusPointSupported) {
      await c.setFocusPoint(point);
    }
    if (c.value.exposurePointSupported) {
      await c.setExposurePoint(point);
    }
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_permissionInFlight) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(start());
    } else {
      unawaited(suspend());
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _active = false;
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    await _enqueue(_release);
    super.dispose();
  }

  @override
  void dispose() {
    unawaited(close());
  }
}
