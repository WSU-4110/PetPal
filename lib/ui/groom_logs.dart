// ui/groom_logs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/groom_log.dart';
import '../models/pet.dart';
import 'add_groom_log_dialog.dart'; // Unified dialog for add/edit

class GroomLogs extends StatefulWidget {
  final int petId;
  final bool isOwner;

  const GroomLogs({super.key, required this.petId, this.isOwner = false});

  @override
  State<GroomLogs> createState() => _GroomLogsPageState();
}

class _GroomLogsPageState extends State<GroomLogs> {
  Pet? selectedPet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPetAndLogs();
  }

  Future<void> _loadPetAndLogs() async {
    try {
      final pets = context.read<AppState>().pets;
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

        await context.read<AppState>().loadGroomLog(pet.id!);
      } else {
        if (!mounted) return;
        setState(() {
          selectedPet = null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        selectedPet = null;
        _isLoading = false;
      });
    }
  }

  void _updateSelectedPet() {
    final pets = context.read<AppState>().pets;
    if (pets.isEmpty) {
      setState(() => selectedPet = null);
      return;
    }

    if (selectedPet != null && !pets.any((p) => p.id == selectedPet!.id)) {
      setState(() => selectedPet = pets.first);
      context.read<AppState>().loadGroomLog(selectedPet!.id!);
    }
  }

  String _getPetName(int petId, AppState appState) {
    try {
      return appState.pets.firstWhere((p) => p.id == petId).name;
    } catch (_) {
      return 'Unknown Pet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.groomLogs;
    final bool isOwner = appState.currentUser?['role'] == 'owner';

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSelectedPet());

    final int alpha20 = (0.2 * 255).round();
    final int alpha90 = (0.9 * 255).round();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Grooming Logs",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
          child: Column(
            children: [
              if (isOwner && !_isLoading && selectedPet != null && appState.pets.isNotEmpty)
                _buildPetDropdown(appState, alpha20, alpha90),
              if (isOwner && selectedPet != null)
                _buildGrantAccessButton(appState),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (appState.pets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No pets available. Add a pet first!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (records.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No Grooming Logs.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, i) =>
                        _buildGroomLogTile(context, records[i], isOwner, appState),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetDropdown(AppState appState, int alpha20, int alpha90) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(alpha20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: selectedPet?.id,
        dropdownColor: Colors.white.withAlpha(alpha90),
        items: appState.pets
            .map((p) => DropdownMenuItem<int>(
                  value: p.id,
                  child: Text(p.name, style: const TextStyle(color: Color(0xFFB892F7))),
                ))
            .toList(),
        onChanged: (id) async {
          if (id != null) {
            final pet = appState.pets.firstWhere((p) => p.id == id);
            if (!mounted) return;
            setState(() => selectedPet = pet);
            await appState.loadGroomLog(pet.id!);
          }
        },
      ),
    );
  }

  Widget _buildGrantAccessButton(AppState appState) {
    return ElevatedButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final groomers = await appState.getGroomers();

        if (!mounted) return;

        final selectedGroomer = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (cont) => SimpleDialog(
            title: const Text("Select Groomer"),
            children: groomers
                .map((g) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(cont, g),
                      child: Text("${g['firstName']} ${g['lastName']}"),
                    ))
                .toList(),
          ),
        );

        if (!mounted || selectedGroomer == null || selectedPet == null) return;

        await appState.grantAccess(selectedPet!.id!, selectedGroomer['id']);

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text("Granted access to ${selectedGroomer['firstName']}")),
        );
      },
      child: const Text("Grant Groomer Access"),
    );
  }

  Widget _buildGroomLogTile(BuildContext context, GroomLog record, bool isOwner, AppState appState) {
    final messenger = ScaffoldMessenger.of(context);

    final int alpha15 = (0.15 * 255).round();
    final int alpha30 = (0.3 * 255).round();
    final int alpha25 = (0.25 * 255).round();

    final petName = _getPetName(record.petId, appState);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(alpha15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withAlpha(alpha30),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(petName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Title: ${record.type}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Description: ${record.description}\n\nMaintenance: ${record.maintenance}\n\nDate and Time: ${record.date}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () async {
                      final appStateRead = context.read<AppState>();
                      final result = await showDialog<GroomLog>(
                        context: context,
                        builder: (_) => AddGroomLogDialog(groomLog: record),
                      );

                      if (!mounted || result == null) return;
                      await appStateRead.updateGroomLog(result);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Grooming Log updated')),
                      );
                    },
                  ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await appState.deleteGroomLog(record.id!, record.petId);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Grooming Log deleted')),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
