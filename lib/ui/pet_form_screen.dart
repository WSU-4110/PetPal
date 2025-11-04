// lib/ui/pet_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  String _name = '';
  String _gender = 'Unknown';
  String? _species;
  String? _breed;
  String _customBreed = '';
  int _age = 0;

  // Breed lists per species
  static const Map<String, List<String>> _breedOptions = {
    'Cat': [
      'Bombay',
      'Siamese',
      'Maine Coon',
      'Domestic Shorthair',
      'Other'
    ],
    'Dog': [
      'German Shepherd',
      'Labrador Retriever',
      'Golden Retriever',
      'Beagle',
      'Other'
    ],
    'Bird': [
      'Parakeet',
      'Cockatiel',
      'Canary',
      'Other'
    ],
    'Rabbit': [
      'Lionhead',
      'Dutch',
      'Mini Lop',
      'Other'
    ],
    'Other': ['Other'],
  };

  // species dropdown options (keep this short & friendly)
  static final List<String> _speciesOptions = _breedOptions.keys.toList();

  // helpers
  List<String> get _currentBreedList {
    if (_species == null) return [];
    return _breedOptions[_species!] ?? ['Other'];
  }

  bool get _showCustomBreedField {
    return _breed == 'Other' || (_breed != null && _breed!.trim().isEmpty && _species == 'Other');
  }

  // Build asset path for preview image. Convention:
  // assets/images/breeds/{species_lower}_{breed_lower_underscored}.png
  // e.g. assets/images/breeds/cat_bombay.png
  // If file missing, fallback to placeholder.
  String _imageFor(String? species, String? breed) {
    if (species == null || breed == null) {
      return 'assets/images/breeds/placeholder.png';
    }

    // use custom breed when provided
    final usedBreed = (breed == 'Other' && _customBreed.isNotEmpty) ? _customBreed : breed;

    String s = species.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    String b = usedBreed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    // guard: if the user typed a weird custom breed, keep only letters/numbers/underscores
    if (b.isEmpty) b = 'placeholder';

    return 'assets/images/breeds/${s}_${b}.png';
  }

  // Local helper to check if an asset exists at runtime isn't trivial without package support,
  // so we try to load the expected asset and show Image.asset. If asset is missing the framework
  // will show a little error placeholder in debug — that's why we recommend dropping a
  // fallback placeholder at assets/images/breeds/placeholder.png
  Widget _buildPreviewImage() {
    final imgPath = _imageFor(_species, _breed);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        height: 140,
        color: Colors.white.withOpacity(0.06),
        child: Image.asset(
          imgPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // fallback UI if asset not found at runtime
            return Image.asset('assets/images/breeds/placeholder.png', fit: BoxFit.cover);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add Pet'),
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // preview + name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildPreviewImage(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Name',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            prefixIcon: const Icon(Icons.pets, color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.7)),
                            ),
                            labelStyle: const TextStyle(color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          initialValue: '',
                          onSaved: (v) => _name = v?.trim() ?? '',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Gender (still text for now but you can change to dropdown)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.male, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
                      ),
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSaved: (v) => _gender = v?.trim() ?? 'Unknown',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter the gender' : null,
                  ),

                  const SizedBox(height: 16),

                  // Species dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Species',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.nature, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _species,
                        hint: const Text('Select species', style: TextStyle(color: Colors.white70)),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: _speciesOptions.map((s) {
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _species = val;
                            // reset breed whenever species changes
                            _breed = null;
                            _customBreed = '';
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Breed dropdown (depends on species)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Breed',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.category, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _breed,
                        hint: const Text('Select breed', style: TextStyle(color: Colors.white70)),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: _currentBreedList.map((b) {
                          return DropdownMenuItem<String>(value: b, child: Text(b));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _breed = val;
                            // if breed changed and not Other, clear custom breed
                            if (val != 'Other') _customBreed = '';
                          });
                        },
                      ),
                    ),
                  ),

                  // Custom breed input only when user picks "Other"
                  if (_showCustomBreedField) const SizedBox(height: 12),
                  if (_showCustomBreedField)
                    TextFormField(
                      controller: TextEditingController(text: _customBreed),
                      decoration: InputDecoration(
                        labelText: 'Custom breed',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        prefixIcon: const Icon(Icons.edit, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLength: 40,
                      onChanged: (v) => setState(() => _customBreed = v.trim()),
                      validator: (v) {
                        if (_showCustomBreedField) {
                          return (v == null || v.trim().isEmpty)
                              ? 'Please enter the custom breed'
                              : null;
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 16),

                  // Age
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Age',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.cake, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
                      ),
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _age = int.tryParse(v ?? '0') ?? 0,
                  ),

                  const SizedBox(height: 28),

                  // Save button
                  GestureDetector(
                    onTap: () async {
                      // validate
                      if (!_formKey.currentState!.validate()) return;

                      // save form values
                      _formKey.currentState!.save();

                      // final selected breed text (custom if used)
                      final finalBreed = (_breed == 'Other' ? (_customBreed.isNotEmpty ? _customBreed : 'Other') : (_breed ?? 'Other'));

                      final pet = Pet(
                        name: _name,
                        gender: _gender,
                        species: _species ?? 'Other',
                        breed: finalBreed,
                        age: _age,
                      );

                      await appState.addPet(pet);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Save Pet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black26,
                              offset: Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Small instructions + asset naming reminder for devs
                  const Text(
                    'Tip for devs: place breed images in assets/images/breeds/ named like "cat_bombay.png". '
                    'If missing, placeholder.png will be used.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
