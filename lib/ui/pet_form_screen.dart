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
  String name = '';
  String gender = '';
  String species = '';
  String breed = '';
  int age = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add Pet'),
        backgroundColor: Colors.purpleAccent.shade100,
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
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.pets, color: Colors.white70),
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
                    onSaved: (v) => name = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 16),
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
                    onSaved: (v) => gender = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the gender' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Species',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.nature, color: Colors.white70),
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
                    onSaved: (v) => species = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter species' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Breed',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      prefixIcon: const Icon(Icons.category, color: Colors.white70),
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
                    onSaved: (v) => breed = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter breed' : null,
                  ),
                  const SizedBox(height: 16),
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
                    onSaved: (v) => age = int.tryParse(v ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () async {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();
                      final pet = Pet(
                        name: name,
                        gender: gender,
                        species: species,
                        breed: breed,
                        age: age,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
