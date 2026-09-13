import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/logging/app_log.dart';
import '../../projects/domain/project.dart';
import '../../projects/domain/project_repository.dart';
import '../domain/trace_settings.dart';
import '../domain/trace_transform.dart';

class TraceController extends ChangeNotifier {
  TraceController(this.project, this.repository) : settings = project.tracing;
  Project project;
  final ProjectRepository repository;
  TraceSettings settings;
  Timer? _timer;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  Object? saveError;
  void _change(TraceSettings next) {
    if (next == settings) {
      return;
    }
    settings = next;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), flush);
  }

  void transform(TraceTransform value) => _change(settings.setTransform(value));
  void opacity(double value) => _change(settings.setOpacity(value));
  void grid(GridSettings value) {
    if (!settings.locked) {
      _change(settings.copyWith(grid: value));
    }
  }

  void lock() => _change(settings.copyWith(locked: true));
  void unlock() => _change(settings.copyWith(locked: false));
  Future<void> flush() {
    _timer?.cancel();
    final snapshot = project.copyWith(
      tracing: settings,
      updatedAt: DateTime.now().toUtc(),
    );
    _writes = _writes.then((_) async {
      try {
        await repository.save(snapshot);
        project = snapshot;
        saveError = null;
      } catch (error, stack) {
        saveError = error;
        AppLog.error('Save tracing', error, stack);
      }
      if (!_disposed) {
        notifyListeners();
      }
    });
    return _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(flush());
    super.dispose();
  }
}
