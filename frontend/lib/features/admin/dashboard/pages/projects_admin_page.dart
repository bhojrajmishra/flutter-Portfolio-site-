import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/project.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';
import '../../widgets/file_pick_helpers.dart';

class ProjectsAdminPage extends ConsumerWidget {
  const ProjectsAdminPage({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Project? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    final tagsController = TextEditingController(text: existing?.techTags.join(', ') ?? '');
    final liveUrlController = TextEditingController(text: existing?.liveUrl ?? '');
    final repoUrlController = TextEditingController(text: existing?.repoUrl ?? '');
    String? imageUrl = existing?.imageUrl;
    bool featured = existing?.featured ?? false;
    bool uploading = false;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Project' : 'Edit Project'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tagsController,
                      decoration:
                          const InputDecoration(labelText: 'Tech tags (comma-separated, e.g. Flutter, MySQL)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: liveUrlController,
                      decoration: const InputDecoration(labelText: 'Live URL (optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: repoUrlController,
                      decoration: const InputDecoration(labelText: 'Repository URL (optional)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  final picked = await pickFileBytes(type: FileType.image);
                                  if (picked == null) return;
                                  setDialogState(() => uploading = true);
                                  try {
                                    final url = await ref
                                        .read(portfolioRepositoryProvider)
                                        .uploadImage(picked.bytes, picked.name);
                                    setDialogState(() {
                                      imageUrl = url;
                                      uploading = false;
                                    });
                                  } catch (e) {
                                    setDialogState(() => uploading = false);
                                    if (context.mounted) {
                                      showSnack(context, 'Upload failed: $e', isError: true);
                                    }
                                  }
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.image_outlined),
                          label: const Text('Thumbnail'),
                        ),
                        const SizedBox(width: 12),
                        if (imageUrl != null)
                          Expanded(child: Text(imageUrl!, overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: featured,
                      onChanged: (v) => setDialogState(() => featured = v ?? false),
                      title: const Text('Featured'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final repo = ref.read(portfolioRepositoryProvider);
    final tags = tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final project = Project(
      id: existing?.id ?? 0,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      imageUrl: imageUrl,
      techTags: tags,
      liveUrl: liveUrlController.text.trim().isEmpty ? null : liveUrlController.text.trim(),
      repoUrl: repoUrlController.text.trim().isEmpty ? null : repoUrlController.text.trim(),
      featured: featured,
      sortOrder: existing?.sortOrder ?? 0,
    );

    if (existing == null) {
      await repo.createProject(project);
    } else {
      await repo.updateProject(project);
    }
    ref.invalidate(projectsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Project project) async {
    final confirmed = await confirmDelete(context, itemLabel: project.title);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteProject(project.id);
    ref.invalidate(projectsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return AdminPage(
      title: 'Projects',
      subtitle: 'Shown as cards in the Projects section.',
      action: ElevatedButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
      child: projectsAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (projects) {
          if (projects.isEmpty) {
            return const Text('No projects yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: projects
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (p.featured) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star, size: 16, color: AppColors.accentEnd),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(p.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textSecondary)),
                                  if (p.techTags.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(p.techTags.join(', '),
                                        style: const TextStyle(color: AppColors.accentEnd, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openForm(context, ref, existing: p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, p),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
