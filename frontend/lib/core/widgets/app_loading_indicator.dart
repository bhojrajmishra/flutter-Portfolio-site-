import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A modern spinner + "LOADING" label, used anywhere dynamic data is being
/// fetched (page content, list views) in place of a bare
/// [CircularProgressIndicator]. Pass [showLabel]: false and a smaller [size]
/// for tight spaces (e.g. a compact card) where the label doesn't fit.
class AppLoadingIndicator extends StatefulWidget {
  final double size;
  final bool showLabel;

  const AppLoadingIndicator({super.key, this.size = 30, this.showLabel = true});

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _controller,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _SpinnerPainter(color: AppColors.textSecondary),
          ),
        ),
        if (widget.showLabel) ...[
          SizedBox(height: widget.size * 0.3),
          Text(
            'LOADING',
            style: TextStyle(
              fontSize: (widget.size * 0.34).clamp(10, 13),
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws the 8-spoke fading "sync" glyph (distinct from Material's circular
/// arc), each spoke fainter than the last to read as motion once rotated.
class _SpinnerPainter extends CustomPainter {
  final Color color;
  const _SpinnerPainter({required this.color});

  static const _spokes = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.42;
    final strokeWidth = size.width * 0.11;

    for (var i = 0; i < _spokes; i++) {
      final angle = (i / _spokes) * 2 * math.pi;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final paint = Paint()
        ..color = color.withValues(alpha: (i + 1) / _spokes)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center + direction * innerRadius, center + direction * outerRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) => oldDelegate.color != color;
}
