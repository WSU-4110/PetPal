class Pet {
  final int? id;
  final String name;
  final String species;
  final int age;

  Pet({
    this.id,
    required this.name,
    required this.species,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'age': age,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as int?,
      name: map['name'] as String,
      species: map['species'] as String,
      age: map['age'] as int,
    );
  }
}
