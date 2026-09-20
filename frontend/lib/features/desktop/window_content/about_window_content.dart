import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';

/// Content shown inside the "About Me" window (and, on mobile, its
/// fullscreen equivalent). Uses [LayoutBuilder] rather than [MediaQuery]
/// since a window is usually much narrower than the full viewport.
class AboutWindowContent extends ConsumerWidget {
  const AboutWindowContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutProvider);
    final skillsAsync = ref.watch(skillsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth > 520;
        final bio = _Panel(
          child: aboutAsync.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, st) => Text('Failed to load: $e'),
            data: (about) => Text(
              about.bio.isNotEmpty ? about.bio : 'Add your bio from the admin panel.',
              style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.textSecondary),
            ),
          ),
        );
        final skills = _Panel(
          child: skillsAsync.when(
            loading: () => const Center(child: AppLoadingIndicator()),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: entry.value
                                    .map((name) => Chip(
                                          label: Text(name, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: AppColors.background,
                                          side: const BorderSide(color: AppColors.glassBorder),
                                          visualDensity: VisualDensity.compact,
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
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: sideBySide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: bio),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: skills),
                    ],
                  ),
                )
              : Column(children: [bio, const SizedBox(height: 16), skills]),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );
  }
}
