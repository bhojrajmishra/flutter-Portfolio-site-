import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_theme.dart';

enum _Category { all, popular, mobile, web }

const _categoryDefs = <(_Category, String, IconData)>[
  (_Category.all, 'All Projects', Icons.grid_view_rounded),
  (_Category.popular, 'Popular', Icons.local_fire_department_rounded),
  (_Category.mobile, 'Mobile', Icons.phone_iphone_rounded),
  (_Category.web, 'Web', Icons.public_rounded),
];

// Categories are derived from each project's admin-entered tech tags —
// there's no separate "category" field in the data model, so a project can
// land in more than one bucket (e.g. tagged both "flutter" and "web").
const _mobileHints = {'flutter', 'android', 'ios', 'kotlin', 'swift', 'react native', 'mobile', 'dart'};
const _webHints = {
  'web', 'react', 'next.js', 'nextjs', 'vue', 'angular', 'html', 'css',
  'javascript', 'typescript', 'node', 'node.js', 'flutter web',
};

bool _hasAny(Project p, Set<String> hints) {
  final tags = p.techTags.map((t) => t.toLowerCase().trim());
  return tags.any(hints.contains);
}

bool _isMobile(Project p) => _hasAny(p, _mobileHints);
bool _isWeb(Project p) => _hasAny(p, _webHints);

List<Project> _filterFor(_Category c, List<Project> all) {
  switch (c) {
    case _Category.all:
      return all;
    case _Category.popular:
      return all.where((p) => p.featured).toList();
    case _Category.mobile:
      return all.where(_isMobile).toList();
    case _Category.web:
      return all.where(_isWeb).toList();
  }
}

class ProjectsWindowContent extends ConsumerStatefulWidget {
  const ProjectsWindowContent({super.key});

  @override
  ConsumerState<ProjectsWindowContent> createState() => _ProjectsWindowContentState();
}

class _ProjectsWindowContentState extends ConsumerState<ProjectsWindowContent> {
  _Category _selected = _Category.all;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, st) => Center(
        child: Padding(padding: const EdgeInsets.all(32), child: Text('Failed to load: $e')),
      ),
      data: (allProjects) {
        if (allProjects.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Add projects from the admin panel.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        final counts = {
          _Category.all: allProjects.length,
          _Category.popular: allProjects.where((p) => p.featured).length,
          _Category.mobile: allProjects.where(_isMobile).length,
          _Category.web: allProjects.where(_isWeb).length,
        };

        final filtered = _filterFor(_selected, allProjects);
        Project? banner;
        var gridItems = filtered;
        final featuredInFiltered = filtered.where((p) => p.featured).toList();
        if (featuredInFiltered.isNotEmpty) {
          banner = featuredInFiltered.first;
          gridItems = filtered.where((p) => p != banner).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar = constraints.maxWidth > 520;
            final columns = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

            final content = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showSidebar)
                    _CategoryChipsRow(
                      selected: _selected,
                      counts: counts,
                      onSelect: (c) => setState(() => _selected = c),
                    ),
                  if (banner != null) ...[
                    _FeaturedBanner(project: banner),
                    const SizedBox(height: 16),
                  ],
                  if (gridItems.isEmpty && banner == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No projects in this category yet.', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else if (gridItems.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gridItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 260,
                      ),
                      itemBuilder: (context, i) => _ProjectCard(project: gridItems[i]),
                    ),
                ],
              ),
            );

            if (!showSidebar) return content;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategorySidebar(
                  selected: _selected,
                  counts: counts,
                  onSelect: (c) => setState(() => _selected = c),
                ),
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final _Category selected;
  final Map<_Category, int> counts;
  final ValueChanged<_Category> onSelect;

  const _CategorySidebar({required this.selected, required this.counts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'CATEGORIES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          for (final def in _categoryDefs)
            _CategoryTile(
              icon: def.$3,
              label: def.$2,
              count: counts[def.$1] ?? 0,
              isSelected: selected == def.$1,
              onTap: () => onSelect(def.$1),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.accentGradient : null,
            color: selected ? null : (_hovering ? AppColors.glassFill : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal fallback for narrow window widths where a sidebar wouldn't fit.
class _CategoryChipsRow extends StatelessWidget {
  final _Category selected;
  final Map<_Category, int> counts;
  final ValueChanged<_Category> onSelect;

  const _CategoryChipsRow({required this.selected, required this.counts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final def in _categoryDefs) ...[
              _CategoryChip(
                label: def.$2,
                count: counts[def.$1] ?? 0,
                isSelected: selected == def.$1,
                onTap: () => onSelect(def.$1),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.count, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected ? null : AppColors.glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            '$label · $count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// The single, large "hero" card at the top of a filtered list — mirrors the
/// featured-project treatment from modern portfolio apps (image overlay,
/// FEATURED badge, prominent View button).
class _FeaturedBanner extends StatelessWidget {
  final Project project;
  const _FeaturedBanner({required this.project});

  @override
  Widget build(BuildContext context) {
    final link = (project.liveUrl?.isNotEmpty ?? false) ? project.liveUrl : project.repoUrl;
    final hasImage = project.imageUrl != null && project.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(project.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                )
              : null,
        ),
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (link != null && link.isNotEmpty)
                    ElevatedButton(
                      onPressed: () => launchUrl(Uri.parse(link), webOnlyWindowName: '_blank'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('View'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final link = (project.liveUrl?.isNotEmpty ?? false) ? project.liveUrl : project.repoUrl;
    final hasSeparateRepo = project.repoUrl != null && project.repoUrl!.isNotEmpty && project.repoUrl != link;
    final categoryIcon = _isMobile(project) ? Icons.phone_iphone_rounded : (_isWeb(project) ? Icons.public_rounded : Icons.widgets_rounded);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
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
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: AppColors.glassFill, borderRadius: BorderRadius.circular(8)),
                child: Icon(categoryIcon, size: 14, color: AppColors.accentEnd),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              project.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 12.5),
            ),
          ),
          if (project.techTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: project.techTags
                    .take(3)
                    .map((t) => Text('#$t', style: const TextStyle(fontSize: 10.5, color: AppColors.accentEnd)))
                    .toList(),
              ),
            ),
          Row(
            children: [
              const Spacer(),
              if (hasSeparateRepo)
                IconButton(
                  tooltip: 'Source',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => launchUrl(Uri.parse(project.repoUrl!), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.code, size: 16),
                ),
              if (link != null && link.isNotEmpty)
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(link), webOnlyWindowName: '_blank'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.glassFill,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
