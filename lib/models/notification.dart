class AppNotification {
  final int? id;
  final String title;
  final String? body;
  final DateTime? scheduledAt;
  final DateTime? deliveredAt;

  AppNotification({
    this.id,
    required this.title,
    this.body,
    this.scheduledAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };

  static AppNotification fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] as int?,
    title: map['title'] as String,
    body: map['body'] as String?,
    scheduledAt: map['scheduledAt'] != null
        ? DateTime.parse(map['scheduledAt'])
        : null,
    deliveredAt: map['deliveredAt'] != null
        ? DateTime.parse(map['deliveredAt'])
        : null,
  );
}