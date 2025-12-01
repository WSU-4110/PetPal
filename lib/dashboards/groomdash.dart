// dashboards/groomdash.dart
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
      // NOTE: loadAccessiblePets is often an async call, but context.read is synchronous.
      // This is safe because it's called within initState and is immediately followed
      // by a build/Consumer rebuild when the state is updated.
      context.read<app_state.AppState>().loadAccessiblePets(groomerId);
    }

  }

  @override
  Widget build(BuildContext context) {
    // Alpha calculation for deprecated color functions
    final int alpha15 = (0.15 * 255).round();
    final int alpha10 = (0.1 * 255).round();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Groomer Dashboard',
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
            end:Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20), // Add space after app bar
                // Center the instruction text
                const Center(
                  child: Text(
                    'Select a pet to view grooming records:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Pet selection will be handled by a separate component
                Expanded(
                  child: Consumer<app_state.AppState>(
                    builder: (context, appState, _) {
                      if (appState.accessiblePets.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cut,
                                size: 80,
                                color: Colors.white70,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No pets available',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pet owners need to grant you access to their pets',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: appState.accessiblePets.length,
                        itemBuilder: (context, index) {
                          final pet = appState.accessiblePets[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              // FIX: Replaced withOpacity with withAlpha
                              color: Colors.white.withAlpha(alpha15),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  // FIX: Replaced withOpacity with withAlpha
                                  color: Colors.black.withAlpha(alpha10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white24,
                                backgroundImage: pet.image != null && pet.image!.isNotEmpty
                                    ? (pet.image!.startsWith('http')
                                        ? NetworkImage(pet.image!) as ImageProvider
                                        : AssetImage(pet.image!) as ImageProvider)
                                    : null,
                                child: pet.image == null || pet.image!.isEmpty
                                    ? const Icon(Icons.pets, color: Colors.white70)
                                    : null,
                              ),
                              title: Text(
                                pet.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                '${pet.species} • ${pet.breed}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
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
        ),
      ),
    );
  }
}