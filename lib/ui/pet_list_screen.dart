// lib/ui/pet_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet.dart';
import 'pet_form_screen.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pets = appState.pets;

    return Scaffold(
      appBar: AppBar(title: const Text('Pets')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: pets.isEmpty
              ? const Center(
                  child: Text(
                    'No pets yet',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final Pet pet = pets[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(pet),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pet.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                    '${pet.breed} • ${pet.species} • Age: ${pet.age}',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () async {
                                  // Navigate to PetFormScreen in edit mode
                                  final updatedPet = await Navigator.push<Pet>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PetFormScreen(
                                        pet: pet,
                                      ),
                                    ),
                                  );

                                  // If pet was updated, save it
                                  if (updatedPet != null) {
                                    await appState.updatePet(updatedPet);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await appState.deletePet(pet.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Pet deleted')));
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PetFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAvatar(Pet pet) {
    final image = pet.image;

    // No image → show default paw placeholder
    if (image == null || image.isEmpty) {
      return const CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white24,
        child: Icon(Icons.pets, color: Colors.white70),
      );
    }

    // Network image
    if (image.startsWith('http')) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white24,
        backgroundImage: NetworkImage(image),
      );
    }

    // Asset image (already has correct path)
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white24,
      backgroundImage: AssetImage(image),
    );
  }
}
