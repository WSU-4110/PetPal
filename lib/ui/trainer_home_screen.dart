// lib/ui/trainer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dart:developer'; // Using dart:developer for logging


class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});
  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, upcoming, completed

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      final userId = appState.user?['id'] as int?;

      if (userId != null) {
        await appState.loadPet();
        final allPets = appState.pets;

        List<Map<String, dynamic>> allTrainingAppointments = [];

        for (final pet in allPets) {
          try {
            if (!mounted) return;
            // Assuming the return type of getTrainingAppointmentsForPet is now non-nullable List<Map<...>>.
            // If it returns null, the method signature in AppState/db needs to be checked.
            // For the sake of fixing the lint, we treat it as non-nullable here.
            final petAppointments =
                await appState.db.getTrainingAppointmentsForPet(pet.id!);

            // FIX: Removed unnecessary null check on petAppointments
            if (petAppointments.isNotEmpty) {
              allTrainingAppointments.addAll(petAppointments);
            }
          } catch (e) {
            log('Error loading training appointments for pet ${pet.id}: $e');
          }
        }

        final trainerAppointments = allTrainingAppointments.where((a) {
          final trainerId = a['trainerId'] ?? a['trainer_id'] ?? a['trainer'];
          if (trainerId is int) {
            return trainerId == userId;
          } else if (trainerId is String) {
            return int.tryParse(trainerId) == userId;
          }
          return false;
        }).toList();

        if (mounted) {
          setState(() {
            _appointments = trainerAppointments;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      log('Error loading trainer appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_filterStatus == 'all') {
      return _appointments;
    }
    return _appointments.where((a) => a['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final upcomingCount =
        _appointments.where((a) => a['status'] == 'upcoming').length;
    final completedCount =
        _appointments.where((a) => a['status'] == 'completed').length;

return Scaffold(
  backgroundColor: const Color(0xFFF5F7FA),
  appBar: AppBar(
    automaticallyImplyLeading: true, // <-- set to true so menu button appears
    backgroundColor: const Color(0xFFB892F7),
    elevation: 0,
    title: const Text(
      'Trainer Dashboard',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),


  body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : Column(
          children: [
            _buildHeader(upcomingCount, completedCount),
            _buildFilterChips(),
            Expanded(
              child: _filteredAppointments.isEmpty
                  ? _buildEmptyState()
                  : _buildAppointmentsList(),
            ),
          ],
        ),
);

  }

  Widget _buildHeader(int upcomingCount, int completedCount) {
    final appState = Provider.of<AppState>(context);
    final trainerName =
        '${appState.user?['firstName'] ?? ''} ${appState.user?['lastName'] ?? ''}'
            .trim();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFB892F7),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $trainerName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Upcoming',
                  upcomingCount.toString(),
                  Icons.schedule,
                  Colors.white,
                  const Color(0xFFB892F7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  completedCount.toString(),
                  Icons.check_circle,
                  Colors.white70,
                  const Color(0xFFB892F7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color,
      Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Upcoming', 'upcoming'),
          const SizedBox(width: 8),
          _buildFilterChip('Completed', 'completed'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFFF9F43).withAlpha((0.2 * 255).round()),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFB892F7) : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFB892F7) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No training sessions found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'all'
                ? 'Your training sessions will appear here'
                : 'No $_filterStatus sessions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final sortedAppointments =
        List<Map<String, dynamic>>.from(_filteredAppointments)
          ..sort((a, b) {
            final aDateStr = a['dateTime'] as String?;
            final bDateStr = b['dateTime'] as String?;

            if (aDateStr == null || bDateStr == null) return 0;

            try {
              final aDate = DateTime.parse(aDateStr);
              final bDate = DateTime.parse(bDateStr);
              return aDate.compareTo(bDate);
            } catch (e) {
              return 0;
            }
          });
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(sortedAppointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isUpcoming = appointment['status'] == 'upcoming';
    final statusColor = isUpcoming ? const Color(0xFFFF9F43) : Colors.grey;
    final dateTimeString = appointment['dateTime'] as String?;

    DateTime dateTime;
    try {
      dateTime = DateTime.parse(dateTimeString ?? '');
    } catch (e) {
      dateTime = DateTime.now(); // Fallback
      log('Error parsing dateTime: $dateTimeString. Error: $e');
    }

    final petId = appointment['petId'] as int?;
    String petName = 'Unknown';
    if (petId != null) {
      final pet = appState.getPetById(petId);
      petName = pet?.name ?? 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isUpcoming ? 'Upcoming' : 'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (isUpcoming)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                  onSelected: (value) {
                    if (value == 'complete') {
                      _completeAppointment(appointment);
                    } else if (value == 'cancel') {
                      _cancelAppointment(appointment);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 18, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Mark Complete'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['type'] ?? 'Unknown Training',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pet: $petName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment['facility'] ?? 'Unknown Facility',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                _formatDate(dateTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.access_time, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                _formatTime(dateTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _completeAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Training Session'),
        content: const Text('Mark this training session as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;
              final appState = Provider.of<AppState>(context, listen: false);

              try {
                final updatedAppointment =
                    Map<String, dynamic>.from(appointment);
                updatedAppointment['status'] = 'completed';

                await appState.db.updateTrainingAppointment(updatedAppointment);

                _loadAppointments();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Training session marked as completed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Training Session'),
        content:
            const Text('Are you sure you want to cancel this training session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;
              final appState = Provider.of<AppState>(context, listen: false);

              try {
                await appState.deleteTrainingAppointment(
                    appointment['id'].toString());

                _loadAppointments();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Training session cancelled')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}