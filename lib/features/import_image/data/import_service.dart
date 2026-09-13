import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/cv/image_processor.dart';
import '../../../core/cv/processing_settings.dart';
import '../../../core/image/image_files.dart';
import '../../../core/logging/app_log.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_repository.dart';

class ImportService {
  ImportService(this.picker, this.files, this.processor, this.projects);
  final ImagePicker picker;
  final ImageFiles files;
  final ImageProcessor processor;
  final ProjectRepository projects;
  Future<Project?> pick(ImageSource source) async {
    final selected = await picker.pickImage(
      source: source,
      requestFullMetadata: false,
    );
    return selected == null ? null : create(selected);
  }

  Future<Project> create(XFile selected) async {
    final id = const Uuid().v4();
    try {
      final original = await files.import(selected.path, id);
      final processed = await processor.process(
        files.resolve(original),
        const ProcessingSettings(),
      );
      final result = await files.keepProcessed(id, processed);
      final now = DateTime.now().toUtc();
      final project = Project(
        id: id,
        name: 'Drawing ${now.day}.${now.month}',
        createdAt: now,
        updatedAt: now,
        originalImage: original,
        processedImage: result,
        imageWidth: processed.width,
        imageHeight: processed.height,
      );
      await projects.save(project);
      return project;
    } catch (error) {
      try {
        await files.deleteProject(id);
      } catch (cleanupError, stack) {
        AppLog.error('Clean failed import', cleanupError, stack);
      }
      rethrow;
    }
  }
}
