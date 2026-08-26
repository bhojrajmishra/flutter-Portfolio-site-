import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/about_content.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

class AboutAdminPage extends ConsumerStatefulWidget {
  const AboutAdminPage({super.key});

  @override
  ConsumerState<AboutAdminPage> createState() => _AboutAdminPageState();
}

class _AboutAdminPageState extends ConsumerState<AboutAdminPage> {
  final _bioController = TextEditingController();
  bool _saving = false;
  bool _loadedOnce = false;

  void _populate(AboutContent about) {
    if (_loadedOnce) return;
    _loadedOnce = true;
    _bioController.text = about.bio;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(portfolioRepositoryProvider).updateAbout(AboutContent(bio: _bioController.text.trim()));
      ref.invalidate(aboutProvider);
      if (mounted) showSnack(context, 'About section saved.');
    } catch (e) {
      if (mounted) showSnack(context, 'Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aboutAsync = ref.watch(aboutProvider);

    return AdminPage(
      title: 'About Section',
      subtitle: 'Your bio, shown alongside your skills.',
      child: aboutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (about) {
          _populate(about);
          return GlassCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 10,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
