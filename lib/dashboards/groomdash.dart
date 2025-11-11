import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/groom_logs.dart';
import '../state/app_state.dart' as app_state;

// New GroomDashboard screen for Groomers
class GroomerDashboard extends StatefulWidget {
  const GroomerDashboard({super.key});

  @override
  State<GroomerDashboard> createState() => _GroomerDashboardState();
}

class _GroomerDashboardState extends State<GroomerDashboard> {

  @override
  void initState() {
    super.initState();

    final groomerId = context.read<app_state.AppState>().currentUser?['id'] as int?;

    if (groomerId != null) {
      context.read<app_state.AppState>().loadAccessiblePets(groomerId);
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
              'Groomer Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a pet to view grooming records:',
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
                                builder: (context) => GroomLogs(petId: pet.id!),
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