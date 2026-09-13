import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../domain/project.dart';

class ProjectTile extends ConsumerWidget {
  const ProjectTile({super.key, required this.project, this.trailing});
  final Project project;
  final Widget? trailing;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(12),
      minVerticalPadding: 16,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: Colors.white,
          child: Image.file(
            File(ref.read(imageFilesProvider).resolve(project.processedImage)),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            cacheWidth: 168,
            errorBuilder: (_, error, stack) => const SizedBox(
              width: 56,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
      title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${project.updatedAt.toLocal().day}.${project.updatedAt.toLocal().month}.${project.updatedAt.toLocal().year}',
      ),
      trailing: trailing ?? const Icon(Icons.arrow_outward_rounded),
      onTap: () => context.push('/trace/${project.id}'),
    ),
  );
}
