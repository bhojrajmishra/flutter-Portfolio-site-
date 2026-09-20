import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';

final _monthYear = DateFormat('MMM yyyy');

String _range(DateTime start, DateTime? end) {
  final startStr = _monthYear.format(start);
  final endStr = end != null ? _monthYear.format(end) : 'Present';
  return '$startStr — $endStr';
}

class ExperienceWindowContent extends ConsumerWidget {
  const ExperienceWindowContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experienceAsync = ref.watch(experienceProvider);
    final educationAsync = ref.watch(educationProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth > 560;

        final experience = _Column(
          title: 'Experience',
          child: experienceAsync.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, st) => Text('Failed to load: $e'),
            data: (items) => items.isEmpty
                ? const Text('Add experience from the admin panel.',
                    style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: items
                        .map((e) => _TimelineCard(
                              title: e.role,
                              subtitle: e.company,
                              range: _range(e.startDate, e.endDate),
                              description: e.description,
                            ))
                        .toList(),
                  ),
          ),
        );

        final education = _Column(
          title: 'Education',
          child: educationAsync.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (e, st) => Text('Failed to load: $e'),
            data: (items) => items.isEmpty
                ? const Text('Add education from the admin panel.',
                    style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: items
                        .map((e) => _TimelineCard(
                              title: e.degree,
                              subtitle: e.school,
                              range: _range(e.startDate, e.endDate),
                            ))
                        .toList(),
                  ),
          ),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: sideBySide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: experience),
                    const SizedBox(width: 20),
                    Expanded(child: education),
                  ],
                )
              : Column(children: [experience, const SizedBox(height: 20), education]),
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final Widget child;
  const _Column({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String range;
  final String? description;

  const _TimelineCard({
    required this.title,
    required this.subtitle,
    required this.range,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.accentEnd, fontSize: 13)),
            const SizedBox(height: 4),
            Text(range, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description!,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
