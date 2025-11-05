// test/zara_o_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:petpal/models/pet.dart';
import 'package:petpal/state/app_state.dart';
import 'package:petpal/services/breed_service.dart';

void main() {
  group('Pet model', () {
    test('toMap produces expected keys and values', () {
      final pet = Pet(
        id: 42,
        name: 'Koda',
        gender: 'Male',
        species: 'Cat',
        breed: 'Bombay',
        age: 4,
        image: 'cat_bombay.png',
      );

      final map = pet.toMap();
      expect(map['id'], 42);
      expect(map['name'], 'Koda');
      expect(map['gender'], 'Male');
      expect(map['species'], 'Cat');
      expect(map['breed'], 'Bombay');
      expect(map['age'], 4);
      expect(map['image'], 'cat_bombay.png');
    });

    test('fromMap recreates Pet correctly', () {
      final map = {
        'id': 7,
        'name': 'Mittens',
        'gender': 'Female',
        'species': 'Cat',
        'breed': 'Siamese',
        'age': 2,
        'image': 'cat_siamese.png',
      };

      final pet = Pet.fromMap(map);
      expect(pet.id, 7);
      expect(pet.name, 'Mittens');
      expect(pet.gender, 'Female');
      expect(pet.species, 'Cat');
      expect(pet.breed, 'Siamese');
      expect(pet.age, 2);
      expect(pet.image, 'cat_siamese.png');
    });
  });

  group('AppState password helpers', () {
    final appState = AppState();

    test('passwordChecks returns booleans for a strong password', () {
      final checks = appState.passwordChecks('Str0ng!Pass');
      // expected: length, uppercase, lowercase, digit, symbol
      expect(checks.length, 5);
      expect(checks[0], isTrue); // length >= 8
      expect(checks[1], isTrue); // uppercase
      expect(checks[2], isTrue); // lowercase
      expect(checks[3], isTrue); // digit
      expect(checks[4], isTrue); // symbol
    });

    test('isPasswordStrong returns false for weak and true for strong', () {
      expect(appState.isPasswordStrong('weak'), isFalse);
      expect(appState.isPasswordStrong('Better1!'), isTrue);
    });
  });

  group('BreedService helpers', () {
    test('getBreedsForSpecies returns non-empty list for known species', () {
      final catBreeds = BreedService.getBreedsForSpecies('Cat');
      expect(catBreeds, isNotNull);
      expect(catBreeds, isA<List<Map<String, String>>>());
      expect(catBreeds.length, greaterThan(0));
    });

    test('getImageForBreedKey returns path containing key for known breed', () {
      final path = BreedService.getImageForBreedKey('bombay');
      expect(path, isNotNull);
      expect(path, contains('bombay'));
      expect(path, contains('assets'));
    });
  });
}
