import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/auth/login_page.dart';
import '../../features/admin/dashboard/admin_shell.dart';
import '../../features/admin/dashboard/pages/about_admin_page.dart';
import '../../features/admin/dashboard/pages/contact_admin_page.dart';
import '../../features/admin/dashboard/pages/dashboard_home_page.dart';
import '../../features/admin/dashboard/pages/education_admin_page.dart';
import '../../features/admin/dashboard/pages/experience_admin_page.dart';
import '../../features/admin/dashboard/pages/hero_admin_page.dart';
import '../../features/admin/dashboard/pages/projects_admin_page.dart';
import '../../features/admin/dashboard/pages/resume_admin_page.dart';
import '../../features/admin/dashboard/pages/settings_admin_page.dart';
import '../../features/admin/dashboard/pages/skills_admin_page.dart';
import '../../features/admin/dashboard/pages/social_links_admin_page.dart';
import '../../features/desktop/desktop_home_page.dart';
import '../api/auth_controller.dart';

/// Bridges Riverpod auth state changes into a Listenable go_router can use
/// to re-run its redirect logic whenever login state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.loading) return null; // wait for stored token to load

      final loggingIn = state.matchedLocation == '/admin/login';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (isAdminRoute && !loggingIn && !auth.isLoggedIn) return '/admin/login';
      if (loggingIn && auth.isLoggedIn) return '/admin';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DesktopHomePage()),
      GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginPage()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const DashboardHomePage()),
          GoRoute(path: '/admin/hero', builder: (context, state) => const HeroAdminPage()),
          GoRoute(path: '/admin/about', builder: (context, state) => const AboutAdminPage()),
          GoRoute(path: '/admin/projects', builder: (context, state) => const ProjectsAdminPage()),
          GoRoute(path: '/admin/skills', builder: (context, state) => const SkillsAdminPage()),
          GoRoute(
              path: '/admin/experience', builder: (context, state) => const ExperienceAdminPage()),
          GoRoute(path: '/admin/education', builder: (context, state) => const EducationAdminPage()),
          GoRoute(
              path: '/admin/social-links',
              builder: (context, state) => const SocialLinksAdminPage()),
          GoRoute(path: '/admin/resume', builder: (context, state) => const ResumeAdminPage()),
          GoRoute(path: '/admin/contact', builder: (context, state) => const ContactAdminPage()),
          GoRoute(path: '/admin/settings', builder: (context, state) => const SettingsAdminPage()),
        ],
      ),
    ],
  );
});
