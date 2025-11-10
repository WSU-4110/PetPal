import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/groom_log.dart';

class AddGroomLogDialog extends StatefulWidget {
  final int petId;
  const AddGroomLogDialog({super.key, required this.petId});

  @override
  State<AddGroomLogDialog> createState() => _AddGroomLogDialogState();
}

class _AddGroomLogDialogState extends State<AddGroomLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _maintenanceController = TextEditingController();
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;


 @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null) {
      setState(() {
        _selectedDate = _combine(date, _selectedTime);
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
  }
}

Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null){ 
      setState(() {
       _selectedTime = time;
       _selectedDate = _combine(_selectedDate, time);
       _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Grooming Log"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: "Type of Grooming"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
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
              TextButton(
                onPressed: pickTime,
                child: Text(_selectedTime.format(context)),
              ),
              TextFormField(
                controller: _maintenanceController,
                decoration: const InputDecoration(labelText: "Future Maintenance"),
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
              final record = GroomLog(
                petId: widget.petId,
                type: _typeController.text,
                description: _descriptionController.text,
                date: DateFormat('yyyy-MM-dd').format(_selectedDate),
                maintenance: _maintenanceController.text,
              );
              await context.read<AppState>().addGroomLog(record);
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
