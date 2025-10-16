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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
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
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<List<Reminder>>(
                  valueListenable: _selectedReminders,
                  builder: (context, items, _) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No reminders',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final r = items[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  r.done ? Icons.check_circle : Icons.notifications,
                                  color: r.done ? Colors.green : Colors.redAccent,
                                ),
                                onPressed: () async {
                                  // toggle done by creating a new Reminder
                                  final updated = Reminder(
                                    id: r.id,
                                    petId: r.petId,
                                    title: r.title,
                                    category: r.category,
                                    scheduledAt: r.scheduledAt,
                                    done: !r.done,
                                  );
                                  await _dbService.updateReminder(updated);
                                  await _loadAllReminders();
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r.category} @ ${TimeOfDay.fromDateTime(r.scheduledAt).format(context)}',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}
