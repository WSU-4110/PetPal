import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/reminder.dart';
import '../services/db_service.dart';
import 'add_reminder_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DBService _dbService = DBService();

  late final ValueNotifier<List<Reminder>> _selectedReminders;
  Map<DateTime, List<Reminder>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedReminders = ValueNotifier([]);
    _loadAllReminders();
  }

  @override
  void dispose() {
    _selectedReminders.dispose();
    super.dispose();
  }

  Future<void> _loadAllReminders() async {
    final all = await _dbService.getAllReminders();
    final map = <DateTime, List<Reminder>>{};
    for (var r in all) {
      final key = DateTime(r.scheduledAt.year, r.scheduledAt.month, r.scheduledAt.day);
      map.putIfAbsent(key, () => []).add(r);
    }
    setState(() {
      _events = map;
      _isLoading = false;
      _selectedReminders.value = _getRemindersForDay(_selectedDay);
    });
  }

  List<Reminder> _getRemindersForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Future<void> _addReminder() async {
    final pets = await _dbService.getPets();
    final newRem = await showDialog<Reminder>(
      context: context,
      builder: (_) => AddReminderDialog(pets: pets),
    );
    if (newRem != null) {
      await _dbService.insertReminder(newRem);
      await _loadAllReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<Reminder>(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: _getRemindersForDay,
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
                _selectedReminders.value = _getRemindersForDay(selected);
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ValueListenableBuilder<List<Reminder>>(
              valueListenable: _selectedReminders,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return const Center(child: Text('No reminders'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final r = items[i];
                    return ListTile(
                      leading: Icon(
                        r.done ? Icons.check_circle : Icons.notifications,
                        color: r.done ? Colors.green : Colors.redAccent,
                      ),
                      title: Text(r.title),
                      subtitle: Text(
                        '${r.category} @ ${TimeOfDay.fromDateTime(r.scheduledAt).format(context)}',
                      ),

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}