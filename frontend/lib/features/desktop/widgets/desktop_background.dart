import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Abstract flowing-gradient "wallpaper" behind the desktop — inspired by
/// the soft ribbon-style wallpapers common on modern desktop OSes, painted
/// from scratch (not a copy of any specific OS's actual wallpaper asset).
class DesktopBackground extends StatelessWidget {
  const DesktopBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: CustomPaint(
        painter: _RibbonPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void ribbon(Path path, List<Color> colors, double opacity, double strokeWidth) {
      final fadedColors = colors.map((c) => c.withValues(alpha: opacity)).toList();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: fadedColors).createShader(Rect.fromLTWH(0, 0, w, h))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawPath(path, paint);
    }

    Path curve(double y0, double c1y, double c2y, double y1) {
      return Path()
        ..moveTo(-w * 0.2, h * y0)
        ..cubicTo(w * 0.25, h * c1y, w * 0.55, h * c2y, w * 1.2, h * y1);
    }

    ribbon(
      curve(0.15, 0.55, -0.05, 0.65),
      [AppColors.accentStart, AppColors.accentEnd],
      0.10,
      160,
    );
    ribbon(
      curve(0.55, 0.15, 0.85, 0.35),
      [AppColors.accentEnd, AppColors.accentStart],
      0.08,
      140,
    );
    ribbon(
      curve(0.85, 1.05, 0.55, 1.15),
      [AppColors.accentStart, AppColors.accentEnd],
      0.07,
      180,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
