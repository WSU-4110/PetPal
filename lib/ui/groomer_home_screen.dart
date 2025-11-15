// lib/ui/groomer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class GroomerAppointment {
  final String id;
  final String groomerName;
  final String salon;
  final DateTime dateTime;
  final String type;
  final String status;
  final int? groomerId;
  final String? petName;
  final int? petId;

  GroomerAppointment({
    required this.id,
    required this.groomerName,
    required this.salon,
    required this.dateTime,
    required this.type,
    required this.status,
    this.groomerId,
    this.petName,
    this.petId,
  });
}

class GroomerHomeScreen extends StatefulWidget {
  const GroomerHomeScreen({super.key});

  @override
  State<GroomerHomeScreen> createState() => _GroomerHomeScreenState();
}

class _GroomerHomeScreenState extends State<GroomerHomeScreen> {
  List<GroomerAppointment> _appointments = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, upcoming, completed

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      // Use user['id'] instead of currentUserId
      final groomerId = appState.user?['id'] as int?;
      if (groomerId != null) {
        // Load all pets to get their grooming appointments
        await appState.loadPet();
        final allPets = appState.pets;
        
        // Collect all grooming appointments for all pets
        List<Map<String, dynamic>> allGroomingAppointments = [];
        
        for (final pet in allPets) {
          try {
            final petAppointments = await appState.db.getGroomingAppointmentsForPet(pet.id!);
            allGroomingAppointments.addAll(petAppointments);
          } catch (e) {
            print('Error loading grooming appointments for pet ${pet.id}: $e');
          }
        }
        
        // Filter for this groomer
        final groomerAppointments = allGroomingAppointments.where((a) => a['groomerId'] == groomerId).toList();
        
        if (mounted) {
          setState(() {
            _appointments = groomerAppointments.map((a) => GroomerAppointment(
              id: a['id'].toString(),
              groomerName: a['groomerName'] ?? 'Unknown Groomer',
              salon: a['salon'] ?? 'Unknown Salon',
              dateTime: DateTime.parse(a['dateTime']),
              type: a['type'] ?? 'Unknown Type',
              status: a['status'] ?? 'upcoming',
              groomerId: a['groomerId'] as int?,
              petName: a['petName'] as String?,
              petId: a['petId'] as int?,
            )).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading groomer appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GroomerAppointment> get _filteredAppointments {
    if (_filterStatus == 'all') {
      return _appointments;
    }
    return _appointments.where((a) => a.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final upcomingCount = _appointments.where((a) => a.status == 'upcoming').length;
    final completedCount = _appointments.where((a) => a.status == 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4ECDC4),
        elevation: 0,
        title: const Text(
          'Groomer Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAppointments,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              appState.logout();
            },
          ),
        ],
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
    final groomerName = '${appState.currentUser?['firstName'] ?? ''} ${appState.currentUser?['lastName'] ?? ''}'.trim();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF4ECDC4),
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
            'Welcome back, $groomerName',
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
                  const Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  completedCount.toString(),
                  Icons.check_circle,
                  Colors.white70,
                  const Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
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
      selectedColor: const Color(0xFF4ECDC4).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[300]!,
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
            Icons.cut,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'all'
                ? 'Your appointments will appear here'
                : 'No $_filterStatus appointments',
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
    // Sort appointments by date
    final sortedAppointments = List<GroomerAppointment>.from(_filteredAppointments)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sortedAppointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(sortedAppointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(GroomerAppointment appointment) {
    final appState = Provider.of<AppState>(context);
    final isUpcoming = appointment.status == 'upcoming';
    final statusColor = isUpcoming ? const Color(0xFF4ECDC4) : Colors.grey;
    
    // Get pet name from the app state if not already available
    String petName = appointment.petName ?? 'Unknown';
    if (petName == 'Unknown' && appointment.petId != null) {
      final pet = appState.getPetById(appointment.petId);
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
            color: Colors.black.withOpacity(0.05),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
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
                          Icon(Icons.check_circle, size: 18, color: Colors.green),
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cut,
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
                      appointment.type,
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
                      appointment.salon,
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
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                _formatDate(appointment.dateTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.access_time, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                _formatTime(appointment.dateTime),
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

  void _completeAppointment(GroomerAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: const Text('Mark this grooming appointment as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final appState = Provider.of<AppState>(context, listen: false);
              
              try {
                // Create a map of the appointment with updated status
                final updatedAppointment = {
                  'id': appointment.id,
                  'groomerId': appointment.groomerId,
                  'groomerName': appointment.groomerName,
                  'salon': appointment.salon,
                  'dateTime': appointment.dateTime.toIso8601String(),
                  'type': appointment.type,
                  'status': 'completed',
                  'petId': appointment.petId,
                  'petName': appointment.petName,
                };
                
                // Update the appointment in the database
                await appState.db.updateGroomingAppointment(updatedAppointment);
                
                // Reload appointments
                _loadAppointments();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment marked as completed'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(GroomerAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this grooming appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final appState = Provider.of<AppState>(context, listen: false);
              
              try {
                // Delete the appointment from the database
                await appState.deleteGroomingAppointment(appointment.id);
                
                // Reload appointments
                _loadAppointments();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}