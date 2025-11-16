import 'package:flutter/material.dart';
import 'package:petpal/ui/add_groom_log_dialog.dart';
import 'package:petpal/ui/edit_groom_log_dialog.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/groom_log.dart';
import '../models/pet.dart';

class GroomLogs extends StatefulWidget {
  final int petId;
  final bool isOwner;

  const GroomLogs({super.key, required this.petId, this.isOwner = false});

  @override
  State<GroomLogs> createState() => _GroomLogsPageState();
}

class _GroomLogsPageState extends State<GroomLogs> {
  Pet? selectedPet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPetAndLogs();
  }

  void _loadPetAndLogs() async {
    try {
      final pets = context.read<AppState>().pets;
      if (pets.isNotEmpty) {
        // Try to find the pet with the given ID
        Pet pet;
        if (widget.petId != null) {
          try {
            pet = pets.firstWhere((p) => p.id == widget.petId);
          } catch (e) {
            // If pet with widget.petId is not found, use the first pet
            pet = pets.first;
          }
        } else {
          // If no petId is provided, use the first pet
          pet = pets.first;
        }
        
        if (mounted) {
          setState(() {
            selectedPet = pet;
            _isLoading = false;
          });
          // Load grooming logs for the pet
          await context.read<AppState>().loadGroomLog(pet.id!);
        }
      } else {
        // No pets available
        if (mounted) {
          setState(() {
            selectedPet = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        setState(() {
          selectedPet = null;
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to handle pet list updates
  void _updateSelectedPet() {
    final pets = context.read<AppState>().pets;
    if (pets.isEmpty) {
      setState(() {
        selectedPet = null;
      });
      return;
    }
    
    // Check if selectedPet is still in the pets list
    if (selectedPet != null && !pets.any((p) => p.id == selectedPet!.id)) {
      // If not, select the first pet
      setState(() {
        selectedPet = pets.first;
      });
      // Load logs for the newly selected pet
      context.read<AppState>().loadGroomLog(selectedPet!.id!);
    }
  }

  // Helper method to get pet name from ID
  String _getPetName(int petId, AppState appState) {
    try {
      final pet = appState.pets.firstWhere((p) => p.id == petId);
      return pet.name;
    } catch (e) {
      return 'Unknown Pet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.groomLogs;

    // Update selectedPet when pets list changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedPet();
    });

    final bool isOwner = appState.currentUser?['role'] == 'owner';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Grooming Logs",
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (isOwner)
                // Only show dropdown if we have pets and a selected pet
                if (!_isLoading && selectedPet != null && appState.pets.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<Pet>(
                      value: selectedPet,
                      dropdownColor: Colors.white.withOpacity(0.9),
                      items: appState.pets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.name,
                                  style: const TextStyle(color: Color(0xFFB892F7)),
                                ),
                              ))
                          .toList(),
                      onChanged: (p) {
                        if (p != null) {
                          setState(() => selectedPet = p);
                          context.read<AppState>().loadGroomLog(p.id!);
                        }
                      },
                    ),
                  ),

              // Groom Access Button
              if (isOwner && selectedPet != null)
                ElevatedButton(
                  onPressed: () async {
                    final groomers = await context.read<AppState>().getGroomers();

                    final selectedGroomer = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (cont) {
                        return SimpleDialog(
                          title: const Text("Select Groomer"),
                          children: groomers.map((groomer) {
                            final fullName = "${groomer['firstName']} ${groomer['lastName']}";
                            return SimpleDialogOption(
                              onPressed: () => Navigator.pop(cont, groomer),
                              child: Text(fullName),
                            );
                          }).toList(),
                        );
                      },
                    );

                    if (selectedGroomer != null) {
                      await context.read<AppState>().grantAccess(selectedPet!.id!, selectedGroomer['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Granted access to ${selectedGroomer['firstName']}")),
                      );
                    }
                  },
                  child: const Text("Grant Groomer Access"),
                ),

              // Loading indicator
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              // No pets available
              else if (appState.pets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No pets available. Add a pet first!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              // No grooming logs
              else if (records.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No Grooming Logs.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              // Grooming logs list
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, i) {
                      final record = records[i];
                      final petName = _getPetName(record.petId, appState);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pet name badge at the top
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pets, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    petName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Main content
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "Title: ${record.type}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Description: ${record.description}\n\nMaintenance: ${record.maintenance}\n\nDate and Time: ${record.date}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white70),
                                      onPressed: () async {
                                        final result = await showDialog<GroomLog>(
                                          context: context,
                                          builder: (_) => EditGroomLogDialog(
                                            groomLog: record,
                                            pets: appState.pets,
                                          ),
                                        );
                                        if (result != null) {
                                          await context.read<AppState>().updateGroomLog(result);
                                        }
                                      },
                                    ),
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await appState.deleteGroomLog(record.id!, record.petId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Grooming Log deleted')),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      // FAB removed - handled by main.dart navigation
    );
  }
}