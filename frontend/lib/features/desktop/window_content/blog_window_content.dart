import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/blog_post.dart';
import '../../../core/theme/app_theme.dart';

final _dateFormat = DateFormat('MMMM d, yyyy');

/// The "Blog" window: a modern card list of posts and a clean, minimalist
/// Markdown-rendered reading view — no browser-style chrome (no fake
/// address bar), so nothing competes with the content. Only published
/// posts are shown here — the admin panel shows drafts too.
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

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Failed to load: $e')),
      data: (posts) {
        final published = posts.where((p) => p.isPublished).toList();
        if (_selected != null) {
          return _PostDetail(post: _selected!, onBack: () => setState(() => _selected = null));
        }
        return _PostList(
          posts: published,
          onOpen: (post) => setState(() => _selected = post),
        );
      },
    );
  }
}

/// Rough reading time estimate from plain word count (~200 wpm), purely
/// cosmetic — no backend field for this.
int _readingMinutes(String content) {
  final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return (words / 200).ceil().clamp(1, 999);
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
        final width = constraints.maxWidth;
        final columns = width > 1100 ? 3 : (width > 680 ? 2 : 1);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'From the blog',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${posts.length} ${posts.length == 1 ? 'post' : 'posts'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: 320,
                ),
                itemBuilder: (context, i) => _PostCard(post: posts[i], onTap: () => onOpen(posts[i])),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostCard extends StatefulWidget {
  final BlogPost post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _hovering ? AppColors.accentEnd.withValues(alpha: 0.6) : AppColors.glassBorder),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: AppColors.accentStart.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                      Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.background,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(gradient: AppColors.accentGradient),
                        alignment: Alignment.center,
                        child: const Icon(Icons.article_outlined, color: Colors.white, size: 32),
                      ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _Pill(text: _dateFormat.format(post.createdAt)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          post.excerpt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 13, color: AppColors.accentEnd),
                          const SizedBox(width: 4),
                          Text(
                            '${_readingMinutes(post.content)} min read',
                            style: const TextStyle(fontSize: 12, color: AppColors.accentEnd, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 180),
                            offset: _hovering ? Offset.zero : const Offset(-0.3, 0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _hovering ? 1 : 0,
                              child: const Icon(Icons.arrow_forward, size: 15, color: AppColors.accentEnd),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatefulWidget {
  final VoidCallback onTap;
  const _BackLink({required this.onTap});

  @override
  State<_BackLink> createState() => _BackLinkState();
}

class _BackLinkState extends State<_BackLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 15, color: _hovering ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Blog',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _hovering ? Colors.white : AppColors.textSecondary,
                decoration: _hovering ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _PostDetail extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onBack;
  const _PostDetail({required this.post, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackLink(onTap: onBack),
              const SizedBox(height: 20),
              Text(
                'ARTICLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.accentEnd.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(_dateFormat.format(post.createdAt),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('${_readingMinutes(post.content)} min read',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 8,
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              MarkdownBody(
                data: post.content,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16.5, height: 1.85, color: AppColors.textSecondary, letterSpacing: 0.1),
                  h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.6),
                  h2: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, height: 1.8),
                  h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.8),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  listBullet: const TextStyle(color: AppColors.textSecondary, height: 1.85),
                  blockSpacing: 18,
                  code: const TextStyle(
                    backgroundColor: AppColors.surface,
                    color: AppColors.accentEnd,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  codeblockPadding: const EdgeInsets.all(14),
                  blockquoteDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(left: BorderSide(color: AppColors.accentEnd, width: 3)),
                    color: AppColors.surface,
                  ),
                  blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  a: const TextStyle(color: AppColors.accentEnd, decoration: TextDecoration.underline),
                  horizontalRuleDecoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.glassBorder)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
