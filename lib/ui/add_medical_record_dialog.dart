import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/medical_record.dart';

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
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _vetController.dispose();
    super.dispose();
  }

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
                decoration: const InputDecoration(labelText: "Appointment"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description of appointment"),
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
                controller: _vetController,
                decoration: const InputDecoration(labelText: "Vet/Clinic Name"),
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
              
              // Store the navigator before the async operation
              final navigator = Navigator.of(context);
              await context.read<AppState>().addMedicalRecord(record);
              if (mounted) {
                navigator.pop();
              }
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}