import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../window_manager.dart';

final _clockFormat = DateFormat('EEE MMM d   h:mm a');

/// Top macOS-style menu bar: logo mark, app menus that open windows, a live
/// clock, and a small admin link.
class DesktopMenuBar extends ConsumerStatefulWidget {
  final Size desktopSize;
  const DesktopMenuBar({super.key, required this.desktopSize});

  @override
  ConsumerState<DesktopMenuBar> createState() => _DesktopMenuBarState();
}

class _DesktopMenuBarState extends ConsumerState<DesktopMenuBar> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = ref.watch(heroProvider).value;
    final notifier = ref.read(windowManagerProvider.notifier);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xCC0B0D14),
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Text(
            hero?.name.isNotEmpty == true ? hero!.name : 'Portfolio',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          _MenuItem(label: 'About Me', onTap: () => notifier.openWindow('about', desktopSize: widget.desktopSize)),
          _MenuItem(label: 'Projects', onTap: () => notifier.openWindow('projects', desktopSize: widget.desktopSize)),
          _MenuItem(
              label: 'Experience', onTap: () => notifier.openWindow('experience', desktopSize: widget.desktopSize)),
          _MenuItem(label: 'Contact', onTap: () => notifier.openWindow('contact', desktopSize: widget.desktopSize)),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/admin'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Admin', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Text(_clockFormat.format(_now), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
