import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../window_content/about_window_content.dart';
import '../window_content/contact_window_content.dart';
import '../window_content/experience_window_content.dart';
import '../window_content/projects_window_content.dart';
import '../window_manager.dart';

Widget buildWindowContent(String id) {
  switch (id) {
    case 'about':
      return const AboutWindowContent();
    case 'projects':
      return const ProjectsWindowContent();
    case 'experience':
      return const ExperienceWindowContent();
    case 'contact':
      return const ContactWindowContent();
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
                    Expanded(child: buildWindowContent(window.id)),
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

class _TitleBar extends StatelessWidget {
  final DesktopWindow window;
  final WindowManagerNotifier notifier;
  final Size desktopSize;

  const _TitleBar({required this.window, required this.notifier, required this.desktopSize});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => notifier.moveWindow(window.id, window.position + details.delta, desktopSize),
      onDoubleTap: () => notifier.toggleMaximize(window.id, desktopSize),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Row(
          children: [
            _TrafficLight(color: const Color(0xFFFF5F57), onTap: () => notifier.closeWindow(window.id)),
            const SizedBox(width: 8),
            _TrafficLight(color: const Color(0xFFFEBC2E), onTap: () => notifier.minimizeWindow(window.id)),
            const SizedBox(width: 8),
            _TrafficLight(
              color: const Color(0xFF28C840),
              onTap: () => notifier.toggleMaximize(window.id, desktopSize),
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
  final VoidCallback onTap;
  const _TrafficLight({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final DesktopWindow window;
  final WindowManagerNotifier notifier;
  const _ResizeHandle({required this.window, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        onPanUpdate: (details) => notifier.resizeWindow(
          window.id,
          window.size + Offset(details.delta.dx, details.delta.dy),
        ),
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.all(4),
          child: const Icon(Icons.drag_indicator, size: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
