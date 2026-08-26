import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import 'section_heading.dart';

class ProjectsSection extends ConsumerWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final width = MediaQuery.of(context).size.width;
    final columns = Breakpoints.isDesktop(width) ? 3 : (Breakpoints.isTablet(width) ? 2 : 1);

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(title: 'Projects'),
          const SizedBox(height: 32),
          projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: 280,
                ),
                itemBuilder: (context, i) => _ProjectCard(project: projects[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.imageUrl != null && project.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                project.imageUrl!,
                height: 100,
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
          const SizedBox(height: 12),
          Text(project.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              project.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          if (project.techTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.techTags
                    .map((t) => Text('#$t',
                        style: const TextStyle(fontSize: 12, color: AppColors.accentEnd)))
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
                  icon: const Icon(Icons.open_in_new, size: 18),
                ),
              if (project.repoUrl != null && project.repoUrl!.isNotEmpty)
                IconButton(
                  tooltip: 'Source',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => launchUrl(Uri.parse(project.repoUrl!), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.code, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
