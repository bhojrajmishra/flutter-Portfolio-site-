import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../window_manager.dart';
import 'calendar_tile.dart';

/// Bottom macOS-style dock: Resume (opens the PDF directly) plus one icon
/// per window "app", styled with distinct per-app tile colors (like real
/// app icons), a running-indicator dot under open windows, a hover-scale
/// animation, and a real glassmorphism bar (backdrop blur + translucent
/// tint + a faint top sheen, like real macOS dock glass) instead of a flat
/// translucent color.
class Dock extends ConsumerWidget {
  final Size desktopSize;
  const Dock({super.key, required this.desktopSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeProvider).value;
    final openWindows = ref.watch(windowManagerProvider);
    final notifier = ref.read(windowManagerProvider.notifier);
    final openIds = openWindows.map((w) => w.id).toSet();

    return Center(
      // Shadow lives on this outer, unclipped box — a clip inside would cut
      // off the blurred shadow's spread past the bar's rounded edges.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x4012151F),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resume != null)
                    _DockIcon(
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: const Color(0xFFEA4335),
                      tileColor: Colors.white,
                      tooltip: 'Resume',
                      isOpen: openIds.contains('resume'),
                      onTap: () => notifier.openWindow(
                        'resume',
                        desktopSize: desktopSize,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    icon: Icons.storefront_rounded,
                    iconColor: Colors.white,
                    tileGradient: const LinearGradient(
                      colors: [Color(0xFF0A84FF), Color(0xFF0040DD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    tooltip: 'App Store',
                    isOpen: openIds.contains('appstore'),
                    onTap: () => notifier.openWindow(
                      'appstore',
                      desktopSize: desktopSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    icon: Icons.person_rounded,
                    tileGradient: AppColors.accentGradient,
                    tooltip: 'About Me',
                    isOpen: openIds.contains('about'),
                    onTap: () =>
                        notifier.openWindow('about', desktopSize: desktopSize),
                  ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    icon: Icons.flutter_dash_rounded,
                    iconColor: const Color(0xFF027DFD),
                    tileColor: Colors.white,
                    tooltip: 'Projects',
                    isOpen: openIds.contains('projects'),
                    onTap: () => notifier.openWindow(
                      'projects',
                      desktopSize: desktopSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    tileChild: const CalendarTile(),
                    tileColor: Colors.white,
                    tooltip: 'Calendar',
                    isOpen: openIds.contains('calendar'),
                    onTap: () => notifier.openWindow(
                      'calendar',
                      desktopSize: desktopSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    icon: Icons.timeline_outlined,
                    iconColor: Colors.white,
                    tileColor: const Color(0xFFFF9F0A),
                    tooltip: 'Experience',
                    isOpen: openIds.contains('experience'),
                    onTap: () => notifier.openWindow(
                      'experience',
                      desktopSize: desktopSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    icon: Icons.chat_bubble_rounded,
                    iconColor: Colors.white,
                    tileColor: const Color(0xFF2ECC71),
                    tooltip: 'Contact',
                    isOpen: openIds.contains('contact'),
                    onTap: () => notifier.openWindow(
                      'contact',
                      desktopSize: desktopSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DockIcon(
                    icon: Icons.explore_rounded,
                    iconColor: Colors.white,
                    tileGradient: const LinearGradient(
                      colors: [Color(0xFF63E2FF), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    tooltip: 'Blog',
                    isOpen: openIds.contains('blog'),
                    onTap: () =>
                        notifier.openWindow('blog', desktopSize: desktopSize),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatefulWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? tileColor;
  final Gradient? tileGradient;
  final Widget? tileChild;
  final String tooltip;
  final VoidCallback onTap;
  final bool isOpen;

  const _DockIcon({
    this.icon,
    this.iconColor,
    this.tileColor,
    this.tileGradient,
    this.tileChild,
    required this.tooltip,
    required this.onTap,
    this.isOpen = false,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: false,
        verticalOffset: 42,
        waitDuration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _hovering ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: widget.tileGradient == null
                        ? (widget.tileColor ?? AppColors.surface)
                        : null,
                    gradient: widget.tileGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      widget.tileChild ??
                      Icon(
                        widget.icon,
                        color: widget.iconColor ?? Colors.white,
                        size: 22,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 4,
                width: 4,
                child: widget.isOpen
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
