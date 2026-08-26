import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/social_link.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

const _suggestedPlatforms = [
  'github',
  'linkedin',
  'pubdev',
  'twitter',
  'instagram',
  'youtube',
  'buymeacoffee',
  'email',
  'website',
];

class SocialLinksAdminPage extends ConsumerWidget {
  const SocialLinksAdminPage({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {SocialLink? existing}) async {
    final platformController = TextEditingController(text: existing?.platform ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');
    final badgeController = TextEditingController(text: existing?.badgeText ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Social Link' : 'Edit Social Link'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: platformController,
                  enabled: existing == null,
                  decoration: const InputDecoration(labelText: 'Platform (e.g. github, linkedin)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (Uri.tryParse(v.trim())?.hasScheme != true) return 'Include http(s):// or mailto:';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: badgeController,
                  decoration: const InputDecoration(
                    labelText: 'Badge (optional, e.g. "25+" repos, "5K+" connections)',
                    helperText: "Your own real number — shown as-is on the icon. Leave blank for none.",
                  ),
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

    final badgeText = badgeController.text.trim();
    await ref.read(portfolioRepositoryProvider).upsertSocialLink(
          platformController.text.trim().toLowerCase(),
          urlController.text.trim(),
          badgeText: badgeText.isEmpty ? null : badgeText,
        );
    ref.invalidate(socialLinksProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, SocialLink link) async {
    final confirmed = await confirmDelete(context, itemLabel: link.platform);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteSocialLink(link.platform);
    ref.invalidate(socialLinksProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(socialLinksProvider);

    return AdminPage(
      title: 'Social Links',
      subtitle: 'Shown in the hero and footer. Suggested: ${_suggestedPlatforms.join(', ')}.',
      action: ElevatedButton.icon(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Link'),
      ),
      child: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (links) {
          if (links.isEmpty) {
            return const Text('No social links yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: links
                .map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(l.platform, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (l.badgeText != null && l.badgeText!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(l.badgeText!, style: const TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(l.url,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openForm(context, ref, existing: l),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, l),
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
