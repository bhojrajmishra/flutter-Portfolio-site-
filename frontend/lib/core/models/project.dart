class Project {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> techTags;
  final String? liveUrl;
  final String? repoUrl;
  final bool featured;
  final int sortOrder;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.techTags,
    this.liveUrl,
    this.repoUrl,
    required this.featured,
    required this.sortOrder,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        techTags: (json['techTags'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        liveUrl: json['liveUrl'] as String?,
        repoUrl: json['repoUrl'] as String?,
        featured: json['featured'] as bool? ?? false,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'techTags': techTags,
        'liveUrl': liveUrl,
        'repoUrl': repoUrl,
        'featured': featured,
        'sortOrder': sortOrder,
      };
}
