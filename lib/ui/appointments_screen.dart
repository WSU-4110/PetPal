import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/appointment.dart';
import '../state/app_state.dart';

enum AppointmentType { vet, grooming, training }

class UnifiedAppointment {
  final String id;
  final String name;
  final String location;
  final DateTime dateTime;
  final String type;
  final String status;
  final AppointmentType appointmentType;
  final String? professionalId;

  UnifiedAppointment({
    required this.id,
    required this.name,
    required this.location,
    required this.dateTime,
    required this.type,
    required this.status,
    required this.appointmentType,
    this.professionalId,
  });
}

class AppointmentsScreen extends StatefulWidget {
  final Pet pet;
  const AppointmentsScreen({super.key, required this.pet});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<UnifiedAppointment> _allAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAppointments();
  }

  @override
  void didUpdateWidget(AppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh appointments when the widget is updated
    _loadAllAppointments();
  }

  Future<void> _loadAllAppointments() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      // Load vet appointments
      await appState.loadAppointmentsForPet(widget.pet.id!);
      final vetAppointments = appState.getAppointmentsForPetLocal(widget.pet.id!)
          .map((a) => UnifiedAppointment(
                id: a.id.toString(),
                name: a.vetName,
                location: a.clinicName,
                dateTime: a.dateTime,
                type: a.type,
                status: a.status,
                appointmentType: AppointmentType.vet,
                professionalId: a.vetId.toString(),
              ))
          .toList();

      // Load grooming appointments
      await appState.loadGroomingAppointmentsForPet(widget.pet.id!);
      final groomingAppointments = appState.getGroomingAppointmentsForPetLocal(widget.pet.id!)
          .map((a) => UnifiedAppointment(
                id: a['id'].toString(),
                name: a['groomerName'] ?? 'Unknown Groomer',
                location: a['salon'] ?? 'Unknown Salon',
                dateTime: DateTime.parse(a['dateTime']),
                type: a['type'] ?? 'Unknown Type',
                status: a['status'] ?? 'upcoming',
                appointmentType: AppointmentType.grooming,
                professionalId: a['groomerId']?.toString(),
              ))
          .toList();

      // Load training appointments
      await appState.loadTrainingAppointmentsForPet(widget.pet.id!);
      final trainingAppointments = appState.getTrainingAppointmentsForPetLocal(widget.pet.id!)
          .map((a) => UnifiedAppointment(
                id: a['id'].toString(),
                name: a['trainerName'] ?? 'Unknown Trainer',
                location: a['facility'] ?? 'Unknown Facility',
                dateTime: DateTime.parse(a['dateTime']),
                type: a['type'] ?? 'Unknown Type',
                status: a['status'] ?? 'upcoming',
                appointmentType: AppointmentType.training,
                professionalId: a['trainerId']?.toString(),
              ))
          .toList();

      final allAppointments = [...vetAppointments, ...groomingAppointments, ...trainingAppointments];
      allAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (mounted) {
        setState(() {
          _allAppointments = allAppointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.pet.name}\'s Appointments',
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allAppointments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _allAppointments.length,
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(_allAppointments[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your appointments will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(UnifiedAppointment appointment) {
    final isUpcoming = appointment.status == 'upcoming';
    final statusColor = isUpcoming
        ? appointment.appointmentType == AppointmentType.vet
            ? const Color(0xFF6C63FF)
            : appointment.appointmentType == AppointmentType.grooming
                ? const Color(0xFF4ECDC4)
                : const Color(0xFFFF9F43)
        : Colors.grey;
    final icon = appointment.appointmentType == AppointmentType.vet
        ? Icons.medical_services
        : appointment.appointmentType == AppointmentType.grooming
            ? Icons.cut
            : Icons.fitness_center;
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
                    if (value == 'cancel') {
                      _cancelAppointment(appointment);
                    } else if (value == 'reschedule') {
                      _rescheduleAppointment(appointment);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Reschedule'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 18),
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
                  icon,
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
                      appointment.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.location,
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

  void _cancelAppointment(UnifiedAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
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
                if (appointment.appointmentType == AppointmentType.vet) {
                  await appState.deleteAppointment(int.parse(appointment.id));
                } else if (appointment.appointmentType == AppointmentType.grooming) {
                  await appState.deleteGroomingAppointment(appointment.id);
                } else if (appointment.appointmentType == AppointmentType.training) {
                  await appState.deleteTrainingAppointment(appointment.id);
                }
                
                // Refresh the appointments list
                _loadAllAppointments();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling appointment: $e')),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(UnifiedAppointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule feature coming soon')),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

