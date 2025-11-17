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

class _PetFormScreenState extends State<PetFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form values
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController(); // changed to controller
  String? _species;
  String? _breed;
  String _customBreed = '';
  final TextEditingController _ageController = TextEditingController();
  DateTime? _birthdate; // <-- new optional birthdate field

  Map<String, List<String>> _breedOptions = {};
  List<String> _speciesOptions = [];

  // Animation controllers
  late AnimationController _imageAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  // Flag to track if animations are initialized
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations immediately
    _initializeAnimations();
    
    // Then load breeds
    _loadBreeds();

    // Pre-fill values if editing
    if (widget.pet != null) {
      final p = widget.pet!;
      _nameController.text = p.name;
      _genderController.text = p.gender;
      _species = p.species;
      _breed = p.breed;
      _customBreed = (p.breed == 'Other') ? '' : '';
      _ageController.text = p.age.toString();
      _birthdate = p.birthdate;
    } else {
      // defaults for new pet
      _genderController.text = ''; // empty so hint shows "Unknown"
      _ageController.text = '0';
    }
  }
  
  void _initializeAnimations() {
    _imageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _imageAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _imageAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    
    // Mark as initialized
    setState(() {
      _animationsInitialized = true;
    });
  }

  @override
  void dispose() {
    if (_animationsInitialized) {
      _imageAnimationController.dispose();
      _pulseAnimationController.dispose();
    }
    _nameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    super.dispose();
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
    
    // Return a simple container if animations aren't initialized yet
    if (!_animationsInitialized) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imgPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/breeds/petlogo.png', fit: BoxFit.cover),
          ),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: () {
                // Add a pulse effect when tapped
                _imageAnimationController.reset();
                _imageAnimationController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background decoration
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              center: Alignment.center,
                              radius: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Pet image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        imgPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/breeds/petlogo.png', fit: BoxFit.cover),
                      ),
                    ),
                    
                    // Shimmer effect
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedOpacity(
                          opacity: 0.3,
                          duration: const Duration(milliseconds: 1500),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                transform: GradientRotation(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Pulse effect border
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            margin: EdgeInsets.all(4 * (_pulseAnimation.value - 1.0)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  Future<void> _pickBirthdate() async {
    final initial = _birthdate ?? DateTime.now();
    final first = DateTime(1900);
    final last = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() => _birthdate = picked);
    }
  }

  String _formatBirthdate(DateTime? dt) {
    if (dt == null) return 'Optional: set birthdate';
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.pet != null ? 'Edit Pet' : 'Add Pet',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildPreviewImage(),
                      const SizedBox(height: 24),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration('Name', Icons.pets),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Enter a name'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Gender - now a editable textbox with hint 'Unknown'
                      TextFormField(
                        controller: _genderController,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          hintText: 'Unknown',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          prefixIcon: const Icon(Icons.male, color: Colors.white70),
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
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSaved: (v) {},
                        // no validator - optional
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

                      // Age
                      TextFormField(
                        controller: _ageController,
                        decoration: _buildInputDecoration('Age', Icons.cake),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 16),

                      // Birthdate (optional) field
                      GestureDetector(
                        onTap: _pickBirthdate,
                        child: InputDecorator(
                          decoration: _buildInputDecoration('Birthdate (optional)', Icons.calendar_today),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatBirthdate(_birthdate),
                                  style: TextStyle(
                                    color: _birthdate == null ? Colors.white54 : Colors.white,
                                  ),
                                ),
                              ),
                              if (_birthdate != null)
                                GestureDetector(
                                  onTap: () {
                                    // clear birthdate
                                    setState(() => _birthdate = null);
                                  },
                                  child: const Icon(Icons.close, color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () async {
                          if (!_formKey.currentState!.validate()) return;
                          // save values from controllers
                          final name = _nameController.text.trim();
                          final gender = _genderController.text.trim().isEmpty ? 'Unknown' : _genderController.text.trim();
                          final age = int.tryParse(_ageController.text.trim()) ?? 0;

                          final finalBreed = (_breed == 'Other'
                              ? (_customBreed.isNotEmpty ? _customBreed : 'Other')
                              : (_breed ?? 'Other'));
                          final imgPath = _imageFor(_species, finalBreed);

                          final petToSave = Pet(
                            id: widget.pet?.id, // preserve ID if editing
                            name: name,
                            gender: gender,
                            species: _species ?? 'Other',
                            breed: finalBreed,
                            age: age,
                            image: imgPath,
                            birthdate: _birthdate, // <-- save birthdate
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
        ),
      ),
    );
  }
}