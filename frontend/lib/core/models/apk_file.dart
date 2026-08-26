class ApkFile {
  final int id;
  final String filename;
  final String? versionLabel;
  final String url;
  final DateTime uploadedAt;

  const ApkFile({
    required this.id,
    required this.filename,
    this.versionLabel,
    required this.url,
    required this.uploadedAt,
  });

  factory ApkFile.fromJson(Map<String, dynamic> json) => ApkFile(
        id: json['id'] as int,
        filename: json['filename'] as String? ?? 'app.apk',
        versionLabel: json['versionLabel'] as String?,
        url: json['url'] as String? ?? '',
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );
}
