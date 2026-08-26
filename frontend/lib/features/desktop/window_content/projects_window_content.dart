import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_theme.dart';

class ProjectsWindowContent extends ConsumerWidget {
  const ProjectsWindowContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720 ? 3 : (constraints.maxWidth > 480 ? 2 : 1);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: projectsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Text('Failed to load: $e'),
            data: (projects) {
              if (projects.isEmpty) {
                return const Text('Add projects from the admin panel.',
                    style: TextStyle(color: AppColors.textSecondary));
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 260,
                ),
                itemBuilder: (context, i) => _ProjectCard(project: projects[i]),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.imageUrl != null && project.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                project.imageUrl!,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            )
          else
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(height: 10),
          Text(project.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              project.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
            ),
          ),
          if (project.techTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: project.techTags
                    .map((t) => Text('#$t', style: const TextStyle(fontSize: 11, color: AppColors.accentEnd)))
                    .toList(),
              ),
            ),
          Row(
            children: [
              if (project.liveUrl != null && project.liveUrl!.isNotEmpty)
                IconButton(
                  tooltip: 'Live',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => launchUrl(Uri.parse(project.liveUrl!), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                ),
              if (project.repoUrl != null && project.repoUrl!.isNotEmpty)
                IconButton(
                  tooltip: 'Source',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => launchUrl(Uri.parse(project.repoUrl!), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.code, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
