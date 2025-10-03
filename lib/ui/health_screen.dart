// lib/ui/health_screen.dart
import 'package:flutter/material.dart';
import 'medical_records.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, hardcode a petId (e.g. 1). Later, you can pass the actual petId dynamically.
    final int petId = 1;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Health Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Track your pets\' health stats here.'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.medical_services),
            label: const Text("View Medical Records"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalRecordsPage(petId: petId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
