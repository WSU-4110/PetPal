import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'pet_form_screen.dart';
import '../models/pet.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Profiles'),
      ),
      body: ListView.builder(
        itemCount: appState.pets.length,
        itemBuilder: (context, index) {
          final Pet pet = appState.pets[index];
          return ListTile(
            title: Text(pet.name),
            subtitle: Text('${pet.species} • Age: ${pet.age}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await appState.deletePet(pet.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet deleted')));
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PetFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
