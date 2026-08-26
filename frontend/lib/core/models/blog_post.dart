class BlogPost {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final String content; // Markdown
  final String? imageUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.content,
    this.imageUrl,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        excerpt: json['excerpt'] as String? ?? '',
        content: json['content'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        isPublished: json['isPublished'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'slug': slug,
        'excerpt': excerpt,
        'content': content,
        'imageUrl': imageUrl,
        'isPublished': isPublished,
      };
}
