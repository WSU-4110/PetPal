class Reminder {
  final int? id;
  final int petId;
  final String title;
  final String category; // e.g., "Feeding", "Medication", "Vet"
  final DateTime scheduledAt;
  final bool done;

  Reminder({
    this.id,
    required this.petId,
    required this.title,
    required this.category,
    required this.scheduledAt,
    this.done = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'category': category,
      'scheduledAt': scheduledAt.toIso8601String(),
      'done': done ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      petId: map['petId'] as int,
      title: map['title'] as String,
      category: map['category'] as String,
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      done: (map['done'] as int) == 1,
    );
  }
}
