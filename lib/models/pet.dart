// lib/models/pet.dart
class Pet {
  final int? id;
  final String name;
  final String gender;
  final String species;
  final String breed;
  final int age;
  final String? image; // asset path or remote URL
  final DateTime? birthdate; // new optional birthdate

  Pet({
    this.id,
    required this.name,
    required this.gender,
    required this.species,
    required this.breed,
    required this.age,
    this.image,
    this.birthdate,
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
      // store ISO8601 string or null
      'birthdate': birthdate?.toIso8601String(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    // Safely parse age from either int or string-like values
    final dynamic rawAge = map['age'];
    final int parsedAge = rawAge is int
        ? rawAge
        : int.tryParse(rawAge?.toString() ?? '') ?? 0;

    DateTime? parsedBirthdate;
    final dynamic rawBirth = map['birthdate'];
    if (rawBirth != null) {
      try {
        parsedBirthdate = DateTime.parse(rawBirth.toString());
      } catch (_) {
        parsedBirthdate = null;
      }
    }

    return Pet(
      id: map['id'] as int?,
      name: (map['name'] ?? '').toString(),
      gender: (map['gender'] ?? '').toString(),
      species: (map['species'] ?? '').toString(),
      breed: (map['breed'] ?? '').toString(),
      age: parsedAge,
      image: map['image'] as String?,
      birthdate: parsedBirthdate,
    );
  }

  /// Helper: returns the expected asset image path for this pet
  /// Example: species="Cat", breed="Bombay" -> assets/breeds/cat_bombay.png
  static String imageFor(String species, String breed) {
    if (species.trim().isEmpty || breed.trim().isEmpty) {
      return 'assets/breeds/petlogo.png';
    }

    final s = species.toLowerCase().replaceAll(RegExp(r'\s+'), '_').trim();
    var b = breed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').trim();

    if (b.isEmpty) b = 'petlogo';
    // use braces for `s` because it's followed immediately by an underscore
    return 'assets/breeds/${s}_$b.png';
  }
}
