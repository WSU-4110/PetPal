// lib/ui/appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../state/app_state.dart';

class Appointment {
  final String id;
  final String vetName;
  final String clinicName;
  final DateTime dateTime;
  final String type;
  final String status;
  final int? vetId;

  Appointment({
    required this.id,
    required this.vetName,
    required this.clinicName,
    required this.dateTime,
    required this.type,
    required this.status,
    this.vetId,
  });
}

class AppointmentsScreen extends StatefulWidget {
  final Pet pet;

  const AppointmentsScreen({super.key, required this.pet});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final List<Appointment> _appointments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _appointments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _appointments.length + 1,
              itemBuilder: (context, index) {
                if (index == _appointments.length) {
                  return _buildBookNewButton();
                }
                return _buildAppointmentCard(_appointments[index]);
              },
            ),
      // Removed floatingActionButton to maintain swipe-back navigation
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
            'Book your first vet appointment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showBookAppointmentDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming = appointment.status == 'upcoming';
    final statusColor = isUpcoming ? const Color(0xFF4ECDC4) : Colors.grey;

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
          // Status & menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF9CA3AF)),
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
          // Vet & clinic info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF6C63FF),
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
                      appointment.vetName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.clinicName,
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
          // Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                _formatDate(appointment.dateTime),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.access_time,
                  size: 16, color: Color(0xFF9CA3AF)),
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

  Widget _buildBookNewButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: _showBookAppointmentDialog,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF6C63FF),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Book New Appointment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookAppointmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookAppointmentSheet(
        pet: widget.pet,
        onBooked: (appointment) {
          setState(() {
            _appointments.add(appointment);
          });
        },
      ),
    );
  }

  void _cancelAppointment(Appointment appointment) {
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
            onPressed: () {
              setState(() {
                _appointments.remove(appointment);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment cancelled')),
              );
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(Appointment appointment) {
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

// Book Appointment Bottom Sheet
class BookAppointmentSheet extends StatefulWidget {
  final Pet pet;
  final Function(Appointment) onBooked;

  const BookAppointmentSheet({
    super.key,
    required this.pet,
    required this.onBooked,
  });

  @override
  State<BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<BookAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedVetId;
  String? _selectedClinic;
  String? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<Map<String, dynamic>> _vets = [];
  bool _loadingVets = true;

  final _clinics = [
    'Pet Care Center',
    'Animal Hospital',
    'Veterinary Clinic Downtown',
    'Happy Paws Clinic',
  ];

  final _types = [
    'Check-up',
    'Vaccination',
    'Surgery',
    'Dental Care',
    'Emergency',
  ];

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final vets = await appState.getVeterinarians();
    setState(() {
      _vets = vets;
      _loadingVets = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 12,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Schedule a visit for ${widget.pet.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),

              // Appointment Type
              _buildDropdown(
                label: 'Appointment Type',
                value: _selectedType,
                items: _types,
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 12),

              // Clinic
              _buildDropdown(
                label: 'Clinic',
                value: _selectedClinic,
                items: _clinics,
                onChanged: (value) => setState(() => _selectedClinic = value),
              ),
              const SizedBox(height: 12),

              // Veterinarian - This loads from vet stakeholders
              _buildVetSelector(),
              const SizedBox(height: 12),

              // Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedDate != null
                                      ? const Color(0xFF2D3142)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Select Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedTime != null
                                      ? const Color(0xFF2D3142)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Book Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Veterinarian',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingVets)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_vets.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No veterinarians available',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedVetId,
            hint: const Text('Select a veterinarian'),
            items: _vets
                .map(
                  (vet) => DropdownMenuItem<int>(
                    value: vet['id'],
                    child: Text(
                      vet['name'] ?? 'Unknown Vet',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedVetId = value),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _bookAppointment() {
    if (_formKey.currentState!.validate()) {
      if (_selectedVetId == null ||
          _selectedClinic == null ||
          _selectedType == null ||
          _selectedDate == null ||
          _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Find the selected vet from the list
      final selectedVet = _vets.firstWhere(
        (vet) => vet['id'] == _selectedVetId,
        orElse: () => {'name': 'Unknown Vet'},
      );

      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vetName: selectedVet['name'] ?? 'Unknown Vet',
        clinicName: _selectedClinic!,
        dateTime: appointmentDate,
        type: _selectedType!,
        status: 'upcoming',
        vetId: _selectedVetId,
      );

      widget.onBooked(appointment);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully')),
      );
    }
  }
}