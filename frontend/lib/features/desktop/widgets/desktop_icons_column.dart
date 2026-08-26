import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/widgets/platform_icons.dart';
import '../window_manager.dart';
import 'desktop_icon.dart';

/// Right-side column of desktop icons: Projects (real badge = project
/// count from the DB — no fabricated numbers) plus one icon per social
/// link the admin has configured, using each platform's brand color/icon
/// and an optional admin-set badge (never a number we invent ourselves).
class DesktopIconsColumn extends ConsumerWidget {
  final Size desktopSize;
  const DesktopIconsColumn({super.key, required this.desktopSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value;
    final socialLinks = ref.watch(socialLinksProvider).value ?? [];
    final notifier = ref.read(windowManagerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DesktopIconButton(
          icon: Icons.flutter_dash_rounded,
          iconColor: const Color(0xFF027DFD),
          tileColor: Colors.white,
          label: 'Projects',
          badge: projects != null && projects.isNotEmpty ? '${projects.length}' : null,
          onTap: () => notifier.openWindow('projects', desktopSize: desktopSize),
        ),
        for (final link in socialLinks) ...[
          const SizedBox(height: 4),
          Builder(builder: (context) {
            final info = platformIconInfoFor(link.platform);
            return DesktopIconButton(
              icon: Icons.link,
              tileChild: Center(child: info.build(size: 22)),
              tileColor: const Color(0xFF1A1D29),
              label: _titleCase(link.platform),
              badge: link.badgeText,
              onTap: () => launchUrl(Uri.parse(link.url), webOnlyWindowName: '_blank'),
            );
          }),
        ],
      ],
    );
  }
}

String _titleCase(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
