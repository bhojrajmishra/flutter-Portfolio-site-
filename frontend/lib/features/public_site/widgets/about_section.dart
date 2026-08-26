import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import 'section_heading.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutProvider);
    final skillsAsync = ref.watch(skillsProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = Breakpoints.isDesktop(width);

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(title: 'About Me'),
          const SizedBox(height: 32),
          Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: GlassCard(
                  child: aboutAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Failed to load: $e'),
                    data: (about) => Text(
                      about.bio.isNotEmpty ? about.bio : 'Add your bio from the admin panel.',
                      style: const TextStyle(fontSize: 16, height: 1.7, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 24),
              Expanded(
                flex: 2,
                child: GlassCard(
                  child: skillsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Failed to load: $e'),
                    data: (skills) {
                      if (skills.isEmpty) {
                        return const Text('Add skills from the admin panel.',
                            style: TextStyle(color: AppColors.textSecondary));
                      }
                      final byCategory = <String, List<String>>{};
                      for (final s in skills) {
                        byCategory.putIfAbsent(s.category, () => []).add(s.name);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: byCategory.entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.key,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: entry.value
                                            .map((name) => Chip(
                                                  label: Text(name),
                                                  backgroundColor: AppColors.glassFill,
                                                  side: const BorderSide(color: AppColors.glassBorder),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
