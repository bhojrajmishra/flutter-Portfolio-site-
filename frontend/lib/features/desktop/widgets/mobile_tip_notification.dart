import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-time "did you know" toast telling desktop visitors this site is
/// also responsive on mobile. Shown once per browser (tracked via
/// SharedPreferences/localStorage), a couple seconds after the desktop
/// finishes loading, and dismissed for good once the visitor taps OK.
class MobileTipNotification extends StatefulWidget {
  const MobileTipNotification({super.key});

  @override
  State<MobileTipNotification> createState() => _MobileTipNotificationState();
}

class _MobileTipNotificationState extends State<MobileTipNotification> {
  static const _seenKey = 'seen_mobile_tip_v1';

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _maybeShow();
  }

  Future<void> _maybeShow() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) == true) return;
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _visible = true);
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.3),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: _visible ? 1 : 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xE62B5FE0), Color(0xE61B3E9C)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Text('💡', style: TextStyle(fontSize: 15)),
                            SizedBox(width: 8),
                            Text(
                              'Did you know?',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 13.5, color: Colors.white, height: 1.4),
                                  children: [
                                    TextSpan(text: 'This portfolio will also look great on '),
                                    TextSpan(text: 'mobile', style: TextStyle(fontWeight: FontWeight.w700)),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _OkButton(onTap: _dismiss),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OkButton extends StatefulWidget {
  final VoidCallback onTap;
  const _OkButton({required this.onTap});

  @override
  State<_OkButton> createState() => _OkButtonState();
}

class _OkButtonState extends State<_OkButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _hovering ? 1 : 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'OK',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1B3E9C)),
          ),
        ),
      ),
    );
  }
}
