import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/scetch_theme.dart';
import '../../../core/camera/camera_session.dart';
import 'camera_surface.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CameraSession camera;
  @override
  void initState() {
    super.initState();
    camera = CameraSession();
    unawaited(camera.start());
  }

  @override
  void dispose() {
    unawaited(camera.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ScetchTheme.create(Brightness.dark),
    child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Your drawing space')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraSurface(session: camera),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Import a photo from Home to add a reference.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
