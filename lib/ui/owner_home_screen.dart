// lib/ui/owner_home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/appointment.dart';
import 'pet_details_screen.dart';
import 'appointments_screen.dart';
import 'notification_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentTipIndex = 0;
  List<String> _tips = [];
  Timer? _tipTimer;
  late AppState _appState;
  bool _appStateListenerAttached = false;

  @override
  void initState() {
    super.initState();
    
    // It's safe to read provider with listen: false here
    _appState = Provider.of<AppState>(context, listen: false);
    _tips = _safeGetTips(_appState);
    _startTipRotation();

    // Attach listener once to update tips when AppState notifies
    if (!_appStateListenerAttached) {
      _appState.addListener(_onAppStateChanged);
      _appStateListenerAttached = true;
    }
  }

  // Helper to safely read tips from AppState
  List<String> _safeGetTips(AppState appState) {
    try {
      final tips = appState.getTips();
      return tips ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  void _onAppStateChanged() {
    final newTips = _safeGetTips(_appState);
    if (!_listEquals(newTips, _tips)) {
      setState(() {
        _tips = newTips;
        _currentTipIndex = 0;
      });
      _startTipRotation();
    }
  }

  void _startTipRotation() {
    _tipTimer?.cancel();
    if (_tips.isEmpty) return;

    if (_currentTipIndex >= _tips.length) _currentTipIndex = 0;

    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
      });
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    if (_appStateListenerAttached) {
      try {
        _appState.removeListener(_onAppStateChanged);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pets = appState.pets;

    // Get user name safely
    String userName = 'there';
    try {
      final dyn = appState as dynamic;
      if (dyn.currentUser != null) {
        final user = Map<String, dynamic>.from(dyn.currentUser);
        userName = user['firstName'] ?? user['first_name'] ?? 'there';
      }
    } catch (_) {}

    // Today's reminders
    final today = DateTime.now();
    final todayReminders = appState.reminders.where((r) {
      return r.scheduledAt.year == today.year &&
          r.scheduledAt.month == today.month &&
          r.scheduledAt.day == today.day;
    }).toList();

    // Get upcoming appointments
    final now = DateTime.now();
    final upcomingAppointments = appState.appointments
        .where((a) => a.dateTime.isAfter(now) && a.status == 'upcoming')
        .toList();
    upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    // Determine tip text to display (always render the box)
    final String tipText = _tips.isNotEmpty
        ? _tips[_currentTipIndex]
        : 'Pet care tips will appear here.';

    return Scaffold(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row header: greeting + notification icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi $userName,',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Let's take a good care of your cutie pets!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Pet Cards or empty state - MODIFIED FOR CENTERING SINGLE PET
              if (pets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: const [
                        SizedBox(height: 40),
                        Icon(Icons.pets, size: 80, color: Colors.white70),
                        SizedBox(height: 16),
                        Text(
                          'No pets yet',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                )
              else if (pets.length == 1)
                // Center single pet card
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _buildPetCard(pets[0], 0),
                  ),
                )
              else
                // Horizontal scroll for multiple pets
                SizedBox(
                  height: 200,
                  child: ScrollConfiguration(
                    behavior:
                        ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: index < pets.length - 1 ? 24 : 0),
                          child: _buildPetCard(pets[index], index),
                        );
                      },
                    ),
                  ),
                ),

              // Tip box — always visible (shows placeholder when no tips available)
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lightbulb icon (as in screenshot)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Tip text (left aligned, can wrap) - FIXED ANIMATION
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.3),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            tipText,
                            key: ValueKey<String>(tipText),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main area: To-dos and Upcoming events
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          "Today's To-Dos",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (todayReminders.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 40, color: Colors.white70),
                                const SizedBox(width: 16),
                                const Text(
                                  'No tasks for today!',
                                  style: TextStyle(fontSize: 16, color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        else
                          ...todayReminders.map((r) => _buildTodoItem(r, appState)),

                        const SizedBox(height: 32),
                        const Text(
                          "Upcoming Events",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildUpcomingEvent(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pet card builder
  Widget _buildPetCard(Pet pet, int index) {
    final badgeNumber = index + 1;
    final colors = [
      {'bg': const Color(0xFFFFE5F1), 'badge': const Color(0xFFFF69B4)},
      {'bg': const Color(0xFFE3F2FD), 'badge': const Color(0xFF42A5F5)},
      {'bg': const Color(0xFFFFF3E0), 'badge': const Color(0xFFFF9800)},
      {'bg': const Color(0xFFE8F5E9), 'badge': const Color(0xFF4CAF50)},
    ];
    final colorSet = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: pet)),
        );
      },
      child: Container(
        width: 160,
        height: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorSet['badge'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$badgeNumber',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: colorSet['bg'], shape: BoxShape.circle),
              child: _buildPetAvatar(pet),
            ),
            Text(
              pet.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetAvatar(Pet pet) {
    final image = pet.image;
    if (image == null || image.isEmpty) {
      return const Icon(Icons.pets, size: 40, color: Colors.white70);
    }
    if (image.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          image,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: Colors.white70),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        image,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: Colors.white70),
      ),
    );
  }

  Widget _buildTodoItem(Reminder reminder, AppState appState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
          vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildReminderIcon(reminder),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.white,
                    decoration: reminder.done ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPetNameForReminder(reminder, appState),
                  style: TextStyle(
                    fontSize: 14, 
                    color: reminder.done ? Colors.white54 : Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder.scheduledAt.hour.toString().padLeft(2, '0')}:${reminder.scheduledAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14, 
                    color: reminder.done ? Colors.white54 : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Custom circle checkbox with confirmation dialog
          GestureDetector(
            onTap: () {
              if (reminder.done) {
                _showUncompleteTaskDialog(reminder, appState);
              } else {
                _showCompleteTaskDialog(reminder, appState);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: reminder.done ? Colors.white : Colors.white70,
                  width: 2,
                ),
                color: reminder.done ? Colors.white : Colors.transparent,
              ),
              child: reminder.done
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFFB892F7),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

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
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5D9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFFFF6B6B), size: 24),
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

  void _showCompleteTaskDialog(Reminder reminder, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB892F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Complete Task?',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            'Mark "${reminder.title}" as done?',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final updated = Reminder(
                  id: reminder.id,
                  petId: reminder.petId,
                  title: reminder.title,
                  category: reminder.category,
                  scheduledAt: reminder.scheduledAt,
                  done: true,
                );
                await appState.updateReminder(updated);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB892F7),
              ),
              child: const Text('Mark as Done', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showUncompleteTaskDialog(Reminder reminder, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB892F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.replay, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Mark as Incomplete?',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            'Unmark "${reminder.title}"?',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final updated = Reminder(
                  id: reminder.id,
                  petId: reminder.petId,
                  title: reminder.title,
                  category: reminder.category,
                  scheduledAt: reminder.scheduledAt,
                  done: false,
                );
                await appState.updateReminder(updated);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB892F7),
              ),
              child: const Text('Mark as Incomplete', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingEvent() {
    final appState = Provider.of<AppState>(context);
    final now = DateTime.now();
    
    // Get upcoming appointments
    final upcomingAppointments = appState.appointments
        .where((a) => a.dateTime.isAfter(now) && a.status == 'upcoming')
        .toList();
    
    upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    if (upcomingAppointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.event_available, size: 40, color: Colors.white70),
            const SizedBox(width: 16),
            const Text(
              'No upcoming events',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
    // Show the next upcoming appointment
    final nextAppointment = upcomingAppointments.first;
    final pet = appState.getPetById(nextAppointment.petId);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextAppointment.type,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet?.name ?? 'Unknown Pet',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextAppointment.vetName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nextAppointment.clinicName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                _formatAppointmentDate(nextAppointment.dateTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                _formatAppointmentTime(nextAppointment.dateTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAppointmentDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _formatAppointmentTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}