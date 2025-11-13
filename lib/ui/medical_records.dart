import 'package:flutter/material.dart';
import 'package:petpal/ui/home_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'add_medical_record_dialog.dart';
import 'edit_medical_record_dialog.dart';
import '../models/medical_record.dart';
import '../models/pet.dart';
import 'home_screen.dart';

class MedicalRecordsPage extends StatefulWidget {
  final int petId;
  final bool isOwner;

  const MedicalRecordsPage({super.key, required this.petId, this.isOwner = false});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  late Pet selectedPet;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    // Initialize with a default pet to prevent "No element" error
    _initializeData();
  }

  void _initializeData() async {
    try {
      final pets = context.read<AppState>().pets;
      if (pets.isNotEmpty) {
        // Find the pet with matching ID or use the first pet as fallback
        final pet = pets.firstWhere(
          (p) => p.id == widget.petId,
          orElse: () => pets.first,
        );
        
        if (mounted) {
          setState(() {
            selectedPet = pet;
            _isLoading = false;
          });
          
          // Load medical records for this pet
          await context.read<AppState>().loadMedicalRecords(pet.id!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.medicalRecords;

    final bool isOwner = appState.currentUser?['role'] == 'owner';

    final String? role = appState.currentUser?['role'] as String?;

    if (role != 'vet' && role != 'owner') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Access Denied"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                Navigator.pop(context);
            },
              child: Text("Return Home"),
              ),
            ],
          ),
        ),
      );
    }


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Medical Records",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // Match ReminderListScreen gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Column(
                  children: [
                    //only show if user is not a Vet
                    if (isOwner)
                      DropdownButton<Pet>(
                        value: selectedPet,
                        items: appState.pets
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                            .toList(),
                        onChanged: (p) {
                          if (p != null) {
                            setState(() => selectedPet = p);
                            context.read<AppState>().loadMedicalRecords(p.id!);
                        }
                      },
                    ),

                    // Vet Access Button
                    if (isOwner)
                    ElevatedButton(
                      onPressed: () async {
                        final vets = await context.read<AppState>().getVeterinarians();

                        final selectedVet = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (cont) {
                            return SimpleDialog(
                              title: const Text("Select Vet"),
                              children: vets.map((vet)
                              {
                                final fullName = "${vet['firstName']} ${vet['lastName']}";
                                return SimpleDialogOption(
                                  onPressed: () => Navigator.pop(cont, vet),
                                  child: Text(fullName),
                                );
                              }).toList(),
                            );
                          },
                        );

                        if (selectedVet != null) {
                          await context.read<AppState>().grantAccess(selectedPet.id!, selectedVet['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Granted access to ${selectedVet['firstName']}")),
                          );
                        }
                      },
                      child: const Text("Grant Vet Access"),
                    ),

                    Expanded(
                      child: records.isEmpty
                          ? const Center(
                              child: Text(
                                    "No medical records yet.",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: records.length,
                              itemBuilder: (context, i) {
                                final record = records[i];
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purpleAccent.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      record.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "${record.date} — ${record.vetName}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isOwner)
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white70),
                                          onPressed: () async {
                                            final result = await showDialog<MedicalRecord>(
                                              context: context,
                                              builder: (_) => EditMedicalRecordDialog(
                                                medicalrecord: record,
                                                pets: appState.pets,
                                              ),
                                            );
                                            if (result != null) {
                                              await context.read<AppState>().updateMedicalRecord(result);
                                            }
                                          },
                                        ),
                                        if (isOwner)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () async {
                                            await appState.deleteMedicalRecord(record.id!, record.petId);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Medical record deleted')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Builder(
                                        builder: (BuildContext scaffoldContext) {
                                          if (role == 'vet' || role == 'owner') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MedicalRecordsPage(petId: selectedPet.id!),
                                                ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Access Denied')),
                                          );
                                        }
                                        return const SizedBox();
                                      },  
                                      );
                                    },
                                  ),
                                );
                              },
                        ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AddMedicalRecordDialog(petId: selectedPet.id!),
            );
          },
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
    );
  }
}