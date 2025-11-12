// screens/edit_exercise_log_dialog.dart 
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
  final _formKey = GlobalKey<FormState>();
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

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null) {
      setState(() {
        selectedDate = _combine(date, selectedTime);
        dateController.text = DateFormat('yyyy-MM-dd hh:mm').format(selectedDate);
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) { 
      setState(() {
        selectedTime = time;
        selectedDate = _combine(selectedDate, time);
        dateController.text = DateFormat('yyyy-MM-dd hh:mm').format(selectedDate);
      });
    }
  }

  @override
  void dispose() {
    lengthController.dispose();
    activityController.dispose();
    dateController.dispose();
    observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.primary.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.directions_run,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Edit Exercise Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update exercise activity for ${selectedPet.name}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity input card
                      _buildFormCard(
                        title: 'Activity Completed',
                        icon: Icons.directions_run,
                        child: TextFormField(
                          controller: activityController,
                          decoration: InputDecoration(
                            hintText: 'Enter activity type...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Length input card
                      _buildFormCard(
                        title: 'Length of Activity',
                        icon: Icons.timer,
                        child: TextFormField(
                          controller: lengthController,
                          decoration: InputDecoration(
                            hintText: 'Enter duration or distance...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Schedule card
                      _buildFormCard(
                        title: 'Schedule',
                        icon: Icons.schedule,
                        child: Column(
                          children: [
                            _buildDateSelector(),
                            const SizedBox(height: 12),
                            _buildTimeSelector(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observations input card
                      _buildFormCard(
                        title: 'Observations',
                        icon: Icons.visibility,
                        child: TextFormField(
                          controller: observationsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter observations during activity...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final dt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
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
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Update Log',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: pickDate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: pickTime,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedTime.format(context),
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}