import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/exercise_log.dart';

class EditExerciseLogDialog extends StatefulWidget {
  final ExerciseLog exerciseLog;
  final List<Pet> pets;

  const EditExerciseLogDialog({super.key, required this.exerciseLog, required this.pets});

  @override
  _EditExerciseLogDialogState createState() => _EditExerciseLogDialogState();
}

class _EditExerciseLogDialogState extends State<EditExerciseLogDialog> {
    late TextEditingController lengthController;
    late TextEditingController activityController;
    late TextEditingController dateController;
    late TextEditingController observationsController;
    late Pet selectedPet;
    late TimeOfDay selectedTime;
    late DateTime selectedDate;


  @override
  void initState() {
    super.initState();
    lengthController = TextEditingController(text: widget.exerciseLog.length);
    activityController = TextEditingController(text: widget.exerciseLog.activity);
    dateController = TextEditingController(text: widget.exerciseLog.date);
    observationsController = TextEditingController(text: widget.exerciseLog.observations);
    try {
        selectedDate = DateFormat('yyyy-MM-dd hh:mm').parse(widget.exerciseLog.date);
    } catch (err) {
      selectedDate = DateTime.now();
    }
    selectedTime = TimeOfDay.fromDateTime(selectedDate);
    selectedPet = widget.pets.firstWhere((p) => p.id == widget.exerciseLog.petId);
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
      title: const Text('Edit Exercise Log'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: lengthController,
              decoration: const InputDecoration(labelText: 'Length of activity'),
            ),
            TextField(
              controller: activityController,
              decoration: const InputDecoration(labelText: 'Activity'),
              maxLines: 2,
            ),
            TextField(
              controller: observationsController,
              decoration: const InputDecoration(labelText: 'Observations'),
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
              final updated = ExerciseLog(
                id: widget.exerciseLog.id,
                petId: widget.exerciseLog.petId,
                length: lengthController.text,
                activity: activityController.text,
                date: DateFormat('yyyy-MM-dd hh:mm').format(dt),
                observations: observationsController.text,
              );
              Navigator.pop(context, updated);
            },
            child: const Text('Save')),
      ],
    );
  }
}
