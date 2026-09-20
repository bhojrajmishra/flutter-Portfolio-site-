import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/contact_message.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

class ContactAdminPage extends ConsumerWidget {
  const ContactAdminPage({super.key});

  Future<void> _markRead(WidgetRef ref, ContactMessage message) async {
    if (message.isRead) return;
    await ref.read(portfolioRepositoryProvider).markContactMessageRead(message.id);
    ref.invalidate(contactMessagesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ContactMessage message) async {
    final confirmed = await confirmDelete(context, itemLabel: 'message from ${message.name}');
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteContactMessage(message.id);
    ref.invalidate(contactMessagesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(contactMessagesProvider);

    return AdminPage(
      title: 'Messages',
      subtitle: 'Submissions from your public contact form.',
      child: messagesAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (messages) {
          if (messages.isEmpty) {
            return const Text('No messages yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: messages
                .map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: InkWell(
                          onTap: () => _markRead(ref, m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (!m.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(
                                          color: AppColors.accentEnd, shape: BoxShape.circle),
                                    ),
                                  Expanded(
                                    child: Text('${m.name} <${m.email}>',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Text(_dateFormat.format(m.createdAt),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    onPressed: () => _delete(context, ref, m),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(m.message, style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
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
