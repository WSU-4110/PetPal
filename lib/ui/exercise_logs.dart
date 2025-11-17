import 'package:flutter/material.dart';
import 'package:petpal/ui/add_exercise_log_dialog.dart';
import 'package:petpal/ui/edit_exercise_log_dialog.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/exercise_log.dart';
import '../models/pet.dart';

class ExerciseLogs extends StatefulWidget {
  final int petId;
  final bool isOwner;

  const ExerciseLogs({super.key, required this.petId, this.isOwner = false});

  @override
  State<ExerciseLogs> createState() => _ExerciseLogsPageState();
}

class _ExerciseLogsPageState extends State<ExerciseLogs> {
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
        final pet = pets.firstWhere(
          (p) => p.id == widget.petId,
          orElse: () => pets.first, // Fallback to first pet if not found
        );
        
        if (mounted) {
          setState(() {
            selectedPet = pet;
            _isLoading = false;
          });
          // Load exercise logs for the pet
          await context.read<AppState>().loadExerciseLog(pet.id!);
        }
      } else {
        // No pets available
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.exerciseLogs;

    final bool isOwner = appState.currentUser?['role'] == 'owner';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Exercise Logs",
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
          child: Column(
            children: [
              if (isOwner)
              // Only show dropdown if we have pets and a selected pet
              if (!_isLoading && selectedPet != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<Pet>(
                    value: selectedPet,
                    dropdownColor: Colors.white.withValues(alpha: 0.9),
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
                        context.read<AppState>().loadExerciseLog(p.id!);
                      }
                    },
                  ),
                ),

                // Trainer Access Button
                    if (isOwner)
                    ElevatedButton(
                      onPressed: () async {
                        // FIX: Store context-dependent objects before async gap
                        final buildContext = context;
                        final appStateRead = context.read<AppState>();
                        final messenger = ScaffoldMessenger.of(context);
                        
                        final trainers = await appStateRead.getTrainers();

                        // FIX: Check mounted before using context
                        if (!mounted) return;

                        final selectedTrainer = await showDialog<Map<String, dynamic>>(
                          context: buildContext,
                          builder: (cont) {
                            return SimpleDialog(
                              title: const Text("Select Trainer"),
                              children: trainers.map((trainer)
                              {
                                final fullName = "${trainer['firstName']} ${trainer['lastName']}";
                                return SimpleDialogOption(
                                  onPressed: () => Navigator.pop(cont, trainer),
                                  child: Text(fullName),
                                );
                              }).toList(),
                            );
                          },
                        );

                        if (selectedTrainer != null && selectedPet != null) {
                          await appStateRead.grantAccess(selectedPet!.id!, selectedTrainer['id']);
                          
                          // FIX: Check mounted before showing snackbar
                          if (!mounted) return;
                          
                          messenger.showSnackBar(
                            SnackBar(content: Text("Granted access to ${selectedTrainer['firstName']}")),
                          );
                        }
                      },
                      child: const Text("Grant Trainer Access"),
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
              // No exercise logs
              else if (records.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No Exercise Logs.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              // Exercise logs list
              else
                Expanded(
                  child: ListView.builder(
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
                            "Activity: ${record.activity}\n",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Text(
                            "Observations: ${record.observations}\n\nLength of Activity: ${record.length}\n\nDate and Time: ${record.date}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOwner)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () async {
                                  // FIX: Store context-dependent objects before async gap
                                  final appStateRead = context.read<AppState>();
                                  
                                  final result = await showDialog<ExerciseLog>(
                                    context: context,
                                    builder: (_) => EditExerciseLogDialog(
                                      exerciseLog: record,
                                      pets: appState.pets,
                                    ),
                                  );
                                  
                                  if (result != null) {
                                    await appStateRead.updateExerciseLog(result);
                                  }
                                },
                              ),
                              if (isOwner)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // FIX: Store messenger before async gap
                                  final messenger = ScaffoldMessenger.of(context);
                                  
                                  await appState.deleteExerciseLog(record.id!, record.petId);
                                  
                                  // FIX: Check mounted before showing snackbar
                                  if (!mounted) return;
                                  
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Exercise Log deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: selectedPet != null
          ? Container(
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
                    builder: (_) => AddExerciseLogDialog(petId: selectedPet!.id!),
                  );
                },
                child: const Icon(Icons.add, size: 30, color: Colors.white),
              ),
            )
          : null,
    );
  }
}