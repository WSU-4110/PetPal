import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
import 'package:intl/intl.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({Key? key}) : super(key: key);

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView.builder(
        itemCount: appState.reminders.length,
        itemBuilder: (context, index) {
          final Reminder r = appState.reminders[index];
          return ListTile(
            title: Text(r.title),
            subtitle: Text('${r.category} • ${_fmt(r.scheduledAt)}'),
            trailing: Checkbox(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Basic add reminder flow: for now pick first pet (if exists)
          if (appState.pets.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a pet first')));
            return;
          }
          final pet = appState.pets.first;
          final now = DateTime.now().add(const Duration(minutes: 1));
          final r = Reminder(
            petId: pet.id!,
            title: 'Feed ${pet.name}',
            category: 'Feeding',
            scheduledAt: now,
          );
          await appState.addReminder(r);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder added')));
        },
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}
