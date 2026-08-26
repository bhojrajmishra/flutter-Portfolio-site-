import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/education.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class EducationAdminPage extends ConsumerWidget {
  const EducationAdminPage({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Education? existing}) async {
    final schoolController = TextEditingController(text: existing?.school ?? '');
    final degreeController = TextEditingController(text: existing?.degree ?? '');
    DateTime? startDate = existing?.startDate;
    DateTime? endDate = existing?.endDate;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Education' : 'Edit Education'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: schoolController,
                    decoration: const InputDecoration(labelText: 'School'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: degreeController,
                    decoration: const InputDecoration(labelText: 'Degree'),
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
                ],
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
    final entry = Education(
      id: existing?.id ?? 0,
      school: schoolController.text.trim(),
      degree: degreeController.text.trim(),
      startDate: startDate!,
      endDate: endDate,
      sortOrder: existing?.sortOrder ?? 0,
    );
    if (existing == null) {
      await repo.createEducation(entry);
    } else {
      await repo.updateEducation(entry);
    }
    ref.invalidate(educationProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Education entry) async {
    final confirmed = await confirmDelete(context, itemLabel: entry.degree);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteEducation(entry.id);
    ref.invalidate(educationProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final educationAsync = ref.watch(educationProvider);

    return AdminPage(
      title: 'Education',
      subtitle: 'Your academic background.',
      action: ElevatedButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Education'),
      ),
      child: educationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (items) {
          if (items.isEmpty) {
            return const Text('No education entries yet.', style: TextStyle(color: AppColors.textSecondary));
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
                                  Text('${e.degree} — ${e.school}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_dateFormat.format(e.startDate)} to ${e.endDate != null ? _dateFormat.format(e.endDate!) : 'Present'}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
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
