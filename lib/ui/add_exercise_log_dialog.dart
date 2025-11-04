import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/exercise_log.dart';

class AddExerciseLogDialog extends StatefulWidget {
  final int petId;
  const AddExerciseLogDialog({super.key, required this.petId});

  @override
  State<AddExerciseLogDialog> createState() => _AddExerciseLogDialogState();
}

class _AddExerciseLogDialogState extends State<AddExerciseLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _activityController = TextEditingController();
  final _dateController = TextEditingController();
  final _observationController = TextEditingController();

  DateTime? _selectedDate;

 @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
      _selectedDate = date;
     _dateController.text = DateFormat('yyyy-MM-dd').format(date);
     });
  }
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Exercise Log"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _lengthController,
                decoration: const InputDecoration(labelText: "Length of activity"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(labelText: "Activity Completed"),
              ),
              GestureDetector(
                onTap: pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: "Date"),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                ),
              ),
              TextFormField(
                controller: _observationController,
                decoration: const InputDecoration(labelText: "Observations"),
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
              final record = ExerciseLog(
                petId: widget.petId,
                length: _lengthController.text,
                activity: _activityController.text,
                date: _dateController.text,
                observations: _observationController.text,
              );
              await context.read<AppState>().addExerciseLog(record);
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
