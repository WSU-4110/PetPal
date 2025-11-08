// screens/add_reminder_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/reminder.dart';

class AddReminderDialog extends StatefulWidget {
  final List<Pet> pets;
  const AddReminderDialog({super.key, required this.pets});

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  Pet? selectedPet;
  final titleController = TextEditingController();
  String category = 'Feeding';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isRecurring = false;
  String recurringInterval = 'Daily';
  int customDays = 1;

  @override
  void initState() {
    super.initState();
    selectedPet = widget.pets.isNotEmpty ? widget.pets.first : null;
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
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
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
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
                          Icons.alarm_add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Add New Reminder',
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
                    'Set up a reminder for your pet',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet selector card
                    _buildFormCard(
                      title: 'Select Pet',
                      icon: Icons.pets,
                      child: _buildPetSelector(),
                    ),
                    const SizedBox(height: 16),

                    // Title input card
                    _buildFormCard(
                      title: 'Reminder Title',
                      icon: Icons.title,
                      child: _buildTitleInput(),
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
                    const SizedBox(height: 16),

                    // Recurring options card
                    _buildFormCard(
                      title: 'Recurring',
                      icon: Icons.repeat,
                      child: _buildRecurringOptions(),
                    ),
                  ],
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
                        'Add Reminder',
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

  Widget _buildPetSelector() {
    if (widget.pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No pets available. Please add a pet first.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Pet>(
          value: selectedPet,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          isExpanded: true,
          items: widget.pets.map((pet) {
            return DropdownMenuItem<Pet>(
              value: pet,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: _buildPetImage(pet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${pet.breed} • ${pet.age} years',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPet = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPetImage(Pet pet) {
    // Check if the image is a network URL or an asset path
    if (pet.image != null && pet.image!.startsWith('http')) {
      // Network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          pet.image!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.pets, size: 18, color: Colors.grey[600]);
          },
        ),
      );
    } else if (pet.image != null && pet.image!.startsWith('assets/')) {
      // Asset image
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          pet.image!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.pets, size: 18, color: Colors.grey[600]);
          },
        ),
      );
    } else {
      // Default icon
      return Icon(Icons.pets, size: 18, color: Colors.grey[600]);
    }
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: titleController,
      decoration: InputDecoration(
        hintText: 'Enter reminder title...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.all(12),
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

  Widget _buildRecurringOptions() {
    return Column(
      children: [
        // Toggle switch for recurring
        Row(
          children: [
            Expanded(
              child: Text(
                'Make this reminder recurring',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: isRecurring,
              onChanged: (value) {
                setState(() => isRecurring = value);
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),

        // Show recurring options if enabled
        if (isRecurring) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Preset intervals
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildIntervalChip('Daily', 'Every day'),
              _buildIntervalChip('Every 2 Days', 'Every other day'),
              _buildIntervalChip('Every 3 Days', 'Every 3 days'),
              _buildIntervalChip('Weekly', 'Once a week'),
              _buildIntervalChip('Bi-Weekly', 'Every 2 weeks'),
              _buildIntervalChip('Monthly', 'Once a month'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Custom days input
          if (recurringInterval == 'Custom') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: customDays.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Repeat every (days)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (value) {
                      final days = int.tryParse(value);
                      if (days != null && days > 0) {
                        setState(() => customDays = days);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRecurringInfoText(),
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIntervalChip(String interval, String description) {
    final isSelected = recurringInterval == interval;
    
    return GestureDetector(
      onTap: () => setState(() => recurringInterval = interval),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2) 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              interval,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRecurringInfoText() {
    if (selectedDate == null || selectedTime == null) {
      return 'Select a date and time first';
    }
    
    final time = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
    
    switch (recurringInterval) {
      case 'Daily':
        return 'Reminder will repeat every day at $time';
      case 'Every 2 Days':
        return 'Reminder will repeat every 2 days at $time';
      case 'Every 3 Days':
        return 'Reminder will repeat every 3 days at $time';
      case 'Weekly':
        return 'Reminder will repeat every week at $time';
      case 'Bi-Weekly':
        return 'Reminder will repeat every 2 weeks at $time';
      case 'Monthly':
        return 'Reminder will repeat every month at $time';
      case 'Custom':
        return 'Reminder will repeat every $customDays day(s) at $time';
      default:
        return '';
    }
  }

  int _getDaysInterval() {
    switch (recurringInterval) {
      case 'Daily':
        return 1;
      case 'Every 2 Days':
        return 2;
      case 'Every 3 Days':
        return 3;
      case 'Weekly':
        return 7;
      case 'Bi-Weekly':
        return 14;
      case 'Monthly':
        return 30;
      case 'Custom':
        return customDays;
      default:
        return 1;
    }
  }

  void _saveReminder() {
    if (selectedPet == null ||
        titleController.text.trim().isEmpty ||
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

    // If recurring, create multiple reminders
    if (isRecurring) {
      final reminders = <Reminder>[];
      final daysInterval = _getDaysInterval();
      
      // Create reminders for the next 90 days (or adjust as needed)
      for (int i = 0; i < 90; i += daysInterval) {
        final reminderDate = dt.add(Duration(days: i));
        
        reminders.add(Reminder(
          petId: selectedPet!.id!,
          title: titleController.text.trim(),
          category: category,
          scheduledAt: reminderDate,
        ));
      }
      
      Navigator.pop(context, reminders);
    } else {
      // Single reminder
      final reminder = Reminder(
        petId: selectedPet!.id!,
        title: titleController.text.trim(),
        category: category,
        scheduledAt: dt,
      );

      Navigator.pop(context, reminder);
    }
  }
}