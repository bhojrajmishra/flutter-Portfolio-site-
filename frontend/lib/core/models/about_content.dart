class AboutContent {
  final String bio;

  const AboutContent({required this.bio});

  factory AboutContent.fromJson(Map<String, dynamic> json) =>
      AboutContent(bio: json['bio'] as String? ?? '');

  Map<String, dynamic> toJson() => {'bio': bio};

  static const empty = AboutContent(bio: '');
}
