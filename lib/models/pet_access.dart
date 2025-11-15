// lib/models/pet_access.dart
class PetAccess {
  final int id;
  final int petId;
  final int userId;
  final DateTime grantedAt;

  PetAccess({
    required this.id,
    required this.petId,
    required this.userId,
    required this.grantedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'userId': userId,
      'grantedAt': grantedAt.toIso8601String(),
    };
  }

  factory PetAccess.fromMap(Map<String, dynamic> map) {
    return PetAccess(
      id: map['id'] as int,
      petId: map['petId'] as int,
      userId: map['userId'] as int,
      grantedAt: DateTime.parse(map['grantedAt'] as String),
    );
  }
}