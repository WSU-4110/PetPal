// lib/models/pet_access.dart
class PetAccess {
  final int petId;
  final int userId;

  PetAccess({
    required this.petId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'userId': userId,
    };
  }

  factory PetAccess.fromMap(Map<String, dynamic> map) {
    return PetAccess(
      petId: map['petId'] ?? map['pet_id'] as int,
      userId: map['userId'] ?? map['user_id'] as int,
    );
  }
}