import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../shared/widgets/failure_view.dart';
import '../domain/project.dart';
import 'project_tile.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});
  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    Project project,
    String action,
  ) async {
    if (action == 'edit') {
      context.push('/editor/${project.id}');
      return;
    }
    final controller = TextEditingController(text: project.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'delete' ? 'Delete drawing?' : 'Rename drawing'),
        content: action == 'delete'
            ? const Text(
                'This removes the project and its images from this device.',
              )
            : TextField(controller: controller, maxLength: 80, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              action == 'delete' ? 'delete' : controller.text.trim(),
            ),
            child: Text(action == 'delete' ? 'Delete' : 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty || !context.mounted) {
      return;
    }
    try {
      final repository = ref.read(projectRepositoryProvider);
      if (action == 'delete') {
        await repository.delete(project.id);
        await ref.read(imageFilesProvider).deleteProject(project.id);
      } else {
        await repository.save(
          project.copyWith(name: result, updatedAt: DateTime.now().toUtc()),
        );
      }
      ref.invalidate(projectProvider(project.id));
    } catch (error) {
      if (context.mounted) {
        showFailure(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Your drawings')),
    body: ref
        .watch(projectsProvider)
        .when(
          data: (projects) => projects.isEmpty
              ? const Center(child: Text('Import an image to start a drawing.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) => ProjectTile(
                    project: projects[index],
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Project actions',
                      onSelected: (action) =>
                          _action(context, ref, projects[index], action),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit image')),
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
          error: (error, stack) => FailureView(
            error: error,
            retry: () => ref.invalidate(projectsProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
  );
}
