import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/cv/image_processor.dart';
import '../../../core/cv/processing_settings.dart';
import '../../../core/image/image_files.dart';
import '../../../core/logging/app_log.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_repository.dart';

class EditorController extends ChangeNotifier {
  EditorController(this.project, this.processor, this.files, this.repository)
    : settings = project.processing,
      preview = ProcessedImage(
        files.resolve(project.processedImage),
        project.imageWidth,
        project.imageHeight,
      );
  Project project;
  final ImageProcessor processor;
  final ImageFiles files;
  final ProjectRepository repository;
  ProcessingSettings settings;
  ProcessedImage preview;
  bool busy = false, saving = false, _disposed = false, _running = false;
  Object? error;
  Timer? _debounce;
  int _revision = 0;

  void change(ProcessingSettings next) {
    settings = next;
    _revision++;
    busy = true;
    error = null;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _process);
  }

  Future<void> _process() async {
    if (_running || _disposed) {
      return;
    }
    _running = true;
    do {
      final revision = _revision;
      final snapshot = settings;
      try {
        final result = await processor.process(
          files.resolve(project.originalImage),
          snapshot,
        );
        if (!_disposed && revision == _revision) {
          preview = result;
          error = null;
        }
      } catch (failure, stack) {
        AppLog.error('Prepare image', failure, stack);
        if (!_disposed && revision == _revision) {
          error = failure;
        }
      }
      if (_disposed || revision == _revision) {
        break;
      }
    } while (true);
    _running = false;
    if (!_disposed) {
      busy = false;
      notifyListeners();
    }
  }

  Future<Project> save() async {
    if (busy || error != null || saving) {
      throw StateError('Image is not ready');
    }
    saving = true;
    notifyListeners();
    try {
      final path = await files.keepProcessed(project.id, preview);
      project = project.copyWith(
        processing: settings,
        processedImage: path,
        imageWidth: preview.width,
        imageHeight: preview.height,
        updatedAt: DateTime.now().toUtc(),
      );
      await repository.save(project);
      await files.removeOldPreviews(
        project.id,
        project.originalImage,
        project.processedImage,
      );
      return project;
    } finally {
      saving = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
