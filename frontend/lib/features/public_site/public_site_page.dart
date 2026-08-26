import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'widgets/about_section.dart';
import 'widgets/contact_section.dart';
import 'widgets/education_experience_section.dart';
import 'widgets/footer_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/nav_bar.dart';
import 'widgets/projects_section.dart';

/// The public one-pager: Hero -> About/Skills -> Projects -> Experience/Education
/// -> Resume/Contact -> Footer, all content driven live from the backend API.
class PublicSitePage extends ConsumerStatefulWidget {
  const PublicSitePage({super.key});

  @override
  ConsumerState<PublicSitePage> createState() => _PublicSitePageState();
}

class _PublicSitePageState extends ConsumerState<PublicSitePage> {
  final scrollController = ScrollController();
  final aboutKey = GlobalKey();
  final projectsKey = GlobalKey();
  final experienceKey = GlobalKey();
  final contactKey = GlobalKey();

  void scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                SizedBox(height: Breakpoints.isMobile(width) ? 72 : 96),
                HeroSection(onViewProjects: () => scrollTo(projectsKey)),
                AboutSection(key: aboutKey),
                ProjectsSection(key: projectsKey),
                EducationExperienceSection(key: experienceKey),
                ContactSection(key: contactKey),
                const FooterSection(),
              ],
            ),
          ),
          NavBar(
            onAbout: () => scrollTo(aboutKey),
            onProjects: () => scrollTo(projectsKey),
            onExperience: () => scrollTo(experienceKey),
            onContact: () => scrollTo(contactKey),
          ),
        ],
      ),
    );
  }
}
