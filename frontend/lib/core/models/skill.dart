class Skill {
  final int id;
  final String name;
  final String category;
  final int sortOrder;

  const Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.sortOrder,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'sortOrder': sortOrder,
      };
}
