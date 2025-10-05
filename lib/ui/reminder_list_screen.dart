// lib/ui/reminder_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
import 'add_reminder_dialog.dart';
import 'edit_reminder_dialog.dart';
import 'package:intl/intl.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Stack(
      children: [
        appState.reminders.isEmpty
            ? const Center(child: Text('No reminders yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: appState.reminders.length,
                itemBuilder: (context, index) {
                  final Reminder r = appState.reminders[index];
                  return ListTile(
                    title: Text(r.title),
                    subtitle: Text('${r.category} • ${_fmt(r.scheduledAt)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: r.done,
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
                          icon: const Icon(Icons.edit, color: Colors.deepPurple),
                          onPressed: () async {
                            final result = await showDialog<Reminder>(
                              context: context,
                              builder: (_) => EditReminderDialog(
                                  reminder: r, pets: appState.pets),
                            );
                            if (result != null) {
                              await appState.updateReminder(result);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reminder updated')));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await appState.deleteReminder(r.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reminder deleted')));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () async {
              if (appState.pets.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add a pet first')));
                return;
              }

              final result = await showDialog<Reminder>(
                  context: context,
                  builder: (context) =>
                      AddReminderDialog(pets: appState.pets));

              if (result != null) {
                await appState.addReminder(result);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder added')));
              }
            },
            child: const Icon(Icons.add_alarm),
          ),
        ),
      ],
    );
  }
}
