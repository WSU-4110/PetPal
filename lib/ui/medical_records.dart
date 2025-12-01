// lib/ui/medical_records.dart
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
    _loadPetAndRecords();
  }

  Future<void> _loadPetAndRecords() async {
    try {
      final appState = context.read<AppState>();
      final pets = appState.pets;

      if (pets.isNotEmpty) {
        final pet = pets.firstWhere(
          (p) => p.id == widget.petId,
          orElse: () => pets.first,
        );

        if (!mounted) return;
        setState(() {
          selectedPet = pet;
          _isLoading = false;
        });

        await appState.loadMedicalRecords(pet.id!);
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

    final bool isOwner = appState.currentUser?['role'] == 'owner';
    final bool isVet = appState.currentUser?['role'] == 'vet';

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
            child: Text('Access denied', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Medical Records", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : selectedPet == null
                  ? const Center(
                      child: Text('No pet found', style: TextStyle(color: Colors.white, fontSize: 20)),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        if (isOwner && appState.pets.length > 1)
                          _buildPetDropdown(appState),
                        if (isOwner) _buildGrantAccessButton(appState),
                        Expanded(
                          child: records.isEmpty
                              ? _buildEmptyRecords(isVet)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: records.length,
                                  itemBuilder: (context, i) => _buildRecordCard(records[i], isVet, appState),
                                ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: (isVet && selectedPet != null)
          ? _buildAddRecordFAB()
          : null,
    );
  }

  Widget _buildPetDropdown(AppState appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<Pet>(
        value: selectedPet,
        isExpanded: true,
        dropdownColor: const Color(0xFFB892F7),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        items: appState.pets.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (p) async {
          if (p != null) {
            if (!mounted) return;
            setState(() => selectedPet = p);
            await context.read<AppState>().loadMedicalRecords(p.id!);
          }
        },
      ),
    );
  }

  Widget _buildGrantAccessButton(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ElevatedButton.icon(
        onPressed: () async {
          if (selectedPet == null) return;
          final messenger = ScaffoldMessenger.of(context);
          final vets = await appState.getVeterinarians();
          if (!mounted) return;

          final selectedVet = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (cont) => SimpleDialog(
              title: const Text("Select Veterinarian"),
              children: vets
                  .map((vet) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(cont, vet),
                        child: Text("${vet['firstName']} ${vet['lastName']}"),
                      ))
                  .toList(),
            ),
          );

          if (!mounted || selectedVet == null) return;
          await appState.grantAccess(selectedPet!.id!, selectedVet['id']);
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text("Granted access to Dr. ${selectedVet['firstName']} ${selectedVet['lastName']}")),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Grant Vet Access"),
      ),
    );
  }

  Widget _buildAddRecordFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddRecordDialog(),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildEmptyRecords(bool isVet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 80, color: Colors.white.withAlpha((0.3 * 255).round())),
          const SizedBox(height: 16),
          const Text("No medical records yet", style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            isVet ? "Add records after checkups" : "Records will appear here",
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog() async {
    if (selectedPet == null) return;
    final appStateRead = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<MedicalRecord>(
      context: context,
      builder: (_) => AddMedicalRecordDialog(petId: selectedPet!.id!),
    );

    if (!mounted || result == null) return;
    await appStateRead.addMedicalRecord(result);
    await _loadPetAndRecords();
    messenger.showSnackBar(const SnackBar(content: Text('Medical record added')));
  }

  Widget _buildRecordCard(MedicalRecord record, bool isVet, AppState appState) {
    final messenger = ScaffoldMessenger.of(context);
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
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(record.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              if (isVet)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () async {
                        final result = await showDialog<MedicalRecord>(
                          context: context,
                          builder: (_) => EditMedicalRecordDialog(medicalrecord: record, pets: appState.pets),
                        );
                        if (!mounted || result == null) return;
                        await appState.updateMedicalRecord(result);
                        await _loadPetAndRecords();
                        messenger.showSnackBar(const SnackBar(content: Text('Medical record updated')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await appState.deleteMedicalRecord(record.id!, record.petId);
                        if (!mounted) return;
                        messenger.showSnackBar(const SnackBar(content: Text('Medical record deleted')));
                        await _loadPetAndRecords();
                      },
                    ),
                  ],
                ),
            ],
          ),
          if (record.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(record.status!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          if (record.description != null && record.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(record.description!, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(_formatDate(record.date), style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}
