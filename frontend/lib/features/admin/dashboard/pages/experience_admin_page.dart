import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/experience.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class ExperienceAdminPage extends ConsumerWidget {
  const ExperienceAdminPage({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Experience? existing}) async {
    final companyController = TextEditingController(text: existing?.company ?? '');
    final roleController = TextEditingController(text: existing?.role ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    DateTime? startDate = existing?.startDate;
    DateTime? endDate = existing?.endDate;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Experience' : 'Edit Experience'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: companyController,
                      decoration: const InputDecoration(labelText: 'Company'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: roleController,
                      decoration: const InputDecoration(labelText: 'Role'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: 'Start date',
                            value: startDate,
                            onChanged: (d) => setDialogState(() => startDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: 'End date (blank = present)',
                            value: endDate,
                            onChanged: (d) => setDialogState(() => endDate = d),
                            clearable: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (startDate == null) {
                  showSnack(context, 'Start date is required', isError: true);
                  return;
                }
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || startDate == null) return;

    final repo = ref.read(portfolioRepositoryProvider);
    final entry = Experience(
      id: existing?.id ?? 0,
      company: companyController.text.trim(),
      role: roleController.text.trim(),
      startDate: startDate!,
      endDate: endDate,
      description: descriptionController.text.trim(),
      sortOrder: existing?.sortOrder ?? 0,
    );
    if (existing == null) {
      await repo.createExperience(entry);
    } else {
      await repo.updateExperience(entry);
    }
    ref.invalidate(experienceProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Experience entry) async {
    final confirmed = await confirmDelete(context, itemLabel: entry.role);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteExperience(entry.id);
    ref.invalidate(experienceProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experienceAsync = ref.watch(experienceProvider);

    return AdminPage(
      title: 'Experience',
      subtitle: 'Your work history timeline.',
      action: ElevatedButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Experience'),
      ),
      child: experienceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (items) {
          if (items.isEmpty) {
            return const Text('No experience entries yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: items
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${e.role} — ${e.company}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_dateFormat.format(e.startDate)} to ${e.endDate != null ? _dateFormat.format(e.endDate!) : 'Present'}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(e.description, style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openForm(context, ref, existing: e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, e),
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool clearable;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.clearable = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: clearable && value != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => onChanged(null))
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value != null ? _dateFormat.format(value!) : ''),
      ),
    );
  }
}
