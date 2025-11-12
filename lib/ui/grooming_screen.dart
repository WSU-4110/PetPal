// lib/ui/grooming_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../state/app_state.dart';

class GroomingAppointment {
  final String id;
  final String groomerName;
  final String salon;
  final DateTime dateTime;
  final String type;
  final String status;
  final int? groomerId;

  GroomingAppointment({
    required this.id,
    required this.groomerName,
    required this.salon,
    required this.dateTime,
    required this.type,
    required this.status,
    this.groomerId,
  });
}

class GroomingScreen extends StatefulWidget {
  final Pet pet;

  const GroomingScreen({super.key, required this.pet});

  @override
  State<GroomingScreen> createState() => _GroomingScreenState();
}

class _GroomingScreenState extends State<GroomingScreen> {
  final List<GroomingAppointment> _appointments = [];

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
          '${widget.pet.name}\'s Grooming',
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
            'No grooming appointments yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first grooming session',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showBookGroomingDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Book Grooming'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(GroomingAppointment appointment) {
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
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cut,
                  color: Color(0xFF4ECDC4),
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
                      appointment.groomerName,
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

  Widget _buildBookNewButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: _showBookGroomingDialog,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4ECDC4).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF4ECDC4),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Book New Grooming',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookGroomingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookGroomingSheet(
        pet: widget.pet,
        onBooked: (appointment) {
          setState(() {
            _appointments.add(appointment);
          });
        },
      ),
    );
  }

  void _cancelAppointment(GroomingAppointment appointment) {
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

  void _rescheduleAppointment(GroomingAppointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule feature coming soon')),
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

// Book Grooming Bottom Sheet
class BookGroomingSheet extends StatefulWidget {
  final Pet pet;
  final Function(GroomingAppointment) onBooked;

  const BookGroomingSheet({
    super.key,
    required this.pet,
    required this.onBooked,
  });

  @override
  State<BookGroomingSheet> createState() => _BookGroomingSheetState();
}

class _BookGroomingSheetState extends State<BookGroomingSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedGroomerId;
  String? _selectedSalon;
  String? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<Map<String, dynamic>> _groomers = [];
  bool _loadingGroomers = true;

  final _salons = [
    'Pampered Paws Salon',
    'Happy Tails Grooming',
    'Pet Spa Downtown',
    'Furry Friends Salon',
  ];

  final _types = [
    'Full Grooming',
    'Bath & Brush',
    'Haircut',
    'Nail Trim',
    'Teeth Cleaning',
  ];

  @override
  void initState() {
    super.initState();
    _loadGroomers();
  }

  Future<void> _loadGroomers() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final groomers = await appState.getGroomers();
    setState(() {
      _groomers = groomers;
      _loadingGroomers = false;
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
                'Book Grooming',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Schedule grooming for ${widget.pet.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),

              _buildDropdown(
                label: 'Service Type',
                value: _selectedType,
                items: _types,
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Salon',
                value: _selectedSalon,
                items: _salons,
                onChanged: (value) => setState(() => _selectedSalon = value),
              ),
              const SizedBox(height: 12),

              _buildGroomerSelector(),
              const SizedBox(height: 12),

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
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4ECDC4)),
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
                            const Icon(Icons.access_time, size: 18, color: Color(0xFF4ECDC4)),
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookGrooming,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Grooming',
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

  Widget _buildGroomerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Groomer',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 8),
        
        if (_loadingGroomers)
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
        else if (_groomers.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No groomers available',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedGroomerId,
            hint: const Text('Select a groomer'),
            items: _groomers
                .map(
                  (groomer) {
                    final firstName = groomer['firstName'] ?? '';
                    final lastName = groomer['lastName'] ?? '';
                    final displayName = '$firstName $lastName'.trim();
                    
                    return DropdownMenuItem<int>(
                      value: groomer['id'] as int,
                      child: Text(displayName),
                    );
                  },
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedGroomerId = value),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _bookGrooming() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGroomerId == null ||
          _selectedSalon == null ||
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

      // Find the selected groomer from the list
      final selectedGroomer = _groomers.firstWhere(
        (groomer) => groomer['id'] == _selectedGroomerId,
        orElse: () => {'firstName': 'Unknown', 'lastName': 'Groomer'},
      );

      final firstName = selectedGroomer['firstName'] ?? '';
      final lastName = selectedGroomer['lastName'] ?? '';
      final groomerName = '$firstName $lastName'.trim();

      final appointment = GroomingAppointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groomerName: groomerName,
        salon: _selectedSalon!,
        dateTime: appointmentDate,
        type: _selectedType!,
        status: 'upcoming',
        groomerId: _selectedGroomerId,
      );

      widget.onBooked(appointment);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grooming appointment booked successfully!')),
      );
    }
  }
}