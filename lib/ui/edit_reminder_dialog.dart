// screens/edit_reminder_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/reminder.dart';

class EditReminderDialog extends StatefulWidget {
  final Reminder reminder;
  final List<Pet> pets;

  const EditReminderDialog({super.key, required this.reminder, required this.pets});

  @override
  _EditReminderDialogState createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends State<EditReminderDialog> {
  late Pet selectedPet;
  late TextEditingController titleController;
  late String category;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedPet = widget.pets.firstWhere((p) => p.id == widget.reminder.petId);
    titleController = TextEditingController(text: widget.reminder.title);
    category = widget.reminder.category;
    selectedDate = widget.reminder.scheduledAt;
    selectedTime = TimeOfDay.fromDateTime(widget.reminder.scheduledAt);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100));
    if (date != null) setState(() => selectedDate = date);
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
      title: const Text('Edit Reminder'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButton<Pet>(
              value: selectedPet,
              items: widget.pets
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (p) => setState(() => selectedPet = p!),
            ),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            DropdownButton<String>(
              value: category,
              items: ['Feeding', 'Medication', 'Vet']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (c) => setState(() => category = c!),
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
              final updated = Reminder(
                id: widget.reminder.id,
                petId: selectedPet.id!,
                title: titleController.text,
                category: category,
                scheduledAt: dt,
                done: widget.reminder.done,
              );
              Navigator.pop(context, updated);
            },
            child: const Text('Save')),
      ],
    );
  }
}
