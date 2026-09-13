import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/camera/camera_session.dart';
import '../../../shared/widgets/value_slider.dart';
import '../domain/trace_transform.dart';
import 'trace_controller.dart';

class TraceTools extends StatelessWidget {
  const TraceTools({
    super.key,
    required this.trace,
    required this.camera,
    required this.blinkSpeed,
    required this.onBlinkSpeed,
    required this.onExit,
  });
  final TraceController trace;
  final CameraSession camera;
  final int blinkSpeed;
  final ValueChanged<int> onBlinkSpeed;
  final VoidCallback onExit;
  Future<void> _grid(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: trace,
        builder: (context, _) {
          final grid = trace.settings.grid;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Grid', style: Theme.of(context).textTheme.titleLarge),
                  Wrap(
                    spacing: 8,
                    children: [0, 2, 3, 4, 5, 8]
                        .map(
                          (n) => ChoiceChip(
                            label: Text(n == 0 ? 'Off' : '${n}×$n'),
                            selected: grid.divisions == n,
                            onSelected: (_) =>
                                trace.grid(grid.copyWith(divisions: n)),
                          ),
                        )
                        .toList(),
                  ),
                  ValueSlider(
                    label: 'Custom divisions',
                    value: grid.divisions.clamp(2, 24).toDouble(),
                    min: 2,
                    max: 24,
                    divisions: 22,
                    onChanged: (v) =>
                        trace.grid(grid.copyWith(divisions: v.round())),
                  ),
                  SwitchListTile(
                    title: const Text('Attach to reference'),
                    value: grid.referenceBound,
                    onChanged: (v) =>
                        trace.grid(grid.copyWith(referenceBound: v)),
                  ),
                  ValueSlider(
                    label: 'Grid opacity',
                    value: grid.opacity,
                    onChanged: (v) => trace.grid(grid.copyWith(opacity: v)),
                  ),
                  ValueSlider(
                    label: 'Line thickness',
                    value: grid.thickness,
                    min: 0.5,
                    max: 4,
                    onChanged: (v) => trace.grid(grid.copyWith(thickness: v)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  Future<void> _cameraTools(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: camera,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueSlider(
                label: 'Camera zoom',
                value: camera.zoom,
                min: camera.minZoom,
                max: camera.maxZoom,
                onChanged: camera.maxZoom > camera.minZoom
                    ? camera.setZoom
                    : null,
              ),
              ValueSlider(
                label: 'Exposure',
                value: camera.exposure,
                min: camera.minExposure,
                max: camera.maxExposure,
                onChanged: camera.maxExposure > camera.minExposure
                    ? camera.setExposure
                    : null,
              ),
              const Text('Double-tap the preview to focus.'),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final settings = trace.settings;
    if (settings.locked) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              button: true,
              label: 'Hold to unlock reference',
              child: GestureDetector(
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  trace.unlock();
                },
                child: FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hold the button to unlock.')),
                  ),
                  icon: const Icon(Icons.lock),
                  label: const Text('Hold to unlock'),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Save and close',
                onPressed: onExit,
                icon: const Icon(Icons.arrow_back),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Flashlight',
                isSelected: camera.torch,
                onPressed: camera.controller == null
                    ? null
                    : camera.toggleTorch,
                icon: const Icon(Icons.flashlight_on_outlined),
              ),
              IconButton(
                tooltip: 'Camera controls',
                onPressed: camera.controller == null
                    ? null
                    : () => _cameraTools(context),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueSlider(
                        label:
                            'Reference · ${(settings.opacity * 100).round()}%',
                        value: settings.opacity,
                        onChanged: trace.opacity,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Mirror horizontal',
                              onPressed: () => trace.transform(
                                settings.transform.copyWith(
                                  flipX: !settings.transform.flipX,
                                ),
                              ),
                              icon: const Icon(Icons.flip),
                            ),
                            IconButton(
                              tooltip: 'Mirror vertical',
                              onPressed: () => trace.transform(
                                settings.transform.copyWith(
                                  flipY: !settings.transform.flipY,
                                ),
                              ),
                              icon: const RotatedBox(
                                quarterTurns: 1,
                                child: Icon(Icons.flip),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Center',
                              onPressed: () => trace.transform(
                                settings.transform.copyWith(x: 0, y: 0),
                              ),
                              icon: const Icon(Icons.center_focus_strong),
                            ),
                            IconButton(
                              tooltip: 'Fit',
                              onPressed: () => trace.transform(
                                settings.transform.copyWith(
                                  x: 0,
                                  y: 0,
                                  scale: 1,
                                  rotation: 0,
                                ),
                              ),
                              icon: const Icon(Icons.fit_screen),
                            ),
                            IconButton(
                              tooltip: 'Reset transform',
                              onPressed: () =>
                                  trace.transform(const TraceTransform()),
                              icon: const Icon(Icons.restart_alt),
                            ),
                            IconButton(
                              tooltip: 'Grid',
                              onPressed: () => _grid(context),
                              icon: const Icon(Icons.grid_4x4),
                            ),
                            PopupMenuButton<int>(
                              tooltip: 'Blink comparison',
                              initialValue: blinkSpeed,
                              onSelected: onBlinkSpeed,
                              icon: Icon(
                                blinkSpeed == 0
                                    ? Icons.visibility_outlined
                                    : Icons.visibility,
                              ),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 0,
                                  child: Text('Blink off'),
                                ),
                                PopupMenuItem(value: 1200, child: Text('Slow')),
                                PopupMenuItem(
                                  value: 650,
                                  child: Text('Normal'),
                                ),
                                PopupMenuItem(value: 300, child: Text('Fast')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              trace.lock();
                            },
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Lock reference'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
