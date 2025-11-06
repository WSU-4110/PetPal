class GroomLog {
  final int? id;
  final int petId;
  final String type;
  final String description;
  final String maintenance;
  final String date;         

  GroomLog({
    this.id,
    required this.petId,
    required this.type,
    required this.description,
    required this.maintenance,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'length': type,
      'activity': description,
      'observations': maintenance,
      'date': date,
    };
  }

  factory GroomLog.fromMap(Map<String, dynamic> map) {
    return GroomLog(
      id: map['id'],
      petId: map['petId'],
      type: map['type'],
      description: map['description'],
      maintenance: map['maintenance'],
      date: map['date'],
    );
  }
}
