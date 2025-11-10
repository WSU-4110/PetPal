// lib/services/breed_service.dart
// A small helper used for tips and breed key normalization.
// We keep this minimal because you already use breeds.json for dropdowns.

class BreedService {
  // breed key -> quick tips (extend this over time)
  // Keys should match the filename-key convention: lowercased, non-alnum -> underscore
  static const Map<String, List<String>> _breedTips = {
    'bombay': [
      'Bombays are people-oriented — schedule daily cuddle time.',
      'Great apartment cats — provide toys & vertical spaces.',
    ],
    'siamese': [
      'Siamese cats are vocal and social — spend time interacting daily.',
      'They need stimulation — puzzle feeders help.',
    ],
    'german_shepherd': [
      'German Shepherds need daily exercise and mental stimulation.',
      'Consider obedience training and consistent routines.',
    ],
    'labrador_retriever': [
      'Labradors love to fetch — regular exercise prevents weight gain.',
      'Watch food portions; they are very food-driven.',
    ],
    // Add more specific breed tips here as you add images/entries.
  };

  // species-level tips (fallbacks)
  static const Map<String, List<String>> _speciesTips = {
    'cat': [
      'Cats like predictable routines — keep feeding times consistent.',
      'Provide scratching posts to protect furniture.',
    ],
    'dog': [
      'Daily walks are essential for a happy dog — aim for at least 30 minutes.',
      'Positive-reinforcement training builds a strong bond.',
    ],
    'rabbit': [
      'Rabbits need chew toys and safe space to hop and explore.',
      'Keep their living area clean and offer hay constantly.',
    ],
    'bird': [
      'Birds are social — provide toys and interaction daily.',
      'Ensure safe items — no toxic houseplants or open water containers.',
    ],
  };

  // General owner tips (fallback)
  static const List<String> generalTips = [
    'Regular vet check-ups keep pets healthy — schedule yearly visits.',
    'Microchip and register your pet in case they get lost.',
    'Keep fresh water available at all times.',
    'Use enrichment (toys, puzzles) to prevent boredom and bad behaviors.',
  ];

  // Normalize a display breed name into a key matching your filename convention:
  // e.g. "Labrador Retriever" -> "labrador_retriever"
  static String breedNameToKey(String breed) {
    return breed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  // Get tips for a breed key; returns empty list if none.
  static List<String> getTipsForBreedKey(String key) {
    return _breedTips[key] ?? [];
  }

  // Get species-level tips (case-insensitive).
  static List<String> getTipsForSpecies(String species) {
    final k = species.toLowerCase().trim();
    return _speciesTips[k] ?? [];
  }

  // Combined tip list for a pet (breed tips first, then species, then general)
  static List<String> getCombinedTipsForPet(String species, String breed) {
    final List<String> result = [];
    final key = breedNameToKey(breed);
    final breedTips = getTipsForBreedKey(key);
    if (breedTips.isNotEmpty) result.addAll(breedTips);
    final speciesTips = getTipsForSpecies(species);
    if (speciesTips.isNotEmpty) result.addAll(speciesTips);
    // always add a couple general tips
    result.addAll(generalTips);
    return result;
  }

  // ----------------------------------------------------------
  // Added lightweight helpers for UI/unit-test compatibility:

  /// Return a lightweight list of breed maps for a species.
  /// This is a minimal fallback and doesn't replace your `breeds.json`.
  static List<Map<String, String>> getBreedsForSpecies(String species) {
    final speciesKey = species.toLowerCase().trim();
    final Map<String, List<String>> defaultBreeds = {
      'cat': ['Bombay', 'Siamese', 'Persian', 'Maine Coon'],
      'dog': ['Labrador Retriever', 'German Shepherd', 'Beagle', 'Poodle'],
      'rabbit': ['Lop', 'Dutch'],
    };

    final breeds = defaultBreeds[speciesKey] ?? ['Other'];
    return breeds.map((b) => {'name': b}).toList();
  }

  /// Return a guess at the asset path for a given normalized key
  static String getImageForBreedKey(String key) {
    final k = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_').trim();
    return 'assets/breeds/$k.png';
  }
}
