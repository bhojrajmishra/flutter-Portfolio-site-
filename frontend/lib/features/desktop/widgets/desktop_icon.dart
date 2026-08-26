import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// One "desktop icon": glyph in a rounded tile, label below, optional badge.
/// Used both for the right-side desktop icon column and the mobile app grid.
class DesktopIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? tileColor;
  final Gradient? tileGradient;

  /// Overrides the icon glyph entirely with custom content (e.g. a live
  /// date display for a calendar-style tile). When set, [icon]/[iconColor]
  /// are ignored.
  final Widget? tileChild;

  const DesktopIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.iconColor,
    this.tileColor,
    this.tileGradient,
    this.tileChild,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: tileGradient == null ? (tileColor ?? const Color(0xCC1A1D29)) : null,
                      gradient: tileGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: tileChild ?? Icon(icon, color: iconColor ?? Colors.white, size: 24),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
