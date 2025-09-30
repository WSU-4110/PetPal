import 'package:flutter/material.dart';
import 'pet_list_screen.dart';
import 'reminder_list_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetPal'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.pets),
              label: const Text('Pet Profiles'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PetListScreen()));
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.alarm),
              label: const Text('Reminders'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen()));
              },
            ),
            const SizedBox(height: 32),
            Text('Pets in system: ${appState.pets.length}'),
            Text('Reminders total: ${appState.reminders.length}'),
          ],
        ),
      ),
    );
  }
}
