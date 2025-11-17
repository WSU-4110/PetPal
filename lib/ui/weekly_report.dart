import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/reminder.dart';
import '../models/exercise_log.dart';
import '../models/groom_log.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';

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

    String weekRangeText(DateTime start, DateTime end) {
      final fmt = DateFormat('MMM dd, yyyy');
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Report',
          style: TextStyle(
        ),
        ),

      ),

      body: Container(
    decoration: const BoxDecoration(
    gradient: LinearGradient(
        colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),
    padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Week of ${weekRangeText(startOfWeek, endOfWeek)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Tasks This Week'),
            _buildCard(
              child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total reminders: ${weeklyReminders.length}',
                style: const TextStyle(
                fontSize: 18,
                color: Colors.white),
                  ),
                  Text('Completed: ${weeklyReminders.where((r) => r.done).length}',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white),
                  ),
                  Text('Pending: ${weeklyReminders.where((r) => !r.done).length}',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Exercise'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sessions: ${weeklyExercise.length}',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white),
              ),
                  if (weeklyExercise.isNotEmpty)
                    Text('Last activity: ${weeklyExercise.first.activity}',
        style: const TextStyle(
            fontSize: 18,
            color: Colors.white),
      ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Grooming'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sessions: ${weeklyGrooming.length}',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white),
              ),
                  if (weeklyGrooming.isNotEmpty)
                    Text('Last type: ${weeklyGrooming.first.type}',
        style: const TextStyle(
            fontSize: 18,
            color: Colors.white),
      ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
        color: Colors.white,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      child: child,
    );
  }

}