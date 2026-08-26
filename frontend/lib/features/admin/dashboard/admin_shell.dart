import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_controller.dart';
import '../../../core/theme/app_theme.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}

const _navItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined, '/admin'),
  _NavItem('Hero', Icons.badge_outlined, '/admin/hero'),
  _NavItem('About', Icons.person_outline, '/admin/about'),
  _NavItem('Skills', Icons.psychology_outlined, '/admin/skills'),
  _NavItem('Projects', Icons.work_outline, '/admin/projects'),
  _NavItem('Experience', Icons.timeline_outlined, '/admin/experience'),
  _NavItem('Education', Icons.school_outlined, '/admin/education'),
  _NavItem('Social Links', Icons.link, '/admin/social-links'),
  _NavItem('Resume', Icons.description_outlined, '/admin/resume'),
  _NavItem('Messages', Icons.mail_outline, '/admin/contact'),
];

/// Sidebar + content shell wrapping every /admin/* route once logged in.
class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);
    final currentPath = GoRouterState.of(context).matchedLocation;

    final sidebar = _Sidebar(currentPath: currentPath);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.surface,
              title: const Text('Admin'),
            )
          : null,
      drawer: isMobile ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          if (!isMobile)
            SizedBox(
              width: 240,
              child: sidebar,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String currentPath;
  const _Sidebar({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Portfolio Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _navItems
                  .map((item) => ListTile(
                        leading: Icon(item.icon,
                            color: currentPath == item.path ? AppColors.accentEnd : AppColors.textSecondary),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: currentPath == item.path ? Colors.white : AppColors.textSecondary,
                            fontWeight: currentPath == item.path ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: currentPath == item.path,
                        selectedTileColor: AppColors.glassFill,
                        onTap: () => context.go(item.path),
                      ))
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new, color: AppColors.textSecondary),
            title: const Text('View Site'),
            onTap: () => context.go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.textSecondary),
            title: const Text('Log Out'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
