// lib/ui/reminder_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: "Open Calendar",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
        ],
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                                  '${r.category} • ${_fmt(r.scheduledAt)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: r.done,
                                activeColor: Colors.purpleAccent,
                                onChanged: (val) async {
                                  final updated = Reminder(
                                    id: r.id,
                                    petId: r.petId,
                                    title: r.title,
                                    category: r.category,
                                    scheduledAt: r.scheduledAt,
                                    done: val ?? false,
                                  );
                                  await appState.updateReminder(updated);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70),
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
                                      const SnackBar(
                                          content:
                                              Text('Reminder updated')),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await appState.deleteReminder(r.id!);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                        content: Text('Reminder deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
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
              color: Colors.pinkAccent.withValues(alpha: 0.5),
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
}