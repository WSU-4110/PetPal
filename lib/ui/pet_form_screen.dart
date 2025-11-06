// lib/ui/pet_form_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? pet; // <-- optional for editing

  const PetFormScreen({super.key, this.pet});

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

  Map<String, List<String>> _breedOptions = {};
  List<String> _speciesOptions = [];

  @override
  void initState() {
    super.initState();
    _loadBreeds();

    // Pre-fill values if editing
    if (widget.pet != null) {
      final p = widget.pet!;
      _name = p.name;
      _gender = p.gender;
      _species = p.species;
      _breed = p.breed;
      _customBreed = (p.breed == 'Other') ? '' : '';
      _age = p.age;
    }
  }

  Future<void> _loadBreeds() async {
    try {
      final data = await rootBundle.loadString('assets/breeds.json');
      final decoded = json.decode(data) as Map<String, dynamic>;

      setState(() {
        _breedOptions = decoded.map((key, value) => MapEntry(
            key, (value as List<dynamic>).map((e) => e.toString()).toList()));
        _speciesOptions = _breedOptions.keys.toList();
      });
    } catch (e) {
      setState(() {
        _breedOptions = {'Other': ['Other']};
        _speciesOptions = ['Other'];
      });
    }
  }

  List<String> get _currentBreedList {
    if (_species == null) return [];
    return _breedOptions[_species!] ?? ['Other'];
  }

  bool get _showCustomBreedField {
    return _breed == 'Other' ||
        (_breed != null && _breed!.trim().isEmpty && _species == 'Other');
  }

  String _imageFor(String? species, String? breed) {
    if (species == null || breed == null) return 'assets/breeds/petlogo.png';
    final usedBreed = (breed == 'Other' && _customBreed.isNotEmpty)
        ? _customBreed
        : breed;
    return Pet.imageFor(species, usedBreed);
  }

  Widget _buildPreviewImage() {
    final imgPath = _imageFor(_species, _breed);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        height: 140,
        color: Colors.white.withValues(alpha: 0.06),
        child: Image.asset(
          imgPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset('assets/breeds/petlogo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }

  Future<void> _openSelector({
    required String title,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) async {
    if (items.isEmpty) return;
    if (!mounted) return;
    
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return GestureDetector(
          onTap: () => Navigator.of(c).pop(),
          behavior: HitTestBehavior.opaque,
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (_, controller) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Scrollbar(
                        controller: controller,
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(8),
                        child: ListView.builder(
                          controller: controller,
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final it = items[i];
                            final isSelected = it == currentValue;
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(it,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                                trailing: isSelected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                                onTap: () => Navigator.of(c).pop(it),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) onSelected(selected);
  }

  Widget _selectorField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required VoidCallback onTap,
  }) {
    final displayText = (value == null || value.isEmpty) ? 'Select $label' : value;
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: _buildInputDecoration(label, icon),
        child: Row(
          children: [
            Expanded(
                child: Text(displayText,
                    style: TextStyle(
                        color: (value == null || value.isEmpty)
                            ? Colors.white54
                            : Colors.white))),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
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
        title: Text(widget.pet != null ? 'Edit Pet' : 'Add Pet'),
        backgroundColor: Colors.white,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildPreviewImage(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _name,
                          decoration: _buildInputDecoration('Name', Icons.pets),
                          style: const TextStyle(color: Colors.white),
                          onSaved: (v) => _name = v?.trim() ?? '',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter a name'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _gender,
                    decoration: _buildInputDecoration('Gender', Icons.male),
                    style: const TextStyle(color: Colors.white),
                    onSaved: (v) => _gender = v?.trim() ?? 'Unknown',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Enter the gender'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Species selector
                  _selectorField(
                    label: 'Species',
                    icon: Icons.nature,
                    value: _species,
                    items: _speciesOptions,
                    onTap: () => _openSelector(
                      title: 'Choose species',
                      items: _speciesOptions,
                      currentValue: _species,
                      onSelected: (val) {
                        setState(() {
                          _species = val;
                          _breed = null;
                          _customBreed = '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Breed selector
                  _selectorField(
                    label: 'Breed',
                    icon: Icons.category,
                    value: _breed,
                    items: _currentBreedList,
                    onTap: () => _openSelector(
                      title: 'Choose breed',
                      items: _currentBreedList,
                      currentValue: _breed,
                      onSelected: (val) {
                        setState(() {
                          _breed = val;
                          if (val != 'Other') _customBreed = '';
                        });
                      },
                    ),
                  ),
                  if (_showCustomBreedField) const SizedBox(height: 12),
                  if (_showCustomBreedField)
                    TextFormField(
                      initialValue: _customBreed,
                      decoration: _buildInputDecoration('Custom breed', Icons.edit),
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
                  TextFormField(
                    initialValue: _age.toString(),
                    decoration: _buildInputDecoration('Age', Icons.cake),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _age = int.tryParse(v ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();

                      final finalBreed = (_breed == 'Other'
                          ? (_customBreed.isNotEmpty ? _customBreed : 'Other')
                          : (_breed ?? 'Other'));
                      final imgPath = _imageFor(_species, finalBreed);

                      final petToSave = Pet(
                        id: widget.pet?.id, // preserve ID if editing
                        name: _name,
                        gender: _gender,
                        species: _species ?? 'Other',
                        breed: finalBreed,
                        age: _age,
                        image: imgPath,
                      );

                      if (widget.pet != null) {
                        // Editing: return updated pet
                        if (!mounted) return;
                        if (context.mounted) {
                          Navigator.of(context).pop(petToSave);
                        }
                      } else {
                        // Adding new
                        await appState.addPet(petToSave);
                        if (!mounted) return;
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
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
                            color: Colors.pinkAccent.withValues(alpha: 0.5),
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
                                offset: Offset(1, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}