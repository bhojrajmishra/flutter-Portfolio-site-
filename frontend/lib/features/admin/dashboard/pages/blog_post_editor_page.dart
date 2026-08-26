import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/blog_post.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';
import '../../widgets/file_pick_helpers.dart';

/// Create/edit form for a blog post. [postId] is null when creating a new
/// post, or an existing post's id when editing (looked up from the
/// already-loaded [blogPostsProvider] list — no separate single-post
/// endpoint needed).
class BlogPostEditorPage extends ConsumerStatefulWidget {
  final int? postId;
  const BlogPostEditorPage({super.key, this.postId});

  @override
  ConsumerState<BlogPostEditorPage> createState() => _BlogPostEditorPageState();
}

class _BlogPostEditorPageState extends ConsumerState<BlogPostEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  String? _imageUrl;
  bool _isPublished = true;
  bool _saving = false;
  bool _uploading = false;
  bool _previewing = false;
  bool _loadedOnce = false;
  bool _slugTouched = false;

  bool get _isEditing => widget.postId != null;

  void _populate(BlogPost post) {
    if (_loadedOnce) return;
    _loadedOnce = true;
    _titleController.text = post.title;
    _slugController.text = post.slug;
    _excerptController.text = post.excerpt;
    _contentController.text = post.content;
    _imageUrl = post.imageUrl;
    _isPublished = post.isPublished;
    _slugTouched = true;
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _pickImage() async {
    final picked = await pickFileBytes(type: FileType.image);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(portfolioRepositoryProvider).uploadImage(picked.bytes, picked.name);
      setState(() => _imageUrl = url);
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
      final post = BlogPost(
        id: widget.postId ?? 0,
        title: _titleController.text.trim(),
        slug: _slugController.text.trim().isEmpty
            ? _slugify(_titleController.text.trim())
            : _slugController.text.trim(),
        excerpt: _excerptController.text.trim(),
        content: _contentController.text,
        imageUrl: _imageUrl,
        isPublished: _isPublished,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final repo = ref.read(portfolioRepositoryProvider);
      if (_isEditing) {
        await repo.updateBlogPost(widget.postId!, post);
      } else {
        await repo.createBlogPost(post);
      }
      ref.invalidate(blogPostsProvider);
      if (mounted) {
        showSnack(context, 'Post saved.');
        context.go('/admin/blog');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(blogPostsProvider);

    Widget form(BlogPost? existing) {
      if (existing != null) _populate(existing);
      return GlassCard(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (v) {
                    if (!_slugTouched) _slugController.text = _slugify(v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _slugController,
                  decoration: const InputDecoration(labelText: 'URL slug', helperText: 'e.g. how-i-built-this-site'),
                  onChanged: (_) => _slugTouched = true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _excerptController,
                  decoration: const InputDecoration(labelText: 'Excerpt (short summary shown on the card)'),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickImage,
                      icon: _uploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.image_outlined),
                      label: const Text('Cover Image'),
                    ),
                    const SizedBox(width: 12),
                    if (_imageUrl != null)
                      Expanded(child: Text(_imageUrl!, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Content (Markdown)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ToggleButtons(
                      isSelected: [!_previewing, _previewing],
                      onPressed: (i) => setState(() => _previewing = i == 1),
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 72),
                      children: const [Text('Edit'), Text('Preview')],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_previewing)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 240),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: MarkdownBody(data: _contentController.text.isEmpty ? '*Nothing yet.*' : _contentController.text),
                  )
                else
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: '## Heading\n\nWrite your post in Markdown — **bold**, *italic*, lists, `code`, > quotes...',
                    ),
                    maxLines: 16,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v ?? true),
                  title: const Text('Published (visible in the public Blog window)'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(onPressed: () => context.go('/admin/blog'), child: const Text('Cancel')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AdminPage(
      title: _isEditing ? 'Edit Post' : 'New Post',
      child: _isEditing
          ? postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Failed to load: $e'),
              data: (posts) {
                final matches = posts.where((p) => p.id == widget.postId);
                final existing = matches.isEmpty ? null : matches.first;
                if (existing == null) {
                  return const Text('Post not found.', style: TextStyle(color: AppColors.textSecondary));
                }
                return form(existing);
              },
            )
          : form(null),
    );
  }
}
