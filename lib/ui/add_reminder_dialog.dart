// screens/add_reminder_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/reminder.dart';

class AddReminderDialog extends StatefulWidget {
  final List<Pet> pets;
  const AddReminderDialog({super.key, required this.pets});

  @override
  _AddReminderDialogState createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  Pet? selectedPet;
  final titleController = TextEditingController();
  String category = 'Feeding';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    selectedPet = widget.pets.first;
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: selectedDate!,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100));
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime!,
    );
    if (time != null) setState(() => selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Reminder'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButton<Pet>(
              value: selectedPet,
              items: widget.pets
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (p) => setState(() => selectedPet = p),
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
                    child: Text(selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                        : 'Pick date')),
                TextButton(
                    onPressed: pickTime,
                    child: Text(selectedTime != null
                        ? selectedTime!.format(context)
                        : 'Pick time')),
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
              final dt = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute);
              final reminder = Reminder(
                petId: selectedPet!.id!,
                title: titleController.text,
                category: category,
                scheduledAt: dt,
              );
              Navigator.pop(context, reminder);
            },
            child: const Text('Add')),
      ],
    );
  }
}
