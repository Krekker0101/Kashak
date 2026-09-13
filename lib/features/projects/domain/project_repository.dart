import 'project.dart';

abstract interface class ProjectRepository {
  Stream<List<Project>> watchAll();
  Future<Project?> find(String id);
  Future<void> save(Project project);
  Future<void> delete(String id);
}
