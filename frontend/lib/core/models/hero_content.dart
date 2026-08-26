class HeroContent {
  final String name;
  final String title;
  final String subtitle;
  final String summary;
  final String? backgroundImageUrl;

  const HeroContent({
    required this.name,
    required this.title,
    required this.subtitle,
    required this.summary,
    this.backgroundImageUrl,
  });

  factory HeroContent.fromJson(Map<String, dynamic> json) => HeroContent(
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        backgroundImageUrl: json['backgroundImageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'subtitle': subtitle,
        'summary': summary,
        'backgroundImageUrl': backgroundImageUrl,
      };

  HeroContent copyWith({
    String? name,
    String? title,
    String? subtitle,
    String? summary,
    String? backgroundImageUrl,
  }) =>
      HeroContent(
        name: name ?? this.name,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        summary: summary ?? this.summary,
        backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      );

  static const empty = HeroContent(name: '', title: '', subtitle: '', summary: '');
}
