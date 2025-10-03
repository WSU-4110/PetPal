class Pet {
  final int? id;
  final String name;
  final String gender;
  final String species;
  final String breed;
  final int age;

  Pet({
    this.id,
    required this.name,
    required this.gender,
    required this.species,
    required this.breed,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'species': species,
      'breed': breed,
      'age': age,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as int?,
      name: map['name'] as String,
      gender: map['gender'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String,
      age: map['age'] as int,
    );
  }
}
