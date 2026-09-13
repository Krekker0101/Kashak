import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/cv/isolate_image_processor.dart';
import '../../core/image/image_files.dart';
import '../../core/logging/app_log.dart';
import '../../core/performance/diagnostics.dart';
import '../../core/storage/app_database.dart';
import '../../features/projects/data/drift_project_repository.dart';
import '../../shared/widgets/failure_view.dart';
import '../scetch_app.dart';
import 'providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  Diagnostics.configure();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLog.error(
      'Flutter',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  try {
    final documents = await getApplicationSupportDirectory();
    final root = Directory(p.join(documents.path, 'scetch'));
    await root.create(recursive: true);
    final cache = Directory(
      p.join((await getTemporaryDirectory()).path, 'scetch_processed'),
    );
    final files = ImageFiles(root);
    await files.pruneCache(cache);
    final preferences = await SharedPreferences.getInstance();
    final db = AppDatabase(
      NativeDatabase.createInBackground(
        File(p.join(root.path, 'scetch.sqlite')),
      ),
    );
    runApp(
      ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(
            DriftProjectRepository(db),
          ),
          imageFilesProvider.overrideWithValue(files),
          imageProcessorProvider.overrideWithValue(
            IsolateImageProcessor(cache.path),
          ),
          preferencesProvider.overrideWithValue(preferences),
        ],
        child: const ScetchApp(),
      ),
    );
  } catch (error, stack) {
    AppLog.error('Bootstrap', error, stack);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: FailureView(error: error, retry: bootstrap),
        ),
      ),
    );
  }
}
