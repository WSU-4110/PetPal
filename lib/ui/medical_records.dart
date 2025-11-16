import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'add_medical_record_dialog.dart';
import 'edit_medical_record_dialog.dart';
import '../models/medical_record.dart';
import '../models/pet.dart';

class MedicalRecordsPage extends StatefulWidget {
  final int petId;
  final bool isOwner;

  const MedicalRecordsPage({super.key, required this.petId, this.isOwner = false});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  Pet? selectedPet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final appState = context.read<AppState>();
      final pets = appState.pets;
      
      if (pets.isNotEmpty) {
        // Find the pet with matching ID or use the first pet as a fallback
        final pet = pets.firstWhere(
          (p) => p.id == widget.petId,
          orElse: () => pets.first,
        );
        
        if (mounted) {
          setState(() {
            selectedPet = pet;
            _isLoading = false;
          });
          
          // Load medical records for this pet
          await appState.loadMedicalRecords(pet.id!);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.medicalRecords;
    
    // Check user role
    final String? role = appState.currentUser?['role'] as String?;
    final bool isOwner = role == 'owner';
    final bool isVet = role == 'vet';

    // Access control
    if (!isVet && !isOwner) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'Access denied',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Medical Records",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : selectedPet == null
                  ? const Center(
                      child: Text(
                        'No pet found',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        
                        // Pet selector dropdown (only for owners)
                        if (isOwner && appState.pets.length > 1)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<Pet>(
                              value: selectedPet,
                              isExpanded: true,
                              dropdownColor: const Color(0xFFB892F7),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              items: appState.pets
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (p) {
                                if (p != null) {
                                  setState(() => selectedPet = p);
                                  context.read<AppState>().loadMedicalRecords(p.id!);
                                }
                              },
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Grant Vet Access Button (only for owners)
                        if (isOwner)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ElevatedButton.icon(
                              onPressed: () => _showGrantAccessDialog(context, appState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Grant Vet Access'),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Records list
                        Expanded(
                          child: records.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.medical_services_outlined,
                                        size: 80,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "No medical records yet",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isVet 
                                            ? "Add records after checkups"
                                            : "Records will appear here",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (isVet) ...[
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: () => _showAddRecordDialog(context),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add First Record'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: records.length,
                                  itemBuilder: (context, i) {
                                    return _buildRecordCard(records[i], isVet, appState);
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: (isVet && selectedPet != null)
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8E87FF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () => _showAddRecordDialog(context),
                child: const Icon(Icons.add, size: 30, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildRecordCard(MedicalRecord record, bool isVet, AppState appState) {
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              if (isVet)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFFB892F7),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditRecordDialog(context, record);
                    } else if (value == 'delete') {
                      _deleteRecord(context, record, appState);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
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
          
          if (record.status != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                record.status!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          
          if (record.description != null && record.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              record.description!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                _formatDate(record.date),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              if (record.vetName != null) ...[
                const SizedBox(width: 20),
                const Icon(Icons.person, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.vetName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (record.weight != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monitor_weight, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  '${record.weight} kg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showGrantAccessDialog(BuildContext context, AppState appState) async {
    if (selectedPet == null) return;
    
    final vets = await appState.getVeterinarians();

    if (!mounted) return;

    final selectedVet = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFB892F7),
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
      await appState.grantAccess(selectedPet!.id!, selectedVet['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Granted access to Dr. ${selectedVet['firstName']} ${selectedVet['lastName']}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showAddRecordDialog(BuildContext context) {
    if (selectedPet == null) return;
    
    showDialog(
      context: context,
      builder: (_) => AddMedicalRecordDialog(petId: selectedPet!.id!),
    );
  }

  void _showEditRecordDialog(BuildContext context, MedicalRecord record) {
    final appState = context.read<AppState>();
    
    showDialog(
      context: context,
      builder: (_) => EditMedicalRecordDialog(
        medicalrecord: record,
        pets: appState.pets,
      ),
    ).then((result) async {
      if (result != null && result is MedicalRecord) {
        await appState.updateMedicalRecord(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medical record updated')),
          );
        }
      }
    });
  }

  void _deleteRecord(BuildContext context, MedicalRecord record, AppState appState) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFB892F7),
        title: const Text(
          'Delete Record',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this medical record?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await appState.deleteMedicalRecord(record.id!, record.petId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medical record deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}