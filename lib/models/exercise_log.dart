class ExerciseLog {
  final int? id;
  final int petId;
  final String length;
  final String activity;
  final String observations; 
  final String date;         

  ExerciseLog({
    this.id,
    required this.petId,
    required this.length,
    required this.activity,
    required this.observations,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'length': length,
      'activity': activity,
      'observations': observations,
      'date': date,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'],
      petId: map['petId'],
      length: map['length'],
      activity: map['activity'],
      observations: map['observations'],
      date: map['date'],
    );
  }
}
