class Education {
  final int id;
  final String school;
  final String degree;
  final DateTime startDate;
  final DateTime? endDate;
  final int sortOrder;

  const Education({
    required this.id,
    required this.school,
    required this.degree,
    required this.startDate,
    this.endDate,
    required this.sortOrder,
  });

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        id: json['id'] as int,
        school: json['school'] as String? ?? '',
        degree: json['degree'] as String? ?? '',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'school': school,
        'degree': degree,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'sortOrder': sortOrder,
      };
}
