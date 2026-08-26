import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_page.dart';

class DashboardHomePage extends ConsumerWidget {
  const DashboardHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value?.length;
    final skills = ref.watch(skillsProvider).value?.length;
    final experience = ref.watch(experienceProvider).value?.length;
    final messages = ref.watch(contactMessagesProvider).value;
    final unread = messages?.where((m) => !m.isRead).length;

    return AdminPage(
      title: 'Dashboard',
      subtitle: 'Overview of your portfolio content.',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatCard(label: 'Projects', value: projects),
          _StatCard(label: 'Skills', value: skills),
          _StatCard(label: 'Experience Entries', value: experience),
          _StatCard(label: 'Unread Messages', value: unread, highlight: (unread ?? 0) > 0),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int? value;
  final bool highlight;
  const _StatCard({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              value?.toString() ?? '—',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.accentEnd : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
