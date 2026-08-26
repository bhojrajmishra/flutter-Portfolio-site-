import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import 'section_heading.dart';

final _monthYear = DateFormat('MMM yyyy');

String _range(DateTime start, DateTime? end) {
  final startStr = _monthYear.format(start);
  final endStr = end != null ? _monthYear.format(end) : 'Present';
  return '$startStr — $endStr';
}

class EducationExperienceSection extends ConsumerWidget {
  const EducationExperienceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experienceAsync = ref.watch(experienceProvider);
    final educationAsync = ref.watch(educationProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = Breakpoints.isDesktop(width);

    return SectionContainer(
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(title: 'Experience'),
                const SizedBox(height: 24),
                experienceAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
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
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 32 : 0, height: isDesktop ? 0 : 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(title: 'Education'),
                const SizedBox(height: 24),
                educationAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
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
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.accentEnd)),
            const SizedBox(height: 4),
            Text(range, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description!, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
