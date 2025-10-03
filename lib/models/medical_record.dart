class MedicalRecord {
  final int? id;
  final int petId;
  final String title;        // e.g. "Vaccination", "Checkup"
  final String description;  // details of the record
  final String date;         // ISO string or yyyy-MM-dd
  final String vetName;      // optional: which vet/clinic

  MedicalRecord({
    this.id,
    required this.petId,
    required this.title,
    required this.description,
    required this.date,
    required this.vetName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'description': description,
      'date': date,
      'vetName': vetName,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'],
      petId: map['petId'],
      title: map['title'],
      description: map['description'],
      date: map['date'],
      vetName: map['vetName'],
    );
  }
}
