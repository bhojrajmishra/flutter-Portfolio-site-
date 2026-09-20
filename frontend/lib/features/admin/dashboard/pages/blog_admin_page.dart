import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/blog_post.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

final _dateFormat = DateFormat('MMM d, yyyy');

class BlogAdminPage extends ConsumerWidget {
  const BlogAdminPage({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, BlogPost post) async {
    final confirmed = await confirmDelete(context, itemLabel: post.title);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteBlogPost(post.id);
    ref.invalidate(blogPostsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(blogPostsProvider);

    return AdminPage(
      title: 'Blog',
      subtitle: 'Shown in the "Blog" window on the public site. Unpublished posts stay hidden there.',
      action: ElevatedButton.icon(
        onPressed: () => context.go('/admin/blog/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
      child: postsAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (posts) {
          if (posts.isEmpty) {
            return const Text('No posts yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: posts
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (!p.isPublished) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade700,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('Draft', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_dateFormat.format(p.createdAt)} · /blog/${p.slug}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => context.go('/admin/blog/${p.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, p),
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
