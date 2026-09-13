import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../projects/domain/project.dart';
import 'editor_controller.dart';
import 'crop_controls.dart';
import 'preparation_controls.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(projectProvider(id))
      .when(
        data: (project) => project == null
            ? const Scaffold(body: Center(child: Text('Project not found.')))
            : _EditorWorkspace(project: project),
        error: (error, stack) => Scaffold(body: FailureView(error: error)),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
}

class _EditorWorkspace extends ConsumerStatefulWidget {
  const _EditorWorkspace({required this.project});
  final Project project;
  @override
  ConsumerState<_EditorWorkspace> createState() => _EditorWorkspaceState();
}

class _EditorWorkspaceState extends ConsumerState<_EditorWorkspace> {
  late final EditorController controller;
  bool preparing = false;
  @override
  void initState() {
    super.initState();
    controller = EditorController(
      widget.project,
      ref.read(imageProcessorProvider),
      ref.read(imageFilesProvider),
      ref.read(projectRepositoryProvider),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!preparing) {
      setState(() => preparing = true);
      return;
    }
    try {
      final project = await controller.save();
      if (!mounted) {
        return;
      }
      ref.invalidate(projectProvider(project.id));
      if (mounted) {
        context.pushReplacement('/trace/${project.id}');
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(preparing ? 'Image Preparation' : 'Edit image'),
        actions: [
          if (preparing)
            IconButton(
              tooltip: 'Crop and rotate',
              onPressed: () => setState(() => preparing = false),
              icon: const Icon(Icons.crop),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: Colors.white,
                    child: SizedBox.expand(
                      child: RepaintBoundary(
                        child: Image.file(
                          File(controller.preview.path),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, error, stack) =>
                              FailureView(error: error),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (controller.busy) const LinearProgressIndicator(),
            if (controller.error != null)
              TextButton(
                onPressed: () => controller.change(controller.settings),
                child: const Text('Processing failed · Tap to retry'),
              ),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: preparing
                    ? PreparationControls(
                        settings: controller.settings,
                        onChanged: controller.change,
                      )
                    : CropControls(
                        settings: controller.settings,
                        onChanged: controller.change,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      controller.busy ||
                          controller.saving ||
                          controller.error != null
                      ? null
                      : _continue,
                  child: Text(
                    controller.saving
                        ? 'Saving…'
                        : preparing
                        ? 'Start tracing'
                        : 'Prepare image',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
