// screens/edit_MedicalRecord_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';

class EditMedicalRecordDialog extends StatefulWidget {
  final MedicalRecord medicalrecord;
  final List<Pet> pets;

  const EditMedicalRecordDialog({super.key, required this.medicalrecord, required this.pets});

  @override
  _EditMedicalRecordDialogState createState() => _EditMedicalRecordDialogState();
}

class _EditMedicalRecordDialogState extends State<EditMedicalRecordDialog> {
    late TextEditingController titleController;
    late TextEditingController descController;
    late TextEditingController dateController;
    late TextEditingController vetController;
    late Pet selectedPet;
    late TimeOfDay selectedTime;
    late DateTime selectedDate;


  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.medicalrecord.title);
    descController = TextEditingController(text: widget.medicalrecord.description);
    dateController = TextEditingController(text: widget.medicalrecord.date);
    vetController = TextEditingController(text: widget.medicalrecord.vetName);
    try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(widget.medicalrecord.date);
    } catch (e) {
      selectedDate = DateTime.now();
    }
    selectedTime = TimeOfDay.fromDateTime(selectedDate);
    selectedPet = widget.pets.firstWhere((p) => p.id == widget.medicalrecord.petId);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100));
    if (date != null) setState(() => selectedDate = date);
    dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) setState(() => selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Medical Record'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextField(
              controller: vetController,
              decoration: const InputDecoration(labelText: 'Vet/Clinic'),
            ),
            Row(
              children: [
                TextButton(
                    onPressed: pickDate,
                    child: Text(DateFormat('yyyy-MM-dd').format(selectedDate))),
                TextButton(
                    onPressed: pickTime,
                    child: Text(selectedTime.format(context))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () {
              final dt = DateTime(selectedDate.year, selectedDate.month,
                  selectedDate.day, selectedTime.hour, selectedTime.minute);
                  dateController.text = DateFormat('yyyy-MM-dd').format(dt);
              final updated = MedicalRecord(
                id: widget.medicalrecord.id,
                petId: widget.medicalrecord.petId,
                title: titleController.text,
                description: descController.text,
                date: DateFormat('yyyy-MM-dd').format(dt),
                vetName: vetController.text,
              );
              Navigator.pop(context, updated);
            },
            child: const Text('Save')),
      ],
    );
  }
}
