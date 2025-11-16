// lib/ui/reminder_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
import 'edit_reminder_dialog.dart';
import 'package:intl/intl.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd – HH:mm').format(dt);

  // Group recurring reminders by their core properties
  List<Map<String, dynamic>> _groupReminders(List<Reminder> reminders) {
    final Map<String, List<Reminder>> grouped = {};
    
    for (var reminder in reminders) {
      // Create a unique key based on pet, title, and category
      final key = '${reminder.petId}_${reminder.title}_${reminder.category}';
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(reminder);
    }
    
    // Convert to display format
    final List<Map<String, dynamic>> result = [];
    grouped.forEach((key, reminderList) {
      // Sort by date to get the earliest one
      reminderList.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      
      result.add({
        'reminder': reminderList.first, // Show the earliest occurrence
        'count': reminderList.length,
        'allReminders': reminderList,
        'isRecurring': reminderList.length > 1,
      });
    });
    
    // Sort by scheduled date
    result.sort((a, b) => 
      (a['reminder'] as Reminder).scheduledAt.compareTo(
        (b['reminder'] as Reminder).scheduledAt
      )
    );
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final groupedReminders = _groupReminders(appState.reminders);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: groupedReminders.isEmpty
              ? const Center(
                  child: Text(
                    'No reminders yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedReminders.length,
                  itemBuilder: (context, index) {
                    final group = groupedReminders[index];
                    final Reminder r = group['reminder'] as Reminder;
                    final int count = group['count'] as int;
                    final bool isRecurring = group['isRecurring'] as bool;
                    final List<Reminder> allReminders = group['allReminders'] as List<Reminder>;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildReminderIcon(r, isRecurring),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _getPetNameForReminder(r, appState),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isRecurring) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.repeat,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$count',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isRecurring
                                      ? '${r.category} • Next: ${_fmt(r.scheduledAt)}'
                                      : '${r.category} • ${_fmt(r.scheduledAt)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (isRecurring)
                                IconButton(
                                  icon: const Icon(Icons.list, color: Colors.white70),
                                  onPressed: () {
                                    _showRecurringDetails(context, allReminders, appState);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final result = await showDialog<Reminder>(
                                    context: context,
                                    builder: (_) => EditReminderDialog(
                                      reminder: r,
                                      pets: appState.pets,
                                    ),
                                  );
                                  if (result != null) {
                                    await appState.updateReminder(result);
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Reminder updated')),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  if (isRecurring) {
                                    _showDeleteRecurringDialog(context, allReminders, appState);
                                  } else {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await appState.deleteReminder(r.id!);
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Reminder deleted')),
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      // FAB removed - handled by main.dart navigation
    );
  }

  // Helper method to build reminder icon based on category
  Widget _buildReminderIcon(Reminder reminder, bool isRecurring) {
    final categoryIcons = {
      'Feeding': Icons.restaurant,
      'Walking': Icons.directions_walk,
      'Medication': Icons.medication,
      'Vet': Icons.local_hospital,
    };

    // Default icon
    IconData icon = Icons.alarm;

    // Check if category matches
    for (var key in categoryIcons.keys) {
      if (reminder.category.toLowerCase().contains(key.toLowerCase()) ||
          reminder.title.toLowerCase().contains(key.toLowerCase())) {
        icon = categoryIcons[key]!;
        break;
      }
    }

    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 26),
        ),
        if (isRecurring)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.repeat,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  void _showRecurringDetails(BuildContext context, List<Reminder> reminders, AppState appState) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.8),
                      Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recurring Reminders',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${reminders.length} occurrences',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: reminders.length,
                  itemBuilder: (builderContext, index) {
                    final reminder = reminders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(builderContext).colorScheme.primary.withValues(alpha: 0.2),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(builderContext).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(_fmt(reminder.scheduledAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () async {
                            await appState.deleteReminder(reminder.id!);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reminder deleted')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteRecurringDialog(BuildContext context, List<Reminder> reminders, AppState appState) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Recurring Reminders'),
        content: Text('Do you want to delete all ${reminders.length} recurring reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              for (var reminder in reminders) {
                await appState.deleteReminder(reminder.id!);
              }
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('${reminders.length} reminders deleted')),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper method to get pet name for reminder
  String _getPetNameForReminder(Reminder reminder, AppState appState) {
    try {
      final pet = appState.pets.firstWhere((p) => p.id == reminder.petId);
      return pet.name;
    } catch (e) {
      return 'Unknown Pet';
    }
  }
}