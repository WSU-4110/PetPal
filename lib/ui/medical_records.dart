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
    Future.microtask(() =>
        context.read<AppState>().loadMedicalRecords(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.medicalRecords;

    return Scaffold(
      appBar: AppBar(title: const Text("Medical Records")),
      body: records.isEmpty
          ? const Center(child: Text("No medical records yet."))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, i) {
                final record = records[i];
                return ListTile(
                  title: Text(record.title),
                  subtitle: Text("${record.date} — ${record.vetName}"),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddMedicalRecordDialog(petId: widget.petId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
