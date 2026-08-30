import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/social_link.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/platform_icons.dart';
import '../window_manager.dart';

/// Fills the empty middle of the desktop with a macOS-Notification-Center
/// style "widget stack" — a profile card, an autoplaying career-history
/// reel, a live stats card, and a quick-actions card. Every number/entry
/// shown comes from real admin-entered content (project/skill/experience
/// data), nothing fabricated. Sits behind open windows in the Stack so it
/// never steals clicks from them.
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
          const _CareerReelCard(),
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
  final double width;
  const _WidgetCard({required this.child, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassCard(padding: const EdgeInsets.all(16), borderRadius: 20, child: child),
    );
  }
}

final _reelMonthYear = DateFormat('MMM yyyy');

String _reelRange(DateTime start, DateTime? end) {
  final startStr = _reelMonthYear.format(start);
  final endStr = end != null ? _reelMonthYear.format(end) : 'Present';
  return '$startStr — $endStr';
}

class _ReelEntry {
  final IconData icon;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String range;
  final String? description;
  final DateTime startDate;

  const _ReelEntry({
    required this.icon,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.range,
    required this.startDate,
    this.description,
  });
}

/// Autoplaying "story"-style reel through real Experience + Education
/// entries (most recent first) — a thin progress bar per entry fills over
/// a few seconds, then advances, with a fade/slide transition between
/// slides. Hovering pauses playback; the arrows and progress bars also
/// support jumping directly to a slide.
class _CareerReelCard extends ConsumerStatefulWidget {
  const _CareerReelCard();

  @override
  ConsumerState<_CareerReelCard> createState() => _CareerReelCardState();
}

class _CareerReelCardState extends ConsumerState<_CareerReelCard> with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(seconds: 6);

  late final AnimationController _controller;
  int _index = 0;
  bool _playbackStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _slideDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted) return;
    setState(() => _index++);
    _controller.forward(from: 0);
  }

  void _goTo(int target, int length) {
    if (length == 0) return;
    setState(() => _index = ((target % length) + length) % length);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final experience = ref.watch(experienceProvider).value ?? [];
    final education = ref.watch(educationProvider).value ?? [];

    final entries = <_ReelEntry>[
      for (final e in experience)
        _ReelEntry(
          icon: Icons.work_outline_rounded,
          typeLabel: 'Experience',
          title: e.role,
          subtitle: e.company,
          range: _reelRange(e.startDate, e.endDate),
          startDate: e.startDate,
          description: e.description,
        ),
      for (final e in education)
        _ReelEntry(
          icon: Icons.school_outlined,
          typeLabel: 'Education',
          title: e.degree,
          subtitle: e.school,
          range: _reelRange(e.startDate, e.endDate),
          startDate: e.startDate,
        ),
    ]..sort((a, b) => b.startDate.compareTo(a.startDate));

    if (entries.isEmpty) {
      return _WidgetCard(
        width: 320,
        child: const SizedBox(
          height: 160,
          child: Center(
            child: Text('Add experience or education from the admin panel.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
      );
    }

    if (!_playbackStarted) {
      _playbackStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }

    final safeIndex = _index % entries.length;
    final entry = entries[safeIndex];

    return _WidgetCard(
      width: 320,
      child: MouseRegion(
        onEnter: (_) => _controller.stop(),
        onExit: (_) => _controller.forward(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Text(
                  'MY JOURNEY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.6),
                ),
                Spacer(),
                Icon(Icons.play_circle_outline_rounded, size: 13, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _goTo(i, entries.length),
                      child: _ReelProgressBar(controller: _controller, isCurrent: i == safeIndex, isPast: i < safeIndex),
                    ),
                  ),
                  if (i != entries.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 132,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: _ReelSlide(key: ValueKey(safeIndex), entry: entry),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ReelNavButton(icon: Icons.chevron_left_rounded, onTap: () => _goTo(safeIndex - 1, entries.length)),
                const Spacer(),
                Text('${safeIndex + 1} / ${entries.length}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                const Spacer(),
                _ReelNavButton(icon: Icons.chevron_right_rounded, onTap: () => _goTo(safeIndex + 1, entries.length)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelProgressBar extends StatelessWidget {
  final AnimationController controller;
  final bool isCurrent;
  final bool isPast;
  const _ReelProgressBar({required this.controller, required this.isCurrent, required this.isPast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(color: AppColors.glassFill),
            if (isPast)
              const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient))
            else if (isCurrent)
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => FractionallySizedBox(
                  widthFactor: controller.value,
                  alignment: Alignment.centerLeft,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReelNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ReelNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: AppColors.glassFill, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ReelSlide extends StatelessWidget {
  final _ReelEntry entry;
  const _ReelSlide({required super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(entry.icon, size: 14, color: AppColors.accentEnd),
            const SizedBox(width: 6),
            Text(
              entry.typeLabel.toUpperCase(),
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentEnd, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          entry.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(entry.range, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (entry.description != null && entry.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              entry.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ],
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
