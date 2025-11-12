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
  State<EditReminderDialog> createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends State<EditReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  String category = 'Feeding';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isRecurring = false;
  String recurringInterval = 'Daily';
  int customDays = 1;
  late Pet selectedPet;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.reminder.title);
    category = widget.reminder.category;
    
    // Parse the scheduled date
    selectedDate = widget.reminder.scheduledAt;
    selectedTime = TimeOfDay.fromDateTime(widget.reminder.scheduledAt);
    
    // Find the pet for this reminder
    selectedPet = widget.pets.firstWhere((p) => p.id == widget.reminder.petId);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(() => selectedTime = time);
    }
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
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Edit Reminder',
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
                    'Update reminder for ${selectedPet.name}',
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
                      // Title input card
                      _buildFormCard(
                        title: 'Reminder Title',
                        icon: Icons.title,
                        child: TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter reminder title...',
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

                      // Category selector card
                      _buildFormCard(
                        title: 'Category',
                        icon: Icons.category,
                        child: _buildCategorySelector(),
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
                      onPressed: _saveReminder,
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
                        'Update Reminder',
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

  Widget _buildCategorySelector() {
    final categories = ['Feeding', 'Walking', 'Medication', 'Vet', 'Grooming', 'Playtime'];
    final categoryIcons = {
      'Feeding': Icons.restaurant,
      'Walking': Icons.directions_walk,
      'Medication': Icons.medication,
      'Vet': Icons.local_hospital,
      'Grooming': Icons.content_cut,
      'Playtime': Icons.toys,
    };
    final categoryColors = {
      'Feeding': Colors.orange,
      'Walking': Colors.green,
      'Medication': Colors.red,
      'Vet': Colors.purple,
      'Grooming': Colors.blue,
      'Playtime': Colors.pink,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = category == cat;
        final color = categoryColors[cat] ?? Colors.grey;
        
        return GestureDetector(
          onTap: () => setState(() => category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryIcons[cat],
                  color: isSelected ? color : Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
                selectedDate != null
                    ? DateFormat('EEEE, MMM dd, yyyy').format(selectedDate!)
                    : 'Select Date',
                style: TextStyle(
                  color: selectedDate != null ? Colors.black87 : Colors.grey[600],
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
                selectedTime != null ? selectedTime!.format(context) : 'Select Time',
                style: TextStyle(
                  color: selectedTime != null ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _saveReminder() {
    if (titleController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final dt = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Update the reminder
    final updatedReminder = Reminder(
      id: widget.reminder.id,
      petId: widget.reminder.petId,  // Keep the original petId
      title: titleController.text.trim(),
      category: category,
      scheduledAt: dt,
    );

    Navigator.pop(context, updatedReminder);
  }
}