import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/social_link.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_icons.dart';
import '../window_manager.dart';

/// Fills the empty middle of the desktop with a macOS-Notification-Center
/// style "widget stack" — a profile card, a live stats card, and a
/// quick-actions card. Every number shown comes from real admin-entered
/// content (project/skill/experience counts), nothing fabricated. Sits
/// behind open windows in the Stack so it never steals clicks from them.
class DesktopWidgetStack extends ConsumerWidget {
  final Size desktopSize;
  const DesktopWidgetStack({super.key, required this.desktopSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroProvider).value;
    final projects = ref.watch(projectsProvider).value ?? [];
    final experience = ref.watch(experienceProvider).value ?? [];
    final skills = ref.watch(skillsProvider).value ?? [];
    final socialLinks = ref.watch(socialLinksProvider).value ?? [];
    final resume = ref.watch(resumeProvider).value;
    final notifier = ref.read(windowManagerProvider.notifier);

    int? yearsExperience;
    if (experience.isNotEmpty) {
      final earliest = experience.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
      yearsExperience = (DateTime.now().difference(earliest).inDays / 365).floor();
    }

    final name = hero?.name.isNotEmpty == true ? hero!.name : 'Portfolio';
    final title = hero?.title ?? '';

    return Padding(
      padding: const EdgeInsets.only(right: 90),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _WidgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (title.isNotEmpty)
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final link in socialLinks.take(5)) ...[
                        _SocialDot(link: link),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          _WidgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SNAPSHOT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(icon: Icons.flutter_dash_rounded, value: '${projects.length}', label: 'Projects'),
                    if (yearsExperience != null && yearsExperience > 0)
                      _StatItem(icon: Icons.timeline_outlined, value: '$yearsExperience+', label: 'Years')
                    else
                      _StatItem(icon: Icons.timeline_outlined, value: '${experience.length}', label: 'Roles'),
                    _StatItem(icon: Icons.bolt_rounded, value: '${skills.length}', label: 'Skills'),
                  ],
                ),
              ],
            ),
          ),
          _WidgetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.work_outline_rounded,
                  label: 'View Projects',
                  onTap: () => notifier.openWindow('projects', desktopSize: desktopSize),
                ),
                _ActionRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Get In Touch',
                  onTap: () => notifier.openWindow('contact', desktopSize: desktopSize),
                ),
                if (resume != null)
                  _ActionRow(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'View Resume',
                    onTap: () => launchUrl(Uri.parse(resume.url), webOnlyWindowName: '_blank'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  final Widget child;
  const _WidgetCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: GlassCard(padding: const EdgeInsets.all(16), borderRadius: 20, child: child),
    );
  }
}

class _SocialDot extends StatelessWidget {
  final SocialLink link;
  const _SocialDot({required this.link});

  @override
  Widget build(BuildContext context) {
    final info = platformIconInfoFor(link.platform);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(link.url), webOnlyWindowName: '_blank'),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.glassBorder),
          ),
          alignment: Alignment.center,
          child: info.build(size: 13),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentEnd),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ActionRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
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
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.glassFill : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12.5))),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
