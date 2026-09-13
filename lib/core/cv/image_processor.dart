import 'processing_settings.dart';

class ProcessedImage {
  const ProcessedImage(this.path, this.width, this.height);
  final String path;
  final int width;
  final int height;
}

/// Implementations own threading and cache policy. An OpenCV adapter can replace
/// the Dart isolate implementation without changing editor or tracing widgets.
abstract interface class ImageProcessor {
  Future<ProcessedImage> process(
    String sourcePath,
    ProcessingSettings settings,
  );
}
