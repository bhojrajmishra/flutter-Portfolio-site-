class SocialLink {
  final int id;
  final String platform;
  final String url;

  const SocialLink({required this.id, required this.platform, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        id: json['id'] as int,
        platform: json['platform'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}
