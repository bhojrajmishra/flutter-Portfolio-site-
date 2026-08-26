import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import 'social_links_row.dart';

class HeroSection extends ConsumerWidget {
  final VoidCallback onViewProjects;
  const HeroSection({super.key, required this.onViewProjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroAsync = ref.watch(heroProvider);
    final resumeAsync = ref.watch(resumeProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);

    return SectionContainer(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 48 : 96),
      child: heroAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, st) => Text('Could not load content: $err'),
        data: (hero) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Soft accent glow behind the content.
              Positioned(
                top: -80,
                child: Opacity(
                  opacity: 0.18,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    hero.title.isNotEmpty ? hero.title : 'Software Engineer',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isMobile ? 14 : 16,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hero.name.isNotEmpty ? hero.name : 'Your Name',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 40 : 64,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(
                      hero.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 18, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(onPressed: onViewProjects, child: const Text('View Projects')),
                      resumeAsync.maybeWhen(
                        data: (resume) => resume != null
                            ? OutlinedButton.icon(
                                onPressed: () => launchUrl(Uri.parse(resume.url), webOnlyWindowName: '_blank'),
                                icon: const Icon(Icons.download_outlined),
                                label: const Text('Resume'),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SocialLinksRow(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
