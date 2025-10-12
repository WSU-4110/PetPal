import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet_builder.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PetBuilder petBuilder = PetBuilder(); // ✅ Use the Builder here

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => petBuilder.setName(v?.trim() ?? ''),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Gender'),
                onSaved: (v) => petBuilder.setGender(v?.trim() ?? ''),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter the gender' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Species'),
                onSaved: (v) => petBuilder.setSpecies(v?.trim() ?? ''),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter species' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Breed'),
                onSaved: (v) => petBuilder.setBreed(v?.trim() ?? ''),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter breed' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onSaved: (v) =>
                    petBuilder.setAge(int.tryParse(v ?? '0') ?? 0),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  // ✅ Build the Pet using the Builder Pattern
                  final pet = petBuilder.build();

                  await appState.addPet(pet);
                  Navigator.pop(context);
                },
                child: const Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
