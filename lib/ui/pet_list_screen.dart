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

    return Stack(
      children: [
        pets.isEmpty
            ? const Center(child: Text('No pets yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final Pet pet = pets[index];
                  return ListTile(
                    title: Text(pet.name),
                    subtitle: Text('${pet.species} • Age: ${pet.age}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await appState.deletePet(pet.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pet deleted')),
                        );
                      },
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PetFormScreen()));
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
