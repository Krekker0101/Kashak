import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scetch/core/cv/isolate_image_processor.dart';
import 'package:scetch/core/cv/processing_settings.dart';
import 'package:scetch/core/errors/app_failure.dart';

void main() {
  late Directory directory;
  late File source;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('scetch_images');
    source = File('${directory.path}/source.png');
    final image = img.Image(width: 80, height: 40);
    for (final pixel in image) {
      pixel.setRgb(pixel.x < 40 ? 255 : 0, pixel.y * 5, 20);
    }
    await source.writeAsBytes(img.encodePng(image));
  });
  tearDown(() => directory.delete(recursive: true));
  test('processing settings JSON round trip', () {
    const settings = ProcessingSettings(
      mode: ProcessingMode.sketch,
      brightness: 0.1,
      contrast: 1.3,
      smoothing: 0.4,
      details: 0.8,
      edgeStrength: 2,
      lineWidth: 3,
      mirror: true,
      quarterTurns: 1,
    );
    expect(ProcessingSettings.fromJson(settings.toJson()), settings);
  });
  test('crop then rotation and content cache work', () async {
    final processor = IsolateImageProcessor('${directory.path}/cache');
    const settings = ProcessingSettings(cropRight: 0.5, quarterTurns: 1);
    final result = await processor.process(source.path, settings);
    expect(result.width, 40);
    expect(result.height, 40);
    final cached = await processor.process(source.path, settings);
    expect(cached.path, result.path);
    final other = await processor.process(
      source.path,
      settings.copyWith(brightness: 0.2),
    );
    expect(other.path, isNot(result.path));
  });
  for (final mode in ProcessingMode.values) {
    test('$mode generates decodable image', () async {
      final processor = IsolateImageProcessor('${directory.path}/cache');
      final result = await processor.process(
        source.path,
        ProcessingSettings(mode: mode),
      );
      final image = img.decodePng(await File(result.path).readAsBytes());
      expect(image, isNotNull);
      expect(image!.width, 80);
      if (mode == ProcessingMode.outline || mode == ProcessingMode.sketch) {
        expect(image.numChannels, 4);
      }
    });
  }
  test('corrupt input reports typed failure', () async {
    await source.writeAsString('not an image');
    expect(
      IsolateImageProcessor(
        '${directory.path}/cache',
      ).process(source.path, const ProcessingSettings()),
      throwsA(isA<AppFailure>()),
    );
  });
}
