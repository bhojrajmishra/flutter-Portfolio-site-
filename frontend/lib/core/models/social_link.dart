class SocialLink {
  final int id;
  final String platform;
  final String url;
  final String? badgeText;

  const SocialLink({required this.id, required this.platform, required this.url, this.badgeText});

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        id: json['id'] as int,
        platform: json['platform'] as String? ?? '',
        url: json['url'] as String? ?? '',
        badgeText: json['badgeText'] as String?,
      );
}
