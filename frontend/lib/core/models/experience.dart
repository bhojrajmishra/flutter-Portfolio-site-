class Experience {
  final int id;
  final String company;
  final String role;
  final DateTime startDate;
  final DateTime? endDate;
  final String description;
  final int sortOrder;

  const Experience({
    required this.id,
    required this.company,
    required this.role,
    required this.startDate,
    this.endDate,
    required this.description,
    required this.sortOrder,
  });

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
        id: json['id'] as int,
        company: json['company'] as String? ?? '',
        role: json['role'] as String? ?? '',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        description: json['description'] as String? ?? '',
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'company': company,
        'role': role,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'description': description,
        'sortOrder': sortOrder,
      };
}
