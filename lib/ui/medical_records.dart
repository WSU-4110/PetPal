import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/medical_record.dart';

abstract class MedicalRecordWidgetFactory {
  Widget createRecordTile(BuildContext context, MedicalRecord record);
  Widget createAddRecordDialog(BuildContext context, int petId);
}

class DefaultMedicalRecordWidgetFactory implements MedicalRecordWidgetFactory {
  const DefaultMedicalRecordWidgetFactory();

  @override
  Widget createRecordTile(BuildContext context, MedicalRecord record) {
    return ListTile(
      title: Text(record.title),
      subtitle: Text("${record.date} — ${record.vetName}"),
    );
  }

  @override
  Widget createAddRecordDialog(BuildContext context, int petId) {
    return AddMedicalRecordDialog(petId: petId);
  }
}

// Display Page
class MedicalRecordsPage extends StatefulWidget {
  final int petId;
  final MedicalRecordWidgetFactory factory;

  const MedicalRecordsPage({
    super.key,
    required this.petId,
    this.factory = const DefaultMedicalRecordWidgetFactory(),
  });

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
          return widget.factory.createRecordTile(context, record);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) =>
                widget.factory.createAddRecordDialog(context, widget.petId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

//Section for adding records
class AddMedicalRecordDialog extends StatefulWidget {
  final int petId;
  const AddMedicalRecordDialog({super.key, required this.petId});

  @override
  State<AddMedicalRecordDialog> createState() => _AddMedicalRecordDialogState();
}

class _AddMedicalRecordDialogState extends State<AddMedicalRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _vetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Medical Record"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextFormField(
                controller: _dateController,
                decoration:
                const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _vetController,
                decoration: const InputDecoration(labelText: "Vet/Clinic"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final record = MedicalRecord(
                petId: widget.petId,
                title: _titleController.text,
                description: _descController.text,
                date: _dateController.text,
                vetName: _vetController.text,
              );
              await context.read<AppState>().addMedicalRecord(record);
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}