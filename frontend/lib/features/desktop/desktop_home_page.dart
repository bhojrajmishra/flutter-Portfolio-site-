import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/data_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/platform_icons.dart';
import 'mobile_content_page.dart';
import 'widgets/calendar_tile.dart';
import 'widgets/desktop_background.dart';
import 'widgets/desktop_icon.dart';
import 'widgets/desktop_icons_column.dart';
import 'widgets/desktop_widget_stack.dart';
import 'widgets/dock.dart';
import 'widgets/menu_bar.dart';
import 'widgets/weather_widget.dart';
import 'widgets/window_frame.dart';
import 'window_manager.dart';

/// The "/" route: a simulated desktop with draggable windows on wide
/// viewports (>=1000px — a real window manager needs the room), and a
/// simplified fullscreen-navigation layout below that.
class DesktopHomePage extends StatelessWidget {
  const DesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return size.width >= 1000
              ? _Desktop(desktopSize: size)
              : _MobileHome(desktopSize: size);
        },
      ),
    );
  }
}

class _Desktop extends ConsumerWidget {
  final Size desktopSize;
  const _Desktop({required this.desktopSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(windowManagerProvider);
    final visible = windows.where((w) => !w.minimized).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Stack(
      children: [
        const Positioned.fill(child: DesktopBackground()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DesktopMenuBar(desktopSize: desktopSize),
        ),
        const Positioned(top: 56, left: 24, child: WeatherWidget()),
        Positioned(
          top: 56,
          right: 8,
          bottom: 110,
          child: DesktopIconsColumn(desktopSize: desktopSize),
        ),
        Positioned(
          top: 90,
          left: 0,
          right: 0,
          bottom: 150,
          child: Center(
            child: SingleChildScrollView(
              child: DesktopWidgetStack(desktopSize: desktopSize),
            ),
          ),
        ),
        for (final w in visible)
          WindowFrame(window: w, desktopSize: desktopSize),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Center(
            child: Text(
              'Built with Flutter',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Dock(desktopSize: desktopSize),
        ),
      ],
    );
  }
}

class _MobileHome extends ConsumerWidget {
  final Size desktopSize;
  const _MobileHome({required this.desktopSize});

  void _openFullscreen(BuildContext context, String id) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MobileContentPage(windowId: id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeProvider).value;
    final apk = ref.watch(apkProvider).value;
    final projects = ref.watch(projectsProvider).value;
    final socialLinks = ref.watch(socialLinksProvider).value ?? [];
    final hero = ref.watch(heroProvider).value;

    return SizedBox(
      width: desktopSize.width,
      height: desktopSize.height,
      child: Stack(
        children: [
          const Positioned.fill(child: DesktopBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero?.name.isNotEmpty == true ? hero!.name : 'Portfolio',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const WeatherWidget(),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 4,
                    runSpacing: 12,
                    children: [
                      DesktopIconButton(
                        icon: Icons.person_rounded,
                        tileGradient: AppColors.accentGradient,
                        label: 'About Me',
                        onTap: () => _openFullscreen(context, 'about'),
                      ),
                      DesktopIconButton(
                        icon: Icons.flutter_dash_rounded,
                        iconColor: const Color(0xFF027DFD),
                        tileColor: Colors.white,
                        label: 'Projects',
                        badge: (projects != null && projects.isNotEmpty)
                            ? '${projects.length}'
                            : null,
                        onTap: () => _openFullscreen(context, 'projects'),
                      ),
                      DesktopIconButton(
                        icon: Icons.calendar_month_rounded,
                        tileChild: const CalendarTile(),
                        tileColor: Colors.white,
                        label: 'Calendar',
                        onTap: () => _openFullscreen(context, 'calendar'),
                      ),
                      DesktopIconButton(
                        icon: Icons.timeline_outlined,
                        tileColor: const Color(0xFFFF9F0A),
                        label: 'Experience',
                        onTap: () => _openFullscreen(context, 'experience'),
                      ),
                      DesktopIconButton(
                        icon: Icons.chat_bubble_rounded,
                        tileColor: const Color(0xFF2ECC71),
                        label: 'Contact',
                        onTap: () => _openFullscreen(context, 'contact'),
                      ),
                      DesktopIconButton(
                        icon: Icons.explore_rounded,
                        tileGradient: const LinearGradient(
                          colors: [Color(0xFF63E2FF), Color(0xFF1E88E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        label: 'Blog',
                        onTap: () => _openFullscreen(context, 'blog'),
                      ),
                      if (resume != null)
                        DesktopIconButton(
                          icon: Icons.picture_as_pdf_rounded,
                          iconColor: const Color(0xFFEA4335),
                          tileColor: Colors.white,
                          label: 'Resume',
                          onTap: () => launchUrl(
                            Uri.parse(resume.url),
                            webOnlyWindowName: '_blank',
                          ),
                        ),
                      if (apk != null)
                        DesktopIconButton(
                          icon: Icons.android_rounded,
                          tileColor: const Color(0xFF3DDC84),
                          label: 'Download App',
                          onTap: () => launchUrl(
                            Uri.parse(apk.url),
                            webOnlyWindowName: '_blank',
                          ),
                        ),
                      for (final link in socialLinks)
                        Builder(builder: (context) {
                          final info = platformIconInfoFor(link.platform);
                          return DesktopIconButton(
                            icon: Icons.link,
                            tileChild: Center(child: info.build(size: 22)),
                            label: link.platform,
                            badge: link.badgeText,
                            onTap: () => launchUrl(
                              Uri.parse(link.url),
                              webOnlyWindowName: '_blank',
                            ),
                          );
                        }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
