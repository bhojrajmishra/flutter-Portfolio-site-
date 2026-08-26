class ResumeFile {
  final int id;
  final String filename;
  final String url;
  final DateTime uploadedAt;

  const ResumeFile({
    required this.id,
    required this.filename,
    required this.url,
    required this.uploadedAt,
  });

  factory ResumeFile.fromJson(Map<String, dynamic> json) => ResumeFile(
        id: json['id'] as int,
        filename: json['filename'] as String? ?? 'resume.pdf',
        url: json['url'] as String? ?? '',
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );
}
