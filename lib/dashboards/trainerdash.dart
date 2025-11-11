import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/exercise_logs.dart';
import '../state/app_state.dart' as app_state;

// New TrainDashboard screen for Trainers
class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {

  @override
  void initState() {
    super.initState();

    final trainerId = context.read<app_state.AppState>().currentUser?['id'] as int?;

    if (trainerId != null) {
      context.read<app_state.AppState>().loadAccessiblePets(trainerId);
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end:Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trainer Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a pet to view training records:',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            // Pet selection will be handled by a separate component
            Expanded(
              child: Consumer<app_state.AppState>(
                builder: (context, appState, _) {
                  if (appState.accessiblePets.isEmpty) {
                    return const Center(
                      child: Text('No pets available'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: appState.accessiblePets.length,
                    itemBuilder: (context, index) {
                      final pet = appState.accessiblePets[index];
                      return Card(
                        color: const Color.fromARGB(255, 222, 196, 226),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(pet.name),
                          subtitle: Text('${pet.species} • ${pet.breed}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseLogs(petId: pet.id!),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}