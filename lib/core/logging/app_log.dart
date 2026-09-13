import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

abstract final class AppLog {
  static void error(String operation, Object error, StackTrace stack) {
    // Never log image paths, image bytes or project names in release builds.
    if (!kReleaseMode) {
      developer.log(operation, name: 'Scetch', error: error, stackTrace: stack);
    }
  }
}
