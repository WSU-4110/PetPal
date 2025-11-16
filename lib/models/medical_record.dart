// lib/models/medical_record.dart

class MedicalRecord {
  final int? id;
  final int petId;
  final String title;
  final String? description;
  final DateTime date;           // THIS MUST BE DateTime, NOT String!
  final String? vetName;
  final double? weight;           // ADD THIS FIELD
  final String? status;           // ADD THIS FIELD

  MedicalRecord({
    this.id,
    required this.petId,
    required this.title,
    this.description,
    required this.date,
    this.vetName,
    this.weight,                  // ADD THIS
    this.status,                  // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),    // Convert DateTime to String for storage
      'vetName': vetName,
      'weight': weight,                   // ADD THIS
      'status': status,                   // ADD THIS
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] as int?,
      petId: map['petId'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),  // Parse String back to DateTime
      vetName: map['vetName'] as String?,
      weight: map['weight'] as double?,              // ADD THIS
      status: map['status'] as String?,              // ADD THIS
    );
  }

  // Add copyWith method for easier updates
  MedicalRecord copyWith({
    int? id,
    int? petId,
    String? title,
    String? description,
    DateTime? date,
    String? vetName,
    double? weight,
    String? status,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      vetName: vetName ?? this.vetName,
      weight: weight ?? this.weight,
      status: status ?? this.status,
    );
  }
}