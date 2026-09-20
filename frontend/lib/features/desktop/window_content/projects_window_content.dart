import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';

enum _Category { all, popular, mobile, web }

const _categoryDefs = <(_Category, String, IconData)>[
  (_Category.all, 'All Projects', Icons.star_rounded),
  (_Category.popular, 'Popular', Icons.local_fire_department_rounded),
  (_Category.mobile, 'Mobile', Icons.phone_iphone_rounded),
  (_Category.web, 'Web', Icons.public_rounded),
];

const _seeButtonBlue = Color(0xFF0A84FF);

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
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: AppLoadingIndicator())),
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
            final columns = constraints.maxWidth > 640 ? 2 : 1;

            final content = SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showSidebar) ...[
                    _CategoryChipsRow(
                      selected: _selected,
                      counts: counts,
                      onSelect: (c) => setState(() => _selected = c),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (banner != null) ...[
                    const _SectionHeading('Featured'),
                    const SizedBox(height: 20),
                    _FeaturedBanner(project: banner),
                    const SizedBox(height: 36),
                  ],
                  if (gridItems.isEmpty && banner == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No projects in this category yet.', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else if (gridItems.isNotEmpty) ...[
                    const _SectionHeading('My Projects'),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gridItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 32,
                        mainAxisExtent: 232,
                      ),
                      itemBuilder: (context, i) => _ProjectListTile(project: gridItems[i]),
                    ),
                  ],
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

/// A section title ("Featured" / "My Projects") with the thin divider rule
/// underneath it, matching the reference design.
class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 10),
        Container(height: 1, color: AppColors.glassBorder),
      ],
    );
  }
}

class _CategorySidebar extends ConsumerWidget {
  final _Category selected;
  final Map<_Category, int> counts;
  final ValueChanged<_Category> onSelect;

  const _CategorySidebar({required this.selected, required this.counts, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroProvider).value;
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
          const Spacer(),
          if (hero != null && hero.name.isNotEmpty) _SidebarProfile(name: hero.name, role: hero.title),
        ],
      ),
    );
  }
}

/// Sidebar footer showing the site owner's own name/role (from the Hero
/// content the admin already fills in) with an initials avatar — no stock
/// photo, since the data model has no profile-picture field.
class _SidebarProfile extends StatelessWidget {
  final String name;
  final String role;
  const _SidebarProfile({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
            child: Text(initial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                if (role.isNotEmpty)
                  Text(role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
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

IconData _fallbackLogoIcon(Project project) =>
    _isMobile(project) ? Icons.phone_iphone_rounded : (_isWeb(project) ? Icons.public_rounded : Icons.widgets_rounded);

/// A project's small square icon badge — its own uploaded logo if set,
/// otherwise a generic icon derived from its tech tags.
class _ProjectLogo extends StatelessWidget {
  final Project project;
  final double size;
  const _ProjectLogo({required this.project, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final hasLogo = project.logoUrl != null && project.logoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: hasLogo
          ? Image.network(
              project.logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  Icon(_fallbackLogoIcon(project), size: size * 0.5, color: AppColors.background),
            )
          : Icon(_fallbackLogoIcon(project), size: size * 0.5, color: AppColors.background),
    );
  }
}

/// The single "Featured" project: text (category, description, "See more")
/// on one side and a large banner image with the project's logo badge
/// overlapping its top-right corner on the other — stacked on narrow
/// windows instead of side-by-side.
class _FeaturedBanner extends StatelessWidget {
  final Project project;
  const _FeaturedBanner({required this.project});

  @override
  Widget build(BuildContext context) {
    final link = (project.liveUrl?.isNotEmpty ?? false) ? project.liveUrl : project.repoUrl;
    final hasImage = project.imageUrl != null && project.imageUrl!.isNotEmpty;

    final image = Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: hasImage
                ? Image.network(
                    project.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
                  )
                : const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
          ),
        ),
        Positioned(top: -14, right: 20, child: _ProjectLogo(project: project, size: 64)),
      ],
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(project.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        if (project.category != null && project.category!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(project.category!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 16),
        Text(
          project.description,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 20),
        if (link != null && link.isNotEmpty) _SeeButton(label: 'See more', onTap: () => _openLink(link)),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [image, const SizedBox(height: 24), text]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 5, child: text),
            const SizedBox(width: 32),
            Expanded(flex: 6, child: image),
          ],
        );
      },
    );
  }
}

void _openLink(String url) => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');

/// A pill button — solid blue with white text (the "See more" style used on
/// the Featured card) or, via [filled]: false, a white pill with blue text
/// (the compact "See" style used on each project row).
class _SeeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _SeeButton({required this.label, required this.onTap, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: filled ? 22 : 16, vertical: filled ? 13 : 8),
          decoration: BoxDecoration(
            color: filled ? _seeButtonBlue : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: filled ? 14 : 12.5,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : _seeButtonBlue,
            ),
          ),
        ),
      ),
    );
  }
}

/// One row in the "My Projects" grid: logo + title + category + a "See"
/// button, with the project's banner image beneath it. The whole tile is
/// clickable, not just the button.
class _ProjectListTile extends StatelessWidget {
  final Project project;
  const _ProjectListTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final link = (project.liveUrl?.isNotEmpty ?? false) ? project.liveUrl : project.repoUrl;
    final hasImage = project.imageUrl != null && project.imageUrl!.isNotEmpty;

    return MouseRegion(
      cursor: (link != null && link.isNotEmpty) ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: (link != null && link.isNotEmpty) ? () => _openLink(link) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProjectLogo(project: project, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(project.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      if (project.category != null && project.category!.isNotEmpty)
                        Text(project.category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (link != null && link.isNotEmpty) _SeeButton(label: 'See', onTap: () => _openLink(link), filled: false),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.network(
                        project.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
                      )
                    : const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
