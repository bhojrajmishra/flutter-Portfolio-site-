import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/blog_post.dart';
import '../../../core/theme/app_theme.dart';

final _dateFormat = DateFormat('MMMM d, yyyy');

/// The "Blog" window: a lightweight browser-style chrome (address bar +
/// back button) around a modern card list of posts, and a Markdown-rendered
/// detail view. Only published posts are shown here — the admin panel
/// shows drafts too.
class BlogWindowContent extends ConsumerStatefulWidget {
  const BlogWindowContent({super.key});

  @override
  ConsumerState<BlogWindowContent> createState() => _BlogWindowContentState();
}

class _BlogWindowContentState extends ConsumerState<BlogWindowContent> {
  BlogPost? _selected;

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(blogPostsProvider);

    return Column(
      children: [
        _AddressBar(
          path: _selected == null ? '/blog' : '/blog/${_selected!.slug}',
          showBack: _selected != null,
          onBack: () => setState(() => _selected = null),
        ),
        Expanded(
          child: postsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Failed to load: $e')),
            data: (posts) {
              final published = posts.where((p) => p.isPublished).toList();
              if (_selected != null) {
                return _PostDetail(post: _selected!);
              }
              return _PostList(
                posts: published,
                onOpen: (post) => setState(() => _selected = post),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddressBar extends StatelessWidget {
  final String path;
  final bool showBack;
  final VoidCallback onBack;
  const _AddressBar({required this.path, required this.showBack, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: showBack ? onBack : null,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'bhojrajmishra.com.np$path',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<BlogPost> posts;
  final ValueChanged<BlogPost> onOpen;
  const _PostList({required this.posts, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(
        child: Text('No posts yet. Add one from the admin panel.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720 ? 2 : 1;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 260,
            ),
            itemBuilder: (context, i) => _PostCard(post: posts[i], onTap: () => onOpen(posts[i])),
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Container(height: 4, decoration: const BoxDecoration(gradient: AppColors.accentGradient)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dateFormat.format(post.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.accentEnd),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        post.excerpt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetail extends StatelessWidget {
  final BlogPost post;
  const _PostDetail({required this.post});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(post.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_dateFormat.format(post.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          MarkdownBody(
            data: post.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.textSecondary),
              h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              h2: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
              h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              listBullet: const TextStyle(color: AppColors.textSecondary),
              code: const TextStyle(
                backgroundColor: AppColors.surface,
                color: AppColors.accentEnd,
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder),
              ),
              blockquoteDecoration: BoxDecoration(
                border: const Border(left: BorderSide(color: AppColors.accentEnd, width: 3)),
                color: AppColors.surface,
              ),
              a: const TextStyle(color: AppColors.accentEnd),
            ),
          ),
        ],
      ),
    );
  }
}
