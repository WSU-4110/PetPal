import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/groom_log.dart';

class EditGroomLogDialog extends StatefulWidget {
  final GroomLog groomLog;
  final List<Pet> pets;

  const EditGroomLogDialog({super.key, required this.groomLog, required this.pets});

  @override
  _EditGroomLogDialogState createState() => _EditGroomLogDialogState();
}

class _EditGroomLogDialogState extends State<EditGroomLogDialog> {
    late TextEditingController typeController;
    late TextEditingController descriptionController;
    late TextEditingController dateController;
    late TextEditingController maintenanceController;
    late Pet selectedPet;
    late TimeOfDay selectedTime;
    late DateTime selectedDate;


  @override
  void initState() {
    super.initState();
    typeController = TextEditingController(text: widget.groomLog.type);
    descriptionController = TextEditingController(text: widget.groomLog.description);
    dateController = TextEditingController(text: widget.groomLog.date);
    maintenanceController = TextEditingController(text: widget.groomLog.maintenance);
    try {
        selectedDate = DateFormat('yyyy-MM-dd hh:mm').parse(widget.groomLog.date);
    } catch (err) {
      selectedDate = DateTime.now();
    }
    selectedTime = TimeOfDay.fromDateTime(selectedDate);
    selectedPet = widget.pets.firstWhere((p) => p.id == widget.groomLog.petId);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null) setState(() => selectedDate = date);
    dateController.text = DateFormat('yyyy-MM-dd hh:mm').format(selectedDate);
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
      title: const Text('Edit Grooming Log'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Type of Grooming'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextField(
              controller: maintenanceController,
              decoration: const InputDecoration(labelText: 'Maintenance Done'),
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
                  dateController.text = DateFormat('yyyy-MM-dd hh:mm').format(dt);
              final updated = GroomLog(
                id: widget.groomLog.id,
                petId: widget.groomLog.petId,
                type: typeController.text,
                description: descriptionController.text,
                date: DateFormat('yyyy-MM-dd hh:mm').format(dt),
                maintenance: maintenanceController.text,
              );
              Navigator.pop(context, updated);
            },
            child: const Text('Save')),
      ],
    );
  }
}
