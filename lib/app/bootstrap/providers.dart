import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cv/image_processor.dart';
import '../../core/image/image_files.dart';
import '../../features/projects/domain/project_repository.dart';
import '../../features/projects/domain/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => throw StateError('Bootstrap required'),
);
final imageProcessorProvider = Provider<ImageProcessor>(
  (ref) => throw StateError('Bootstrap required'),
);
final imageFilesProvider = Provider<ImageFiles>(
  (ref) => throw StateError('Bootstrap required'),
);
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('Bootstrap required'),
);
final projectsProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).watchAll(),
);
final projectProvider = FutureProvider.autoDispose.family<Project?, String>(
  (ref, id) => ref.watch(projectRepositoryProvider).find(id),
);
