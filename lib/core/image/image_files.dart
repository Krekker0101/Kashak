import 'dart:io';
import 'package:path/path.dart' as p;
import '../errors/app_failure.dart';
import '../cv/image_processor.dart';

class ImageFiles {
  ImageFiles(this.root);
  final Directory root;
  String resolve(String relative) {
    final result = p.normalize(p.join(root.path, relative));
    if (!p.isWithin(root.path, result)) {
      throw const AppFailure(FailureKind.storage, 'Invalid image location.');
    }
    return result;
  }

  Future<String> import(String source, String id) async {
    final file = File(source);
    if (await file.length() > 40 * 1024 * 1024) {
      throw const AppFailure(
        FailureKind.image,
        'Choose an image smaller than 40 MB.',
      );
    }
    final relative = p.join(
      'projects',
      id,
      'original${p.extension(source).toLowerCase()}',
    );
    final destination = File(resolve(relative));
    await destination.parent.create(recursive: true);
    await file.copy(destination.path);
    return relative;
  }

  Future<String> keepProcessed(String id, ProcessedImage image) async {
    final relative = p.join('projects', id, p.basename(image.path));
    final target = File(resolve(relative));
    await target.parent.create(recursive: true);
    if (!await target.exists()) {
      await File(image.path).copy(target.path);
    }
    return relative;
  }

  Future<void> deleteProject(String id) async {
    final directory = Directory(resolve(p.join('projects', id)));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> removeOldPreviews(
    String id,
    String original,
    String processed,
  ) async {
    final directory = Directory(resolve(p.join('projects', id)));
    if (!await directory.exists()) {
      return;
    }
    final protected = {resolve(original), resolve(processed)};
    await for (final entry in directory.list()) {
      if (entry is File && !protected.contains(p.normalize(entry.path))) {
        await entry.delete();
      }
    }
  }

  Future<void> pruneCache(
    Directory cache, {
    int maxBytes = 96 * 1024 * 1024,
  }) async {
    if (!await cache.exists()) {
      return;
    }
    final files = await cache
        .list()
        .where((f) => f is File)
        .cast<File>()
        .toList();
    final entries = <(File, FileStat)>[];
    for (final file in files) {
      entries.add((file, await file.stat()));
    }
    entries.sort((a, b) => b.$2.modified.compareTo(a.$2.modified));
    var total = 0;
    for (final entry in entries) {
      total += entry.$2.size;
      if (total > maxBytes) {
        await entry.$1.delete();
      }
    }
  }
}
