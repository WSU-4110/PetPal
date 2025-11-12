import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
import '../models/exercise_log.dart';
import '../models/groom_log.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

// Filter reminders
    final weeklyReminders = appState.reminders.where((r) =>
    r.scheduledAt.isAfter(startOfWeek) &&
        r.scheduledAt.isBefore(endOfWeek.add(const Duration(days: 1)))
    ).toList();

// Filter exercise logs
    final weeklyExercise = appState.exerciseLogs.where((log) {
      final date = DateTime.parse(log.date);
      return date.isAfter(startOfWeek) && date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

// Filter grooming logs
    final weeklyGrooming = appState.groomLogs.where((log) {
      final date = DateTime.parse(log.date);
      return date.isAfter(startOfWeek) && date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Reminders'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total reminders: ${weeklyReminders.length}'),
                  Text('Completed: ${weeklyReminders.where((r) => r.done).length}'),
                  Text('Pending: ${weeklyReminders.where((r) => !r.done).length}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Exercise'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sessions: ${weeklyExercise.length}'),
                  if (weeklyExercise.isNotEmpty)
                    Text('Last activity: ${weeklyExercise.first.activity}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Grooming'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sessions: ${weeklyGrooming.length}'),
                  if (weeklyGrooming.isNotEmpty)
                    Text('Last type: ${weeklyGrooming.first.type}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Highlights'),
            _buildCard(
              child: const Text(
                'Highlight Placeholder',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}