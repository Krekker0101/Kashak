import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

abstract final class Diagnostics {
  static void configure() {
    PaintingBinding.instance.imageCache.maximumSize = 40;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;
    if (!kReleaseMode) {
      debugPrint(
        'Scetch diagnostics: decoded image cache capped at 64 MiB. Use DevTools frame chart in profile mode.',
      );
    }
  }
}
