// lib/ui/health_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';
import '../state/app_state.dart';

class HealthTabScreen extends StatefulWidget {
  final Pet pet;
  const HealthTabScreen({super.key, required this.pet});

  @override
  State<HealthTabScreen> createState() => _HealthTabScreenState();
}

class _HealthTabScreenState extends State<HealthTabScreen> {
  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  bool _isVet = false;
  bool _isOwner = false;
  bool _showMedicalRecords = false;

  // Health information fields - unified with vet home screen
  Map<String, dynamic>? _healthInfo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when the screen becomes visible again
    _loadData();
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Check user role
    setState(() {
      _isVet = appState.currentUser?['role'] == 'vet';
      _isOwner = appState.currentUser?['role'] == 'owner';
    });

    // Load medical records for this pet
    await appState.loadMedicalRecords(widget.pet.id!);

    // Load health information for this pet
    await _loadHealthInfo(appState);

    setState(() {
      _records = appState.medicalRecords;
      _isLoading = false;
    });
  }

  Future<void> _loadHealthInfo(AppState appState) async {
    // Load health information from database
    final healthInfo = await appState.getPetHealthInfo(widget.pet.id!);

    // Always update the state with the latest data
    setState(() {
      _healthInfo = healthInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Information Section
              _buildHealthInfoSection(),

              // Action Buttons (only for owners)
              if (_isOwner) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildGrantAccessButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMedicalRecordsButton()),
                  ],
                ),
              ],

              // Medical Records List (only when showMedicalRecords is true)
              if (_showMedicalRecords) ...[
                const SizedBox(height: 20),
                const Text(
                  'Medical Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                if (_records.isEmpty)
                  _buildEmptyState()
                else
                  ..._records.map((record) => _buildMedicalRecordCard(record)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    // Default values if health info is not available
    final lastCheckup = _healthInfo?['lastCheckup'];
    final vaccinationStatus = _healthInfo?['vaccinationStatus'] ?? 'Not recorded';
    final nextVaccinationDue = _healthInfo?['nextVaccinationDue'];
    final allergies = _healthInfo?['allergies'];
    final medications = _healthInfo?['medications'];
    final notes = _healthInfo?['notes'];

    // Additional fields to match vet home screen
    final diet = _healthInfo?['diet'] ?? 'Not recorded';
    final weight = _healthInfo?['weight'] ?? 'Not recorded';
    final activityLevel = _healthInfo?['activityLevel'] ?? 'Not recorded';
    final behavior = _healthInfo?['behavior'] ?? 'Not recorded';
    final specialNeeds = _healthInfo?['specialNeeds'] ?? 'Not recorded';

    return Container(
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
          const Text(
            'Health Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 16),

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

  Widget _buildGrantAccessButton() {
    return ElevatedButton.icon(
      onPressed: _showGrantAccessDialog,
      icon: const Icon(Icons.person_add, size: 18),
      label: const Text('Grant Vet Access'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4ECDC4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _showMedicalRecords = !_showMedicalRecords;
        });
      },
      icon: Icon(_showMedicalRecords ? Icons.visibility_off : Icons.visibility, size: 18),
      label: Text(_showMedicalRecords ? 'Hide Records' : 'Medical Records'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
        children: [
          Icon(
            Icons.health_and_safety,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _isVet ? 'No Medical Records Yet' : 'No Health Data Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isVet
                ? 'Add medical records after checkups and procedures.'
                : 'Health data will be added by your veterinarian after checkups.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
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
          // Header with title and menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (record.vetName != null)
                      Text(
                        'By ${record.vetName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
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

  void _showGrantAccessDialog() async {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      // Get all veterinarians
      final vets = await appState.getVeterinarians();

      if (!mounted) return;

      final selectedVet = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF4ECDC4),
            title: const Text(
              "Select Veterinarian",
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: vets.isEmpty
                  ? const Text(
                      'No veterinarians available',
                      style: TextStyle(color: Colors.white70),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: vets.length,
                      itemBuilder: (context, index) {
                        final vet = vets[index];
                        final fullName = "Dr. ${vet['firstName']} ${vet['lastName']}";
                        return ListTile(
                          title: Text(
                            fullName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            vet['email'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () => Navigator.pop(dialogContext, vet),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (selectedVet != null && mounted) {
        try {
          // Grant access to vet - use safe type conversion
          final vetId = selectedVet['id'] as int?;
          final petId = widget.pet.id;
          if (vetId != null && petId != null) {
            debugPrint('selectedVet: $selectedVet');
            debugPrint('selectedVet.id: ${selectedVet['id']} (${selectedVet['id']?.runtimeType})');
            debugPrint('pet.id: ${widget.pet.id} (${widget.pet.id?.runtimeType})');

            await appState.grantAccess(petId, vetId);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Granted access to Dr. ${selectedVet['firstName']} ${selectedVet['lastName']}"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error granting access: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading veterinarians: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
