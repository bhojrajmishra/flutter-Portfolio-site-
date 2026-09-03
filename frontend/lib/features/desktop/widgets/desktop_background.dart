import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Ambient "motion wallpaper" behind the desktop — a high-resolution photo
/// that slowly zooms and pans (a subtle Ken-Burns effect, the same trick
/// behind macOS's dynamic wallpapers) instead of a static image. A dark
/// scrim sits on top so window chrome, dock icons, and text stay legible
/// over whatever part of the photo is showing.
class DesktopBackground extends StatefulWidget {
  const DesktopBackground({super.key});

  @override
  State<DesktopBackground> createState() => _DesktopBackgroundState();
}

class _DesktopBackgroundState extends State<DesktopBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 26))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Transform.scale(
                scale: 1.08 + 0.07 * t,
                alignment: Alignment(-0.2 + 0.4 * t, -0.15 + 0.1 * t),
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/desktop_bg.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          // Scrim so windows/dock/text stay legible over the photo.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.55),
                  AppColors.background.withValues(alpha: 0.35),
                  AppColors.background.withValues(alpha: 0.65),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
