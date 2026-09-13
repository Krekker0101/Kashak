import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../app/theme/scetch_theme.dart';
import '../../../core/camera/camera_session.dart';
import '../../../core/logging/app_log.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../projects/domain/project.dart';
import '../domain/trace_transform.dart';
import 'camera_surface.dart';
import 'reference_overlay.dart';
import 'trace_controller.dart';
import 'trace_tools.dart';

class TracingScreen extends ConsumerWidget {
  const TracingScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(projectProvider(id))
      .when(
        data: (project) => project == null
            ? const Scaffold(body: Center(child: Text('Project not found.')))
            : _TraceWorkspace(project: project),
        error: (error, stack) => Scaffold(body: FailureView(error: error)),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
}

class _TraceWorkspace extends ConsumerStatefulWidget {
  const _TraceWorkspace({required this.project});
  final Project project;
  @override
  ConsumerState<_TraceWorkspace> createState() => _TraceWorkspaceState();
}

class _TraceWorkspaceState extends ConsumerState<_TraceWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TraceController trace;
  late final CameraSession camera;
  late final AnimationController blink;
  late final Animation<double> visibility;
  TraceTransform startTransform = const TraceTransform();
  Offset anchor = Offset.zero, focusPoint = Offset.zero;
  int blinkSpeed = 0;
  bool leaving = false;
  Size get reference => Size(
    widget.project.imageWidth.toDouble(),
    widget.project.imageHeight.toDouble(),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    trace = TraceController(
      widget.project,
      ref.read(projectRepositoryProvider),
    );
    camera = CameraSession();
    camera.addListener(_cameraChanged);
    unawaited(camera.start());
    blink = AnimationController(vsync: this, value: 1);
    visibility = blink.drive(CurveTween(curve: const Threshold(0.5)));
    unawaited(_wake(true));
  }

  void _cameraChanged() {
    final error = camera.controlFailure;
    if (error != null && mounted) {
      camera.controlFailure = null;
      showFailure(context, error);
    }
  }

  Future<void> _wake(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (error, stack) {
      AppLog.error('Keep screen awake', error, stack);
      if (mounted && enabled) {
        showFailure(context, error);
      }
    }
  }

  void _blink(int speed) {
    setState(() => blinkSpeed = speed);
    if (speed == 0) {
      blink.stop();
      blink.value = 1;
    } else {
      blink.duration = Duration(milliseconds: speed * 2);
      blink.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(trace.flush());
      blink.stop();
      unawaited(_wake(false));
    } else {
      _blink(blinkSpeed);
      unawaited(_wake(true));
    }
  }

  Future<void> _exit() async {
    if (trace.settings.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hold the lock button to unlock first.')),
      );
      return;
    }
    await trace.flush();
    if (!mounted) {
      return;
    }
    if (trace.saveError != null) {
      showFailure(context, trace.saveError!);
      return;
    }
    setState(() => leaving = true);
    await camera.close();
    if (!mounted) {
      return;
    }
    ref.invalidate(projectProvider(widget.project.id));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    trace.dispose();
    blink.dispose();
    camera.removeListener(_cameraChanged);
    unawaited(camera.close());
    unawaited(_wake(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ScetchTheme.create(Brightness.dark),
    child: PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_exit());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: leaving
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = constraints.biggest;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(child: CameraSurface(session: camera)),
                      ListenableBuilder(
                        listenable: trace,
                        builder: (context, _) => GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTapDown: (details) =>
                              focusPoint = details.localPosition,
                          onDoubleTap: () {
                            final c = camera.controller;
                            if (c != null && !trace.settings.locked) {
                              unawaited(
                                camera.focus(
                                  mapperFor(
                                    c,
                                    viewport,
                                  ).viewToPreview(focusPoint),
                                ),
                              );
                            }
                          },
                          onScaleStart: (details) {
                            if (trace.settings.locked) {
                              return;
                            }
                            startTransform = trace.settings.transform;
                            anchor = MatrixUtils.transformPoint(
                              Matrix4.inverted(
                                startTransform.matrix(viewport, reference),
                              ),
                              details.localFocalPoint,
                            );
                          },
                          onScaleUpdate: (details) => trace.transform(
                            startTransform.gesture(
                              anchor: anchor,
                              focal: details.localFocalPoint,
                              gestureScale: details.scale,
                              gestureRotation: details.rotation,
                              viewport: viewport,
                              reference: reference,
                            ),
                          ),
                          child: ReferenceOverlay(
                            path: ref
                                .read(imageFilesProvider)
                                .resolve(widget.project.processedImage),
                            reference: reference,
                            viewport: viewport,
                            settings: trace.settings,
                            visibility: visibility,
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: Listenable.merge([trace, camera]),
                        builder: (context, _) => TraceTools(
                          trace: trace,
                          camera: camera,
                          blinkSpeed: blinkSpeed,
                          onBlinkSpeed: _blink,
                          onExit: _exit,
                        ),
                      ),
                      ListenableBuilder(
                        listenable: trace,
                        builder: (context, _) => trace.saveError == null
                            ? const SizedBox.shrink()
                            : Align(
                                alignment: Alignment.topCenter,
                                child: SafeArea(
                                  child: TextButton(
                                    onPressed: trace.flush,
                                    child: const Text('Could not save · Retry'),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
      ),
    ),
  );
}
