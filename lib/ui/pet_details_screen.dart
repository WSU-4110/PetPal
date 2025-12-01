import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/appointment.dart';
import '../state/app_state.dart';
import 'appointments_screen.dart';
import 'grooming_screen.dart';
import 'training_screen.dart';
import 'gallery_screen.dart';
import 'health_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicalRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load medical records for this pet
  Future<void> _loadMedicalRecords() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.loadMedicalRecords(widget.pet.id!);
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    }
  }

  Future<void> _refreshData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.loadAppointmentsForPet(widget.pet.id!);
      await appState.loadGroomingAppointmentsForPet(widget.pet.id!);
      await appState.loadTrainingAppointmentsForPet(widget.pet.id!);
      await appState.loadMedicalRecords(widget.pet.id!);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  String _formatDateShort(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[date.month - 1];
    return '$m ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final yearsOld = pet.age;
    final appState = Provider.of<AppState>(context);
    final isVet = appState.currentUser?['role'] == 'vet';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pet Details',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isVet)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
              onPressed: () {
                _tabController.animateTo(0);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF42A5F5).withAlpha((0.2 * 255).round()),
                    border: Border.all(
                      color: const Color(0xFF42A5F5),
                      width: 3,
                    ),
                  ),
                  child: _buildPetAvatar(pet),
                ),
                const SizedBox(height: 16),
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pets, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      '${pet.species} • ${pet.breed}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cake, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      '$yearsOld years old',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                if (pet.birthdate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateShort(pet.birthdate!),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      pet.gender.toLowerCase() == 'male'
                          ? Icons.male
                          : (pet.gender.toLowerCase() == 'female' ? Icons.female : Icons.pets),
                      size: 16,
                      color: const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pet.gender,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Three action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite,
                      label: 'Book\nVet',
                      color: const Color(0xFFFF6B6B),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BookAppointmentScreen(pet: pet)),
                        );
                        await _refreshData();
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.cut,
                      label: 'Book\nGrooming',
                      color: const Color(0xFF4ECDC4),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GroomingScreen(pet: pet)),
                        );
                        await _refreshData();
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.fitness_center,
                      label: 'Book\nTrainer',
                      color: const Color(0xFFFFB74D),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TrainingScreen(pet: pet)),
                        );
                        await _refreshData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF6B6B),
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: const Color(0xFFFF6B6B),
              tabs: const [
                Tab(icon: Icon(Icons.favorite), text: 'Health'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Appointments'),
                Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HealthTabScreen(pet: pet),
                AppointmentsScreen(pet: pet),
                GalleryScreen(pet: pet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar(Pet pet) {
    final image = pet.image;
    if (image == null || image.isEmpty) {
      return const Icon(Icons.pets, size: 60, color: Color(0xFF42A5F5));
    }
    if (image.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          image,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 60, color: Color(0xFF42A5F5)),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        image,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 60, color: Color(0xFF42A5F5)),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookAppointmentScreen extends StatefulWidget {
  final Pet pet;

  const BookAppointmentScreen({super.key, required this.pet});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.loadAppointmentsForPet(widget.pet.id!);
      final appointments = appState.getAppointmentsForPetLocal(widget.pet.id!);
      if (mounted) {
        setState(() {
          _appointments
            ..clear()
            ..addAll(appointments);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
          '${widget.pet.name}\'s Vet Appointments',
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
            onPressed: _showBookAppointmentDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
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
          Icon(Icons.calendar_today, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Book your first appointment', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showBookAppointmentDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Book Appointment'),
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
            border: Border.all(color: const Color(0xFF6C63FF).withAlpha((0.3 * 255).round()), width: 2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF), size: 28),
              SizedBox(width: 12),
              Text('Book New Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C63FF))),
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
        onBooked: (appointment) async {
          final messenger = ScaffoldMessenger.of(context);
          final appState = Provider.of<AppState>(context, listen: false);
          try {
            await appState.addAppointment(appointment);
            await _loadAppointments();
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(content: Text('Appointment booked successfully!'), backgroundColor: Colors.green),
            );
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('Error saving appointment: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming = appointment.status == 'upcoming';
    final statusColor = isUpcoming ? const Color(0xFF6C63FF) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.05 * 255).round()), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(20)),
            child: Text(isUpcoming ? 'Upcoming' : 'Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor))),
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
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'reschedule', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Reschedule')])),
                PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel, size: 18), SizedBox(width: 8), Text('Cancel')])),
              ],
            ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medical_services, color: Color(0xFF6C63FF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appointment.type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 4),
              Text(appointment.vetName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(appointment.clinicName, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(_formatDate(appointment.dateTime), style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(width: 20),
          const Icon(Icons.access_time, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(_formatTime(appointment.dateTime), style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        ]),
      ]),
    );
  }

  void _cancelAppointment(Appointment appointment) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('No')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(dialogContext);
              
              navigator.pop();
              
              try {
                await appState.deleteAppointment(appointment.id!);
                await _loadAppointments();
                
                if (!mounted) return;
                
                messenger.showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
              } catch (e) {
                if (!mounted) return;
                
                messenger.showSnackBar(SnackBar(content: Text('Error cancelling appointment: $e')));
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reschedule feature coming soon')));
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

// Book Appointment Bottom Sheet
class BookAppointmentSheet extends StatefulWidget {
  final Pet pet;
  final Function(Appointment) onBooked;

  const BookAppointmentSheet({super.key, required this.pet, required this.onBooked});

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
  bool _isSubmitting = false;

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
    try {
      final vets = await appState.getVeterinarians();
      if (mounted) {
        setState(() {
          _vets = vets;
          _loadingVets = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vets: $e');
      if (mounted) setState(() => _loadingVets = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 12),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Book Appointment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 4),
            Text('Schedule a visit for ${widget.pet.name}', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 16),
            _buildDropdown(label: 'Appointment Type', value: _selectedType, items: _types, onChanged: (v) => setState(() => _selectedType = v)),
            const SizedBox(height: 12),
            _buildDropdown(label: 'Clinic', value: _selectedClinic, items: _clinics, onChanged: (v) => setState(() => _selectedClinic = v)),
            const SizedBox(height: 12),
            _buildVetSelector(),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : 'Select Date',
                          style: TextStyle(fontSize: 14, color: _selectedDate != null ? const Color(0xFF2D3142) : const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.access_time, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                          style: TextStyle(fontSize: 14, color: _selectedTime != null ? const Color(0xFF2D3142) : const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Widget _buildVetSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Veterinarian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
      const SizedBox(height: 8),
      if (_loadingVets)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        )
      else if (_vets.isEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withAlpha((0.1 * 255).round()), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6C63FF).withAlpha((0.3 * 255).round()))),
          child: const Row(children: [Icon(Icons.warning, color: Color(0xFF6C63FF)), SizedBox(width: 8), Expanded(child: Text('No veterinarians available', style: TextStyle(color: Color(0xFF6C63FF))))]),
        )
      else
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.grey[50]),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedVetId,
              hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Select a veterinarian')),
              isExpanded: true,
              items: _vets.map((vet) {
                final firstName = vet['firstName'] ?? '';
                final lastName = vet['lastName'] ?? '';
                final displayName = 'Dr. $firstName $lastName'.trim();
                return DropdownMenuItem<int>(value: vet['id'] as int, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(displayName)));
              }).toList(),
              onChanged: (value) => setState(() => _selectedVetId = value),
            ),
          ),
        ),
    ]);
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12), color: Colors.grey[50]),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Select...')),
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem<String>(value: e, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(e)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: DateTime(now.year + 2));
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _bookAppointment() async {
    final messenger = ScaffoldMessenger.of(context);
    
    if (_selectedVetId == null || _selectedClinic == null || _selectedType == null || _selectedDate == null || _selectedTime == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appointmentDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      final selectedVet = _vets.firstWhere((vet) => vet['id'] == _selectedVetId, orElse: () => {'firstName': 'Unknown', 'lastName': 'Vet'});
      final firstName = selectedVet['firstName'] ?? '';
      final lastName = selectedVet['lastName'] ?? '';
      final vetName = 'Dr. $firstName $lastName'.trim();
      final appointmentId = DateTime.now().millisecondsSinceEpoch;

      final appointment = Appointment(
        id: appointmentId,
        petId: widget.pet.id!,
        vetId: _selectedVetId!,
        vetName: vetName,
        clinicName: _selectedClinic!,
        dateTime: appointmentDate,
        type: _selectedType!,
        status: 'upcoming',
      );

      widget.onBooked(appointment);

      if (!mounted) return;
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}