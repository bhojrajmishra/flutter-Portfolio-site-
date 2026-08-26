import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';

class NavBar extends ConsumerWidget {
  final VoidCallback onAbout;
  final VoidCallback onProjects;
  final VoidCallback onExperience;
  final VoidCallback onContact;

  const NavBar({
    super.key,
    required this.onAbout,
    required this.onProjects,
    required this.onExperience,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);
    final hero = ref.watch(heroProvider).value;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xCC0B0D14),
            border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
          ),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 16),
          child: Row(
            children: [
              Text(
                hero?.name.isNotEmpty == true ? hero!.name : 'Portfolio',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              if (!isMobile) ...[
                _NavLink('About', onAbout),
                _NavLink('Projects', onProjects),
                _NavLink('Experience', onExperience),
                _NavLink('Contact', onContact),
                const SizedBox(width: 8),
              ],
              TextButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
