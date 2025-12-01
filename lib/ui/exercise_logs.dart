// ui/exercise_logs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/exercise_log.dart';
import '../models/pet.dart';
import 'add_exercise_log_dialog.dart'; // Unified dialog for add/edit

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

  Future<void> _loadPetAndLogs() async {
    try {
      final pets = context.read<AppState>().pets;
      if (pets.isNotEmpty) {
        final pet = pets.firstWhere(
          (p) => p.id == widget.petId,
          orElse: () => pets.first,
        );

        if (!mounted) return;
        setState(() {
          selectedPet = pet;
          _isLoading = false;
        });

        await context.read<AppState>().loadExerciseLog(pet.id!);
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _updateSelectedPet() {
    final pets = context.read<AppState>().pets;
    if (pets.isEmpty) {
      setState(() => selectedPet = null);
      return;
    }

    if (selectedPet != null && !pets.any((p) => p.id == selectedPet!.id)) {
      setState(() => selectedPet = pets.first);
      context.read<AppState>().loadExerciseLog(selectedPet!.id!);
    }
  }

  String _getPetName(int petId, AppState appState) {
    try {
      return appState.pets.firstWhere((p) => p.id == petId).name;
    } catch (_) {
      return 'Unknown Pet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.exerciseLogs;
    final bool isOwner = appState.currentUser?['role'] == 'owner';

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSelectedPet());

    final int alpha20 = (0.2 * 255).round();
    final int alpha90 = (0.9 * 255).round();

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
              if (isOwner && !_isLoading && selectedPet != null && appState.pets.isNotEmpty)
                _buildPetDropdown(appState, alpha20, alpha90),
              if (isOwner && selectedPet != null)
                _buildGrantAccessButton(appState),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
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
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, i) =>
                        _buildExerciseLogTile(context, records[i], isOwner, appState),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetDropdown(AppState appState, int alpha20, int alpha90) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(alpha20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: selectedPet?.id,
        dropdownColor: Colors.white.withAlpha(alpha90),
        items: appState.pets
            .map((p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(p.name, style: const TextStyle(color: Color(0xFFB892F7))),
                ))
            .toList(),
        onChanged: (id) async {
          if (id != null) {
            final pet = appState.pets.firstWhere((p) => p.id == id);
            if (!mounted) return;
            setState(() => selectedPet = pet);
            await appState.loadExerciseLog(pet.id!);
          }
        },
      ),
    );
  }

  Widget _buildGrantAccessButton(AppState appState) {
    return ElevatedButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final trainers = await appState.getTrainers();

        if (!mounted) return;

        final selectedTrainer = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (cont) => SimpleDialog(
            title: const Text("Select Trainer"),
            children: trainers
                .map((trainer) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(cont, trainer),
                      child:
                          Text("${trainer['firstName']} ${trainer['lastName']}"),
                    ))
                .toList(),
          ),
        );

        if (!mounted || selectedTrainer == null || selectedPet == null) return;

        await appState.grantAccess(selectedPet!.id!, selectedTrainer['id']);
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(content: Text("Granted access to ${selectedTrainer['firstName']}")),
        );
      },
      child: const Text("Grant Trainer Access"),
    );
  }

  Widget _buildExerciseLogTile(BuildContext context, ExerciseLog record, bool isOwner, AppState appState) {
    final messenger = ScaffoldMessenger.of(context);

    final int alpha15 = (0.15 * 255).round();
    final int alpha30 = (0.3 * 255).round();
    final int alpha25 = (0.25 * 255).round();

    final petName = _getPetName(record.petId, appState);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(alpha15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withAlpha(alpha30),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(petName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Activity: ${record.activity}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Observations: ${record.observations}\n\nLength of Activity: ${record.length}\n\nDate and Time: ${record.date}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                      final result = await showDialog<ExerciseLog>(
                        context: context,
                        builder: (_) => AddExerciseLogDialog(exerciseLog: record),
                      );

                      if (!mounted || result == null) return;

                      await appState.updateExerciseLog(result);

                      if (!mounted) return;
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Exercise Log updated')));
                    },
                  ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await appState.deleteExerciseLog(record.id!, record.petId);
                      if (!mounted) return;
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Exercise Log deleted')));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}