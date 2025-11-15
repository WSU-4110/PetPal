// lib/models/appointment.dart

class Appointment {
  final int? id;
  final int petId;
  final int vetId;
  final String vetName;
  final String clinicName;
  final DateTime dateTime;
  final String type;
  final String status; // 'upcoming', 'completed', 'cancelled'
  final String? notes;

  Appointment({
    this.id,
    required this.petId,
    required this.vetId,
    required this.vetName,
    required this.clinicName,
    required this.dateTime,
    required this.type,
    this.status = 'upcoming',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'vetId': vetId,
      'vetName': vetName,
      'clinicName': clinicName,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
      'status': status,
      'notes': notes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as int?,
      petId: map['petId'] as int,
      vetId: map['vetId'] as int,
      vetName: map['vetName'] as String,
      clinicName: map['clinicName'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      type: map['type'] as String,
      status: map['status'] as String? ?? 'upcoming',
      notes: map['notes'] as String?,
    );
  }

  Appointment copyWith({
    int? id,
    int? petId,
    int? vetId,
    String? vetName,
    String? clinicName,
    DateTime? dateTime,
    String? type,
    String? status,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      vetId: vetId ?? this.vetId,
      vetName: vetName ?? this.vetName,
      clinicName: clinicName ?? this.clinicName,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}