import 'package:scetch/features/projects/domain/project.dart';
import 'package:scetch/features/projects/domain/project_repository.dart';

class MemoryProjectRepository implements ProjectRepository {
  final values = <String, Project>{};
  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }

  @override
  Future<Project?> find(String id) async => values[id];
  @override
  Future<void> save(Project project) async {
    values[project.id] = project;
  }

  @override
  Stream<List<Project>> watchAll() => Stream.value(values.values.toList());
}
