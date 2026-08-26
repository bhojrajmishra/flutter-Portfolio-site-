class ContactMessage {
  final int id;
  final String name;
  final String email;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) => ContactMessage(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}
