// lib/ui/vet_pet_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';
import '../state/app_state.dart';

class VetPetDetailsScreen extends StatefulWidget {
  final Pet pet;
  final int initialTab; // 0 for medical records, 1 for health info
  const VetPetDetailsScreen({super.key, required this.pet, this.initialTab = 0});

  @override
  State<VetPetDetailsScreen> createState() => _VetPetDetailsScreenState();
}

class _VetPetDetailsScreenState extends State<VetPetDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MedicalRecord> _medicalRecords = [];
  Map<String, dynamic>? _healthInfo;
  bool _isLoading = true;
  bool _isVet = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.initialTab;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Check user role
    setState(() {
      _isVet = appState.currentUser?['role'] == 'vet';
      _isOwner = appState.currentUser?['role'] == 'owner';
    });

    try {
      // Load medical records for this pet
      await appState.loadMedicalRecords(widget.pet.id!);

      // Load health info for this pet from database
      _healthInfo = await appState.getPetHealthInfo(widget.pet.id!);

      if (mounted) {
        setState(() {
          _medicalRecords = appState.medicalRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: Text(
          '${widget.pet.name} - Health Records',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Pet info header
                _buildPetInfoHeader(),

                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF6C63FF),
                    unselectedLabelColor: const Color(0xFF9CA3AF),
                    indicatorColor: const Color(0xFF6C63FF),
                    tabs: const [
                      Tab(text: 'Medical Records', icon: Icon(Icons.medical_services)),
                      Tab(text: 'Health Info', icon: Icon(Icons.favorite)),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMedicalRecordsTab(),
                      _buildHealthInfoTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _isVet ? FloatingActionButton(
        onPressed: _showAddRecordDialog,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildPetInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF6C63FF),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: _buildPetAvatar(widget.pet),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pet.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.pet.species} • ${widget.pet.breed}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.pet.age} years old • ${widget.pet.gender}',
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
    );
  }

  Widget _buildPetAvatar(Pet pet) {
    final image = pet.image;
    if (image == null || image.isEmpty) {
      return const Icon(Icons.pets, size: 40, color: Colors.white);
    }
    if (image.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          image,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: Colors.white),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        image,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: Colors.white),
      ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    if (_medicalRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No medical records yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add medical records after checkups and procedures',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _medicalRecords.length,
      itemBuilder: (context, index) {
        return _buildMedicalRecordCard(_medicalRecords[index]);
      },
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    final statusColors = {
      'Normal': const Color(0xFF4ECDC4),
      'Attention': const Color(0xFFFFA726),
      'Critical': const Color(0xFFEF5350),
    };
    final statusColor = statusColors[record.status] ?? const Color(0xFF9CA3AF);
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
          // Header with title and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  record.status ?? 'Normal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              // Menu button for vets
              if (_isVet)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditRecordDialog(record);
                    } else if (value == 'delete') {
                      _deleteRecord(record);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Description section
          if (record.description != null && record.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],

          // Details section
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Date and vet row
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(record.date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                if (record.weight != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.monitor_weight, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Text(
                        '${record.weight} kg',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoTab() {
    // Default values if health info is not available
    final lastCheckup = _healthInfo?['lastCheckup'];
    final vaccinationStatus = _healthInfo?['vaccinationStatus'] ?? 'Not recorded';
    final nextVaccinationDue = _healthInfo?['nextVaccinationDue'];
    final allergies = _healthInfo?['allergies'];
    final medications = _healthInfo?['medications'];
    final notes = _healthInfo?['notes'];

    // Additional fields to match health screen
    final diet = _healthInfo?['diet'] ?? 'Not recorded';
    final weight = _healthInfo?['weight'] ?? 'Not recorded';
    final activityLevel = _healthInfo?['activityLevel'] ?? 'Not recorded';
    final behavior = _healthInfo?['behavior'] ?? 'Not recorded';
    final specialNeeds = _healthInfo?['specialNeeds'] ?? 'Not recorded';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit button for vets
          if (_isVet)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: _showEditHealthInfoDialog,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Health Information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Basic Health Info
          _buildHealthInfoRow(
            'Last Checkup',
            lastCheckup != null ? _formatDate(lastCheckup) : 'Not recorded',
            Icons.calendar_today,
          ),

          _buildHealthInfoRow(
            'Vaccination Status',
            vaccinationStatus,
            Icons.vaccines,
          ),

          if (nextVaccinationDue != null)
            _buildHealthInfoRow(
              'Next Vaccination Due',
              _formatDate(nextVaccinationDue),
              Icons.event,
            ),

          // Physical Information
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          _buildHealthInfoRow(
            'Weight',
            weight,
            Icons.monitor_weight,
          ),

          _buildHealthInfoRow(
            'Diet',
            diet,
            Icons.restaurant,
          ),

          _buildHealthInfoRow(
            'Activity Level',
            activityLevel,
            Icons.directions_run,
          ),

          // Health Conditions
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          if (allergies != null && allergies.toString().isNotEmpty)
            _buildHealthInfoRow(
              'Allergies',
              allergies.toString(),
              Icons.warning,
            ),

          if (medications != null && medications.toString().isNotEmpty)
            _buildHealthInfoRow(
              'Current Medications',
              medications.toString(),
              Icons.medication,
            ),

          if (specialNeeds != null && specialNeeds.toString().isNotEmpty)
            _buildHealthInfoRow(
              'Special Needs',
              specialNeeds.toString(),
              Icons.accessibility_new,
            ),

          // Behavioral Information
          if (behavior != null && behavior.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            _buildHealthInfoRow(
              'Behavior',
              behavior.toString(),
              Icons.psychology,
            ),
          ],

          // Notes
          if (notes != null && notes.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditHealthInfoDialog() {
    // Initialize controllers with current values
    final lastCheckupController = TextEditingController(
      text: _healthInfo?['lastCheckup'] != null ? _formatDate(_healthInfo!['lastCheckup']) : '',
    );
    final vaccinationStatusController = TextEditingController(
      text: _healthInfo?['vaccinationStatus'] ?? '',
    );
    final nextVaccinationDueController = TextEditingController(
      text: _healthInfo?['nextVaccinationDue'] != null ? _formatDate(_healthInfo!['nextVaccinationDue']) : '',
    );
    final allergiesController = TextEditingController(
      text: _healthInfo?['allergies'] ?? '',
    );
    final medicationsController = TextEditingController(
      text: _healthInfo?['medications'] ?? '',
    );
    final notesController = TextEditingController(
      text: _healthInfo?['notes'] ?? '',
    );

    // Additional fields to match health screen
    final dietController = TextEditingController(
      text: _healthInfo?['diet'] ?? '',
    );
    final weightController = TextEditingController(
      text: _healthInfo?['weight'] ?? '',
    );
    final activityLevelController = TextEditingController(
      text: _healthInfo?['activityLevel'] ?? '',
    );
    final behaviorController = TextEditingController(
      text: _healthInfo?['behavior'] ?? '',
    );
    final specialNeedsController = TextEditingController(
      text: _healthInfo?['specialNeeds'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Health Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Basic Health Info
              const Text(
                'Basic Health Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: lastCheckupController,
                decoration: const InputDecoration(
                  labelText: 'Last Checkup Date',
                  hintText: 'e.g., Jan 15, 2023',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _healthInfo?['lastCheckup'] ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    lastCheckupController.text = _formatDate(date);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vaccinationStatusController,
                decoration: const InputDecoration(
                  labelText: 'Vaccination Status',
                  hintText: 'e.g., Up to date',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nextVaccinationDueController,
                decoration: const InputDecoration(
                  labelText: 'Next Vaccination Due',
                  hintText: 'e.g., Jan 15, 2024',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _healthInfo?['nextVaccinationDue'] ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    nextVaccinationDueController.text = _formatDate(date);
                  }
                },
              ),

              // Physical Information
              const SizedBox(height: 16),
              const Text(
                'Physical Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'e.g., 15.5 kg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dietController,
                decoration: const InputDecoration(
                  labelText: 'Diet',
                  hintText: 'e.g., Regular adult dog food',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: activityLevelController,
                decoration: const InputDecoration(
                  labelText: 'Activity Level',
                  hintText: 'e.g., High, Medium, Low',
                  border: OutlineInputBorder(),
                ),
              ),

              // Health Conditions
              const SizedBox(height: 16),
              const Text(
                'Health Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'e.g., Chicken, Dust mites',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: medicationsController,
                decoration: const InputDecoration(
                  labelText: 'Current Medications',
                  hintText: 'e.g., Antibiotics, Pain relief',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialNeedsController,
                decoration: const InputDecoration(
                  labelText: 'Special Needs',
                  hintText: 'e.g., Mobility assistance, Special diet',
                  border: OutlineInputBorder(),
                ),
              ),

              // Behavioral Information
              const SizedBox(height: 16),
              const Text(
                'Behavioral Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: behaviorController,
                decoration: const InputDecoration(
                  labelText: 'Behavior',
                  hintText: 'e.g., Friendly with other dogs, anxious during storms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Parse dates
              DateTime? lastCheckup;
              DateTime? nextVaccinationDue;

              if (lastCheckupController.text.isNotEmpty) {
                try {
                  lastCheckup = _parseDate(lastCheckupController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid date format for last checkup')),
                  );
                  return;
                }
              }

              if (nextVaccinationDueController.text.isNotEmpty) {
                try {
                  nextVaccinationDue = _parseDate(nextVaccinationDueController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid date format for next vaccination due')),
                  );
                  return;
                }
              }

              final appState = Provider.of<AppState>(context, listen: false);

              // Update health information with all fields
              await appState.updatePetHealthInfo(
                widget.pet.id!,
                {
                  'lastCheckup': lastCheckup,
                  'vaccinationStatus': vaccinationStatusController.text.isEmpty
                      ? null : vaccinationStatusController.text,
                  'nextVaccinationDue': nextVaccinationDue,
                  'allergies': allergiesController.text.isEmpty
                      ? null : allergiesController.text,
                  'medications': medicationsController.text.isEmpty
                      ? null : medicationsController.text,
                  'notes': notesController.text.isEmpty
                      ? null : notesController.text,
                  // Additional fields
                  'diet': dietController.text.isEmpty
                      ? null : dietController.text,
                  'weight': weightController.text.isEmpty
                      ? null : weightController.text,
                  'activityLevel': activityLevelController.text.isEmpty
                      ? null : activityLevelController.text,
                  'behavior': behaviorController.text.isEmpty
                      ? null : behaviorController.text,
                  'specialNeeds': specialNeedsController.text.isEmpty
                      ? null : specialNeedsController.text,
                },
              );

              // Reload data
              await _loadData();

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Health information updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final weightController = TextEditingController();
    String? selectedStatus = 'Normal';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Medical Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Normal', 'Attention', 'Critical']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedStatus = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }
                final appState = Provider.of<AppState>(context, listen: false);
                final vetName = appState.displayName;
                final record = MedicalRecord(
                  petId: widget.pet.id!,
                  title: titleController.text,
                  date: selectedDate,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  vetName: 'Dr. $vetName',
                  weight: weightController.text.isEmpty ? null : double.tryParse(weightController.text),
                  status: selectedStatus,
                );
                await appState.addMedicalRecord(record);
                await _loadData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medical record added')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRecordDialog(MedicalRecord record) {
    final titleController = TextEditingController(text: record.title);
    final descriptionController = TextEditingController(text: record.description ?? '');
    final weightController = TextEditingController(text: record.weight?.toString() ?? '');
    String? selectedStatus = record.status ?? 'Normal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Medical Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Normal', 'Attention', 'Critical']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedStatus = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }
                final updated = MedicalRecord(
                  id: record.id,
                  petId: record.petId,
                  title: titleController.text,
                  date: record.date,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  vetName: record.vetName,
                  weight: weightController.text.isEmpty ? null : double.tryParse(weightController.text),
                  status: selectedStatus,
                );
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.updateMedicalRecord(updated);
                await _loadData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medical record updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this medical record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.deleteMedicalRecord(record.id!, widget.pet.id!);
              await _loadData();

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medical record deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  DateTime _parseDate(String dateString) {
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };

    final parts = dateString.split(' ');
    final month = months[parts[0]] ?? 1;
    final day = int.tryParse(parts[1].replaceAll(',', '')) ?? 1;
    final year = int.tryParse(parts[2]) ?? DateTime.now().year;

    return DateTime(year, month, day);
  }
}
