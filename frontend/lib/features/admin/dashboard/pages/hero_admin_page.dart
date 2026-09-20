import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/hero_content.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';
import '../../widgets/file_pick_helpers.dart';

class HeroAdminPage extends ConsumerStatefulWidget {
  const HeroAdminPage({super.key});

  @override
  ConsumerState<HeroAdminPage> createState() => _HeroAdminPageState();
}

class _HeroAdminPageState extends ConsumerState<HeroAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _summaryController = TextEditingController();
  String? _backgroundImageUrl;
  bool _saving = false;
  bool _uploading = false;
  bool _loadedOnce = false;

  void _populate(HeroContent hero) {
    if (_loadedOnce) return;
    _loadedOnce = true;
    _nameController.text = hero.name;
    _titleController.text = hero.title;
    _subtitleController.text = hero.subtitle;
    _summaryController.text = hero.summary;
    _backgroundImageUrl = hero.backgroundImageUrl;
  }

  Future<void> _pickImage() async {
    final picked = await pickFileBytes(type: FileType.image);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(portfolioRepositoryProvider).uploadImage(picked.bytes, picked.name);
      setState(() => _backgroundImageUrl = url);
    } catch (e) {
      if (mounted) showSnack(context, 'Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(portfolioRepositoryProvider).updateHero(HeroContent(
            name: _nameController.text.trim(),
            title: _titleController.text.trim(),
            subtitle: _subtitleController.text.trim(),
            summary: _summaryController.text.trim(),
            backgroundImageUrl: _backgroundImageUrl,
          ));
      ref.invalidate(heroProvider);
      if (mounted) showSnack(context, 'Hero section saved.');
    } catch (e) {
      if (mounted) showSnack(context, 'Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroAsync = ref.watch(heroProvider);

    return AdminPage(
      title: 'Hero Section',
      subtitle: 'The intro visitors see first.',
      child: heroAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (hero) {
          _populate(hero);
          return GlassCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title (e.g. Senior Flutter Engineer)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle'),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(labelText: 'Summary'),
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploading ? null : _pickImage,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.image_outlined),
                          label: const Text('Background Image'),
                        ),
                        const SizedBox(width: 12),
                        if (_backgroundImageUrl != null)
                          Expanded(
                              child: Text(_backgroundImageUrl!,
                                  overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
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
            ),
          );
        },
      ),
    );
  }
}
