import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'add_medical_record_dialog.dart';

class MedicalRecordsPage extends StatefulWidget {
  final int petId;
  const MedicalRecordsPage({super.key, required this.petId});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  @override
  void initState() {
    super.initState();
    // Load medical records for this pet
    Future.microtask(() =>
        context.read<AppState>().loadMedicalRecords(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.medicalRecords;

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
                      ),
                    );
                  },
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
              color: Colors.pinkAccent.withOpacity(0.5),
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
              builder: (_) => AddMedicalRecordDialog(petId: widget.petId),
            );
          },
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
    );
  }
}
