import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../core/logging/app_log.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../import_image/data/import_service.dart';
import '../../projects/presentation/project_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _busy = false;
  ImportService get _importer => ImportService(
    ImagePicker(),
    ref.read(imageFilesProvider),
    ref.read(imageProcessorProvider),
    ref.read(projectRepositoryProvider),
  );
  @override
  void initState() {
    super.initState();
    Future.microtask(_recover);
  }

  Future<void> _recover() async {
    if (!mounted || !Platform.isAndroid) {
      return;
    }
    setState(() => _busy = true);
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (lost.exception != null) {
        throw lost.exception!;
      }
      for (final file in lost.files ?? <XFile>[]) {
        await _importer.create(file);
      }
    } catch (error, stack) {
      AppLog.error('Recover import', error, stack);
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final project = await _importer.pick(source);
      if (mounted && project != null) {
        context.push('/editor/${project.id}');
      }
    } catch (error, stack) {
      AppLog.error('Import image', error, stack);
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'scetch',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Text(
            'Make space\nfor drawing.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text('A reference. A blank page. You.'),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.gesture_rounded, size: 48),
                  const SizedBox(height: 32),
                  Text(
                    'Your next drawing',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.add),
                      label: const Text('New Drawing'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Import From Gallery'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => context.push('/camera'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Camera'),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Projects',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/projects'),
                child: const Text('Projects'),
              ),
            ],
          ),
          projects.when(
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Your first drawing starts here.'),
                  )
                : Column(
                    children: items
                        .take(3)
                        .map((p) => ProjectTile(project: p))
                        .toList(),
                  ),
            error: (error, stack) => FailureView(error: error),
            loading: () => const LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
