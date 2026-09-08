/// Keep in sync with backend/src/routes/apps.ts's `APP_CATEGORIES` — the
/// upload form's dropdown must offer exactly this list, since the backend
/// rejects anything else.
const appCategories = <String>[
  'Productivity',
  'Utilities',
  'Tools',
  'Business',
  'Education',
  'Entertainment',
  'Social',
  'Health & Fitness',
  'Lifestyle',
  'Other',
];

/// One app in the App Store window — the backend holds every published
/// app as its own row (not just a single "latest upload" slot), so the
/// store is a real, browsable, multi-app listing.
class AppListing {
  final int id;
  final String name;
  final String category;
  final String? description;
  final String? versionLabel;
  final String filename;
  final String url;
  final int? sizeBytes;
  final DateTime uploadedAt;

  const AppListing({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.versionLabel,
    required this.filename,
    required this.url,
    this.sizeBytes,
    required this.uploadedAt,
  });

  factory AppListing.fromJson(Map<String, dynamic> json) => AppListing(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'App',
        category: json['category'] as String? ?? 'Other',
        description: json['description'] as String?,
        versionLabel: json['versionLabel'] as String?,
        filename: json['filename'] as String? ?? 'app.apk',
        url: json['url'] as String? ?? '',
        sizeBytes: json['sizeBytes'] as int?,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      );
}
