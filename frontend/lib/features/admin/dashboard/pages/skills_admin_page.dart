import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/skill.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

class SkillsAdminPage extends ConsumerWidget {
  const SkillsAdminPage({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Skill? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? 'General');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Skill' : 'Edit Skill'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Skill name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category (e.g. Languages, Backend)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final repo = ref.read(portfolioRepositoryProvider);
    final skill = Skill(
      id: existing?.id ?? 0,
      name: nameController.text.trim(),
      category: categoryController.text.trim().isEmpty ? 'General' : categoryController.text.trim(),
      sortOrder: existing?.sortOrder ?? 0,
    );
    if (existing == null) {
      await repo.createSkill(skill);
    } else {
      await repo.updateSkill(skill);
    }
    ref.invalidate(skillsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Skill skill) async {
    final confirmed = await confirmDelete(context, itemLabel: skill.name);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteSkill(skill.id);
    ref.invalidate(skillsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return AdminPage(
      title: 'Skills',
      subtitle: 'Shown in the About section, grouped by category.',
      action: ElevatedButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
      ),
      child: skillsAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (skills) {
          if (skills.isEmpty) {
            return const Text('No skills yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: skills
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(s.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openForm(context, ref, existing: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, s),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
