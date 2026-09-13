import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scetch/core/storage/app_database.dart';
import 'package:scetch/core/cv/processing_settings.dart';
import 'package:scetch/features/projects/data/drift_project_repository.dart';
import 'package:scetch/features/projects/domain/project.dart';
import 'package:scetch/features/tracing/domain/trace_settings.dart';
import 'package:scetch/features/tracing/domain/trace_transform.dart';

void main() {
  test('full project survives closing and reopening SQLite', () async {
    final directory = await Directory.systemTemp.createTemp('scetch_test');
    final file = File('${directory.path}/projects.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    final now = DateTime.utc(2026, 9, 13);
    final project = Project(
      id: 'test',
      name: 'My drawing',
      createdAt: now,
      updatedAt: now,
      originalImage: 'projects/test/original.jpg',
      processedImage: 'projects/test/processed.png',
      imageWidth: 1200,
      imageHeight: 800,
      processing: const ProcessingSettings(
        mode: ProcessingMode.outline,
        brightness: 0.2,
        details: 0.7,
        cropLeft: 0.1,
      ),
      tracing: const TraceSettings(
        opacity: 0.8,
        locked: true,
        transform: TraceTransform(x: 0.3, flipY: true),
        grid: GridSettings(divisions: 8, referenceBound: true),
      ),
    );
    try {
      await DriftProjectRepository(db).save(project);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final repository = DriftProjectRepository(db);
      expect(await repository.find('test'), project);
      expect(await repository.watchAll().first, [project]);
      await repository.delete('test');
      expect(await repository.find('test'), isNull);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
