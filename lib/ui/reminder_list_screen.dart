// lib/ui/reminder_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
import '../models/pet.dart';
import 'add_reminder_dialog.dart';
import 'edit_reminder_dialog.dart';
import 'calendar_screen.dart';
import 'package:intl/intl.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
          child: appState.reminders.isEmpty
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
                  itemCount: appState.reminders.length,
                  itemBuilder: (context, index) {
                    final Reminder r = appState.reminders[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        // MATCH PetListScreen tile style:
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Keep the icon but restyle slightly to match PetListScreen spacing
                          _buildReminderIcon(r),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getPetNameForReminder(r, appState),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r.category} • ${_fmt(r.scheduledAt)}',
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
                                  final messenger = ScaffoldMessenger.of(context);
                                  await appState.deleteReminder(r.id!);
                                  await appState.deleteNotification(r.id!);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Reminder deleted')),
                                  );
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (appState.pets.isEmpty) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Add a pet first')),
              );
              return;
            }

            // NOTE: your AddReminderDialog is a bottom-sheet style widget.
            // you can keep using showDialog (it still works), or switch to modal bottom sheet:
            // showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddReminderDialog(pets: appState.pets));
            final result = await showDialog<Reminder>(
              context: context,
              builder: (context) => AddReminderDialog(pets: appState.pets),
            );

            if (result != null) {
              await appState.addReminder(result);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Reminder added')),
              );
            }
          },
          child: const Icon(Icons.add_alarm, size: 30),
        ),
      ),
    );
  }

  // Helper method to build reminder icon based on category
  Widget _buildReminderIcon(Reminder reminder) {
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

    // match the small tile look but keep the icon visual contrast
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF6C63FF), size: 26),
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
