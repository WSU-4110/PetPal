import 'package:flutter/material.dart';
import 'groom_logs.dart';

class GroomScreen extends StatelessWidget {
  const GroomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, hardcode a petId (e.g. 1). Later, you can pass it dynamically.
    final int petId = 1;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Grooming',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        // Match the purple-pink gradient style from ReminderListScreen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cut, color: Colors.white, size: 70),
                    const SizedBox(height: 16),
                    const Text(
                      'Grooming Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Log your pets' grooming activities here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        // Keep purple tones but match Reminder aesthetic
                        backgroundColor: const Color(0xFFB892F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: const Color(0xFFE040FB).withOpacity(0.5),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.pets),
                      label: const Text(
                        "View Grooming Logs",
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroomLogs(petId: petId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
