class PetAccess {
  final int petId;
  final int userId;

  PetAccess({
    required this.petId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'pet_id': petId,
      'user_id': userId,
    };
  }

  factory PetAccess.fromMap(Map<String, dynamic> map) {
    return PetAccess(
      petId: map['pet_id'],
      userId: map['user_id'],
    );
  }
}
