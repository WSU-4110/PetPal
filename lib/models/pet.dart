// lib/models/pet.dart
class Pet {
  final int? id;
  final String name;
  final String gender;
  final String species;
  final String breed;
  final int age;
  final String? image; // asset path or remote URL

  Pet({
    this.id,
    required this.name,
    required this.gender,
    required this.species,
    required this.breed,
    required this.age,
    this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'species': species,
      'breed': breed,
      'age': age,
      'image': image,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as int?,
      name: map['name'] as String,
      gender: map['gender'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String,
      age: map['age'] is int ? map['age'] as int : int.tryParse('${map['age']}') ?? 0,
      image: map['image'] as String?,
    );
  }

  /// Helper: returns the expected asset image path for this pet
  static String imageFor(String species, String breed) {
    if (species.isEmpty || breed.isEmpty) return 'assets/breeds/petlogo.png';

    String s = species.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    String b = breed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    if (b.isEmpty) b = 'petlogo';
    return 'assets/breeds/${s}_${b}.png';
  }
}
