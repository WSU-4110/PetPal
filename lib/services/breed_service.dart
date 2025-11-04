// lib/services/breed_service.dart
// Small local registry of species -> breeds, breed -> asset path and tips.
// Extend this as you like (or load remotely).

class BreedService {
  // species -> list of breeds (key, displayName)
  static const Map<String, List<Map<String, String>>> speciesBreeds = {
    'Cat': [
      {'key': 'bombay', 'name': 'Bombay'},
      {'key': 'siamese', 'name': 'Siamese'},
      {'key': 'persian', 'name': 'Persian'},
      {'key': 'tabby', 'name': 'Tabby'},
      // add more...
    ],
    'Dog': [
      {'key': 'german_shepherd', 'name': 'German Shepherd'},
      {'key': 'labrador', 'name': 'Labrador Retriever'},
      {'key': 'pug', 'name': 'Pug'},
      {'key': 'beagle', 'name': 'Beagle'},
      // add more...
    ],
    'Rabbit': [
      {'key': 'lop', 'name': 'Lop'},
      {'key': 'dutch', 'name': 'Dutch'},
    ],
    // add more species...
  };

  // breed key -> local asset path (store a representative image in assets/images/breeds/)
  static const Map<String, String> breedImages = {
    'bombay': 'assets/images/breeds/bombay.png',
    'siamese': 'assets/images/breeds/siamese.png',
    'persian': 'assets/images/breeds/persian.png',
    'tabby': 'assets/images/breeds/tabby.png',
    'german_shepherd': 'assets/images/breeds/german_shepherd.png',
    'labrador': 'assets/images/breeds/labrador.png',
    'pug': 'assets/images/breeds/pug.png',
    'beagle': 'assets/images/breeds/beagle.png',
    'lop': 'assets/images/breeds/lop.png',
    'dutch': 'assets/images/breeds/dutch.png',
  };

  // breed key -> quick tips
  static const Map<String, List<String>> breedTips = {
    'bombay': [
      'Bombays are people-oriented — schedule daily cuddle time.',
      'They adapt well to apartments — play indoors frequently.',
    ],
    'german_shepherd': [
      'German Shepherds need daily exercise and mental stimulation.',
      'Consider training classes and long walks.',
    ],
    'labrador': [
      'Labradors are food-motivated — watch portions to avoid weight gain.',
      'Great swimmers — supervise near water.',
    ],
    // ... add for other breeds
  };

  // Helper: get breeds for a species
  static List<Map<String, String>> getBreedsForSpecies(String species) {
    return speciesBreeds[species] ?? [];
  }

  // Helper: get image path for breed key
  static String? getImageForBreedKey(String key) {
    return breedImages[key];
  }

  // Helper: get tips for breed key
  static List<String> getTipsForBreedKey(String key) {
    return breedTips[key] ?? [];
  }
}
