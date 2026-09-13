import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../errors/app_failure.dart';
import '../image/image_files.dart';
import 'image_processor.dart';
import 'processing_settings.dart';

class IsolateImageProcessor implements ImageProcessor {
  IsolateImageProcessor(this.cacheDirectory);
  final String cacheDirectory;
  @override
  Future<ProcessedImage> process(
    String sourcePath,
    ProcessingSettings settings,
  ) {
    final directory = cacheDirectory;
    return Isolate.run(() => processImage(sourcePath, settings, directory));
  }
}

/// Entire read/decode/filter/encode pipeline runs in the worker isolate.
Future<ProcessedImage> processImage(
  String sourcePath,
  ProcessingSettings s,
  String directory,
) async {
  try {
    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.length > 40 * 1024 * 1024) {
      throw const AppFailure(
        FailureKind.image,
        'Choose an image smaller than 40 MB.',
      );
    }
    final key = sha256.convert([
      ...sha256.convert(bytes).bytes,
      ...utf8.encode(jsonEncode(s.toJson())),
      1,
    ]).toString();
    final output = File(p.join(directory, '$key.png'));
    final metadata = File(p.join(directory, '$key.json'));
    if (await output.exists() && await metadata.exists()) {
      final dimensions = jsonDecode(await metadata.readAsString()) as List;
      await output.setLastModified(DateTime.now());
      return ProcessedImage(
        output.path,
        dimensions[0] as int,
        dimensions[1] as int,
      );
    }
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) {
      throw const AppFailure(
        FailureKind.format,
        'Unsupported format. Choose JPEG, PNG or WebP.',
      );
    }
    final info = decoder.startDecode(bytes);
    if (info == null || info.width * info.height > 48000000) {
      throw const AppFailure(
        FailureKind.image,
        'Image could not be loaded. Maximum size is 48 megapixels.',
      );
    }
    var image = decoder.decodeFrame(0);
    if (image == null) {
      throw const AppFailure(FailureKind.image, 'Image could not be loaded.');
    }
    image = img.bakeOrientation(image);
    const maxSide = 1600;
    if (math.max(image.width, image.height) > maxSide) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxSide : null,
        height: image.height > image.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }
    final left = (s.cropLeft.clamp(0, 0.98) * image.width).floor();
    final top = (s.cropTop.clamp(0, 0.98) * image.height).floor();
    final right = (s.cropRight.clamp(s.cropLeft + 0.01, 1) * image.width)
        .ceil();
    final bottom = (s.cropBottom.clamp(s.cropTop + 0.01, 1) * image.height)
        .ceil();
    image = img.copyCrop(
      image,
      x: left,
      y: top,
      width: math.max(1, right - left),
      height: math.max(1, bottom - top),
    );
    if (s.quarterTurns % 4 != 0) {
      image = img.copyRotate(image, angle: (s.quarterTurns % 4) * 90);
    }
    if (s.mirror) {
      image = img.flipHorizontal(image);
    }
    image = img.adjustColor(
      image,
      brightness: 1 + s.brightness.clamp(-0.9, 1),
      contrast: s.contrast.clamp(0.2, 3),
    );
    if (s.smoothing > 0) {
      image = img.gaussianBlur(
        image,
        radius: (s.smoothing.clamp(0, 1) * 4).ceil(),
      );
    }
    switch (s.mode) {
      case ProcessingMode.original:
        break;
      case ProcessingMode.grayscale:
        image = img.grayscale(image);
      case ProcessingMode.highContrast:
        image = img.adjustColor(img.grayscale(image), contrast: 1.8);
      case ProcessingMode.outline:
      case ProcessingMode.sketch:
        image = _edges(img.grayscale(image), s);
    }
    await output.parent.create(recursive: true);
    final temporary = File(
      '${output.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await temporary.writeAsBytes(img.encodePng(image), flush: true);
    if (await output.exists()) {
      await temporary.delete();
    } else {
      await temporary.rename(output.path);
    }
    await metadata.writeAsString(
      jsonEncode([image.width, image.height]),
      flush: true,
    );
    await ImageFiles(Directory(directory)).pruneCache(Directory(directory));
    return ProcessedImage(output.path, image.width, image.height);
  } on AppFailure {
    rethrow;
  } catch (error) {
    throw AppFailure(
      FailureKind.processing,
      'Processing failed. Please try another image.',
      error,
    );
  }
}

img.Image _edges(img.Image source, ProcessingSettings s) {
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  double luminance(int x, int y) => source
      .getPixel(
        x.clamp(0, source.width - 1).toInt(),
        y.clamp(0, source.height - 1).toInt(),
      )
      .r
      .toDouble();
  final radius = s.lineWidth.round().clamp(1, 4).toInt();
  final threshold = 110 * (1 - s.details.clamp(0, 1));
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final gx =
          -luminance(x - radius, y - radius) +
          luminance(x + radius, y - radius) -
          2 * luminance(x - radius, y) +
          2 * luminance(x + radius, y) -
          luminance(x - radius, y + radius) +
          luminance(x + radius, y + radius);
      final gy =
          -luminance(x - radius, y - radius) -
          2 * luminance(x, y - radius) -
          luminance(x + radius, y - radius) +
          luminance(x - radius, y + radius) +
          2 * luminance(x, y + radius) +
          luminance(x + radius, y + radius);
      final strength =
          (math.sqrt(gx * gx + gy * gy) * s.edgeStrength.clamp(0.1, 3) -
                  threshold)
              .clamp(0, 255);
      final shade = s.mode == ProcessingMode.sketch
          ? ((255 - luminance(x, y)) * 0.22 + strength).clamp(0, 255)
          : strength;
      // Transparent paper keeps the live drawing visible underneath the lines.
      output.setPixelRgba(x, y, 24, 24, 28, shade.round());
    }
  }
  return output;
}
