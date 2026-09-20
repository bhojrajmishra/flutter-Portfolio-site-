import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/app_listing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/glass_card.dart';
import '../window_manager.dart';

final _updatedFormat = DateFormat('MMM d, yyyy');

String _formatSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
}

/// Icon glyph + accent color per category — real store apps use category
/// to drive an app's visual identity, so this isn't decoration, it's the
/// one piece of the listing's look that's actually derived from data.
(IconData, Color) _categoryStyle(String category) {
  switch (category) {
    case 'Productivity':
      return (Icons.bolt_rounded, const Color(0xFF0A84FF));
    case 'Utilities':
      return (Icons.build_rounded, const Color(0xFF32ADE6));
    case 'Tools':
      return (Icons.handyman_rounded, const Color(0xFFFF9F0A));
    case 'Business':
      return (Icons.business_center_rounded, const Color(0xFF5E5CE6));
    case 'Education':
      return (Icons.school_rounded, AppColors.accentStart);
    case 'Entertainment':
      return (Icons.movie_rounded, const Color(0xFFFF375F));
    case 'Social':
      return (Icons.forum_rounded, AppColors.accentEnd);
    case 'Health & Fitness':
      return (Icons.favorite_rounded, const Color(0xFF30D158));
    case 'Lifestyle':
      return (Icons.style_rounded, const Color(0xFFFFD60A));
    default:
      return (Icons.apps_rounded, const Color(0xFF8E8E93));
  }
}

/// The "App Store" window: a real, browsable, multi-app listing — a
/// category filter row, a list of every published app, and a per-app
/// product detail page. Every fact shown (name, category, description,
/// version, size, date) is exactly what the admin entered — no invented
/// ratings, download counts, or screenshots.
class AppStoreWindowContent extends ConsumerStatefulWidget {
  const AppStoreWindowContent({super.key});

  @override
  ConsumerState<AppStoreWindowContent> createState() => _AppStoreWindowContentState();
}

class _AppStoreWindowContentState extends ConsumerState<AppStoreWindowContent> {
  AppListing? _selected;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);
    final hero = ref.watch(heroProvider).value;
    final notifier = ref.read(windowManagerProvider.notifier);

    return Column(
      children: [
        _StoreTopBar(
          showBack: _selected != null,
          onBack: () => setState(() => _selected = null),
          title: _selected?.name,
        ),
        Expanded(
          child: appsAsync.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, st) => Center(
              child: Text('Failed to load: $e', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            data: (apps) {
              if (apps.isEmpty) return const _EmptyStore();

              if (_selected != null) {
                final current = apps.firstWhere((a) => a.id == _selected!.id, orElse: () => _selected!);
                return _AppDetail(
                  app: current,
                  developerName: hero?.name.isNotEmpty == true ? hero!.name : null,
                  onOpenAbout: () => notifier.openWindow('about', desktopSize: MediaQuery.sizeOf(context)),
                  onOpenProjects: () => notifier.openWindow('projects', desktopSize: MediaQuery.sizeOf(context)),
                );
              }

              final categories = apps.map((a) => a.category).toSet().toList()..sort();
              final visible = _category == null ? apps : apps.where((a) => a.category == _category).toList();

              return Column(
                children: [
                  if (categories.length > 1)
                    _CategoryFilterBar(
                      categories: categories,
                      selected: _category,
                      onSelect: (c) => setState(() => _category = c),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: visible.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _AppRow(
                        app: visible[i],
                        onTap: () => setState(() => _selected = visible[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreTopBar extends StatelessWidget {
  final bool showBack;
  final VoidCallback onBack;
  final String? title;
  const _StoreTopBar({required this.showBack, required this.onBack, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.storefront_rounded, size: 16, color: AppColors.accentEnd),
            ),
          const SizedBox(width: 6),
          Text(title ?? 'App Store', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyStore extends StatelessWidget {
  const _EmptyStore();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            const Text('No apps published yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Published apps will appear here once uploaded from the admin panel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _CategoryFilterBar({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _FilterChip(label: 'All', selected: selected == null, onTap: () => onSelect(null)),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            _FilterChip(label: c, selected: selected == c, onTap: () => onSelect(c)),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.accentGradient : null,
            color: selected ? null : AppColors.glassFill,
            borderRadius: BorderRadius.circular(100),
            border: selected ? null : Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String category;
  final double size;
  const _AppIcon({required this.category, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _categoryStyle(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

class _AppRow extends StatelessWidget {
  final AppListing app;
  final VoidCallback onTap;
  const _AppRow({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _AppIcon(category: app.category),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(app.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Text(
                      '${app.category} · ${_formatSize(app.sizeBytes)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _GetButton(app: app, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDetail extends StatelessWidget {
  final AppListing app;
  final String? developerName;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenProjects;

  const _AppDetail({
    required this.app,
    required this.developerName,
    required this.onOpenAbout,
    required this.onOpenProjects,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            borderRadius: 26,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AppIcon(category: app.category, size: 84),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          if (developerName != null) ...[
                            const SizedBox(height: 3),
                            Text('by $developerName', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: [
                              _Chip(label: app.category),
                              if (app.versionLabel != null && app.versionLabel!.isNotEmpty)
                                _Chip(label: 'v${app.versionLabel}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _GetButton(app: app, compact: false),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: _StatsRow(app: app),
          ),
          const SizedBox(height: 14),
          GlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABOUT THIS APP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.6),
                ),
                const SizedBox(height: 10),
                Text(
                  app.description?.isNotEmpty == true ? app.description! : 'No description provided.',
                  style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                const _RequirementNote(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(
              children: [
                _LinkRow(icon: Icons.person_outline_rounded, label: 'Meet the developer', onTap: onOpenAbout),
                _LinkRow(icon: Icons.work_outline_rounded, label: 'See more projects', onTap: onOpenProjects),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppListing app;
  const _StatsRow({required this.app});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('VERSION', app.versionLabel?.isNotEmpty == true ? app.versionLabel! : '1.0'),
      _StatData('SIZE', _formatSize(app.sizeBytes)),
      _StatData('UPDATED', _updatedFormat.format(app.uploadedAt)),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0)
            Container(width: 1, height: 32, color: AppColors.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
          Expanded(
            child: Column(
              children: [
                Text(stats[i].value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(
                  stats[i].label,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  const _StatData(this.label, this.value);
}

class _GetButton extends StatefulWidget {
  final AppListing app;
  final bool compact;
  const _GetButton({required this.app, required this.compact});

  @override
  State<_GetButton> createState() => _GetButtonState();
}

class _GetButtonState extends State<_GetButton> {
  bool _justTapped = false;

  Future<void> _handleTap() async {
    await launchUrl(Uri.parse(widget.app.url), webOnlyWindowName: '_blank');
    if (!mounted) return;
    setState(() => _justTapped = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justTapped = false);
  }

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 26, vertical: widget.compact ? 7 : 11),
          decoration: BoxDecoration(
            gradient: _justTapped ? null : AppColors.accentGradient,
            color: _justTapped ? AppColors.glassFill : null,
            borderRadius: BorderRadius.circular(100),
            border: _justTapped ? Border.all(color: AppColors.glassBorder) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_justTapped) ...[
                Icon(Icons.check_rounded, size: widget.compact ? 13 : 15, color: AppColors.accentEnd),
                const SizedBox(width: 5),
              ],
              Text(
                _justTapped ? (widget.compact ? 'Done' : 'Downloading') : 'GET',
                style: TextStyle(
                  fontSize: widget.compact ? 11.5 : 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                  color: _justTapped ? AppColors.accentEnd : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.compact) return button;

    return Row(
      children: [
        button,
        const SizedBox(width: 12),
        Text('Direct download · ${_formatSize(widget.app.sizeBytes)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RequirementNote extends StatelessWidget {
  const _RequirementNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: AppColors.accentEnd),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not on the Play Store — this installs directly. Android may ask you to '
              'allow installs from this source the first time.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.label, required this.onTap});

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.glassFill : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 13))),
              const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
