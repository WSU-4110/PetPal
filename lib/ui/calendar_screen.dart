// lib/ui/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/reminder.dart';
import '../services/db_service.dart';
import 'add_reminder_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
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
    if (mounted) {
      setState(() {
        _events = map;
        _isLoading = false;
        _selectedReminders.value = _getRemindersForDay(_selectedDay);
      });
    }
  }

  List<Reminder> _getRemindersForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Future<void> _addReminder() async {
    // Context check needed because showDialog is an async gap
    if (!mounted) return;
    
    final pets = await _dbService.getPets();
    
    if (!mounted) return;
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
    // Calculate alpha for opacity fixes (0.9 * 255 = 230, 0.1 * 255 = 25, 0.18 * 255 = 46, 0.15 * 255 = 38, 0.8 * 255 = 204)
    final int alpha90 = (0.9 * 255).round();
    final int alpha10 = (0.1 * 255).round();
    final int alpha18 = (0.18 * 255).round();
    final int alpha15 = (0.15 * 255).round();
    final int alpha80 = (0.8 * 255).round();

    if (_isLoading) {
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality if needed
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              // FIX: Replaced withOpacity with withAlpha
              color: Colors.black.withAlpha(alpha18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: null, // Disable hero animation completely
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _addReminder,
          child: const Icon(Icons.add, size: 30, color: Colors.white),
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
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // FIX: Replaced withOpacity with withAlpha
                  color: Colors.white.withAlpha(alpha90),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // FIX: Replaced withOpacity with withAlpha
                      color: Colors.black.withAlpha(alpha10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar<Reminder>(
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
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: Color(0xFFB892F7),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFFFAC4F1),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.pinkAccent,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(color: Colors.black87),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                    todayTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.black54),
                    outsideTextStyle: const TextStyle(color: Colors.black38),
                  ),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB892F7),
                      fontSize: 18,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFB892F7)),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFB892F7)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<List<Reminder>>(
                  valueListenable: _selectedReminders,
                  builder: (context, items, _) {
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'Nothing planned for today',
                          style: TextStyle(
                            // FIX: Replaced withOpacity with withAlpha
                            color: Colors.white.withAlpha(alpha90),
                            fontSize: 16,
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
                            // FIX: Replaced withOpacity with withAlpha
                            color: Colors.white.withAlpha(alpha15),
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
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r.category} @ ${TimeOfDay.fromDateTime(r.scheduledAt).format(context)}',
                                      style: TextStyle(
                                        // FIX: Replaced withOpacity with withAlpha
                                        color: Colors.white.withAlpha(alpha80),
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