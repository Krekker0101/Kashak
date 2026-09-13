import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/project.dart';
import '../domain/project_repository.dart';

class DriftProjectRepository implements ProjectRepository {
  DriftProjectRepository(this.db);
  final AppDatabase db;
  Project _decode(ProjectRow row) {
    try {
      return Project.fromJson(jsonDecode(row.payload) as Map<String, dynamic>);
    } catch (error) {
      throw AppFailure(
        FailureKind.storage,
        'Project could not be restored.',
        error,
      );
    }
  }

  @override
  Stream<List<Project>> watchAll() =>
      (db.select(db.projectRows)
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
          .watch()
          .map((rows) => rows.map(_decode).toList());
  @override
  Future<Project?> find(String id) async {
    final row = await (db.select(
      db.projectRows,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  @override
  Future<void> save(Project project) async {
    await db
        .into(db.projectRows)
        .insertOnConflictUpdate(
          ProjectRowsCompanion.insert(
            id: project.id,
            payload: jsonEncode(project.toJson()),
            updatedAt: project.updatedAt,
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.projectRows)..where((r) => r.id.equals(id))).go();
  }
}
