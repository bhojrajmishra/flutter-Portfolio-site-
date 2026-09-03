import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../window_content/about_window_content.dart';
import '../window_content/app_store_window_content.dart';
import '../window_content/blog_window_content.dart';
import '../window_content/calendar_window_content.dart';
import '../window_content/contact_window_content.dart';
import '../window_content/experience_window_content.dart';
import '../window_content/projects_window_content.dart';
import '../window_content/resume_window_content.dart';
import '../window_manager.dart';

/// [desktopSize] is only consumed by content that itself opens another
/// window (currently just Calendar, to jump to Contact) — everything else
/// ignores it.
Widget buildWindowContent(String id, Size desktopSize) {
  switch (id) {
    case 'about':
      return const AboutWindowContent();
    case 'resume':
      return const ResumeWindowContent();
    case 'projects':
      return const ProjectsWindowContent();
    case 'calendar':
      return CalendarWindowContent(desktopSize: desktopSize);
    case 'experience':
      return const ExperienceWindowContent();
    case 'contact':
      return const ContactWindowContent();
    case 'blog':
      return const BlogWindowContent();
    case 'appstore':
      return const AppStoreWindowContent();
    default:
      return const SizedBox.shrink();
  }
}

/// The draggable, resizable, closable chrome around one [DesktopWindow]'s
/// content. Positioned absolutely within the desktop [Stack] by the caller.
class WindowFrame extends ConsumerWidget {
  final DesktopWindow window;
  final Size desktopSize;

  const WindowFrame({super.key, required this.window, required this.desktopSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(windowManagerProvider.notifier);

    return Positioned(
      left: window.position.dx,
      top: window.position.dy,
      width: window.size.width,
      height: window.size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (_) => notifier.focusWindow(window.id),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  children: [
                    _TitleBar(window: window, notifier: notifier, desktopSize: desktopSize),
                    Expanded(child: buildWindowContent(window.id, desktopSize)),
                  ],
                ),
                if (!window.isMaximized)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _ResizeHandle(window: window, notifier: notifier),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatefulWidget {
  final DesktopWindow window;
  final WindowManagerNotifier notifier;
  final Size desktopSize;

  const _TitleBar({required this.window, required this.notifier, required this.desktopSize});

  @override
  State<_TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<_TitleBar> {
  // Real macOS behavior: hovering anywhere over the traffic-light cluster
  // reveals the ×/−/+ glyphs in all three at once, not just the one under
  // the cursor.
  bool _hoveringLights = false;

  @override
  Widget build(BuildContext context) {
    final window = widget.window;
    final notifier = widget.notifier;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => notifier.moveWindow(window.id, window.position + details.delta, widget.desktopSize),
      onDoubleTap: () => notifier.toggleMaximize(window.id, widget.desktopSize),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Row(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _hoveringLights = true),
              onExit: (_) => setState(() => _hoveringLights = false),
              child: Row(
                children: [
                  _TrafficLight(
                    color: const Color(0xFFFF5F57),
                    icon: Icons.close,
                    showIcon: _hoveringLights,
                    onTap: () => notifier.closeWindow(window.id),
                  ),
                  const SizedBox(width: 8),
                  _TrafficLight(
                    color: const Color(0xFFFEBC2E),
                    icon: Icons.remove,
                    showIcon: _hoveringLights,
                    onTap: () => notifier.minimizeWindow(window.id),
                  ),
                  const SizedBox(width: 8),
                  _TrafficLight(
                    color: const Color(0xFF28C840),
                    icon: window.isMaximized ? Icons.close_fullscreen : Icons.open_in_full,
                    iconSize: 6,
                    showIcon: _hoveringLights,
                    onTap: () => notifier.toggleMaximize(window.id, widget.desktopSize),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(window.icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                window.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool showIcon;
  final VoidCallback onTap;
  final double iconSize;

  const _TrafficLight({
    required this.color,
    required this.icon,
    required this.showIcon,
    required this.onTap,
    this.iconSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: showIcon ? Border.all(color: Colors.black.withValues(alpha: 0.15)) : null,
          ),
          alignment: Alignment.center,
          child: showIcon ? Icon(icon, size: iconSize, color: const Color(0xFF4D2600)) : null,
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  final DesktopWindow window;
  final WindowManagerNotifier notifier;
  const _ResizeHandle({required this.window, required this.notifier});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onPanUpdate: (details) => widget.notifier.resizeWindow(
          widget.window.id,
          widget.window.size + Offset(details.delta.dx, details.delta.dy),
        ),
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.all(4),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: _hovering ? 1.3 : 1.0,
            child: Icon(
              Icons.drag_indicator,
              size: 14,
              color: _hovering ? AppColors.accentEnd : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
