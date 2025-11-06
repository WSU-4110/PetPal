import 'package:flutter/material.dart';
import 'package:petpal/ui/add_groom_log_dialog.dart';
import 'package:petpal/ui/edit_groom_log_dialog.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/groom_log.dart';
import '../models/pet.dart';

class GroomLogs extends StatefulWidget {
  final int petId;
  const GroomLogs({super.key, required this.petId});

  @override
  State<GroomLogs> createState() => _GroomLogsPageState();
}

class _GroomLogsPageState extends State<GroomLogs> {
  late Pet selectedPet;

  @override
  void initState() {
    super.initState();
    // Load groom logs for pet
    final pets = context.read<AppState>().pets;
    selectedPet = pets.firstWhere((p) => p.id == widget.petId);
    Future.microtask(() =>
        context.read<AppState>().loadGroomLog(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final records = appState.groomLogs;

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
        // Match ReminderListScreen gradient
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
              DropdownButton<Pet>(
                value: selectedPet,
                items: appState.pets
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) {
                  if (p != null) {
                    setState(() => selectedPet = p);
                    context.read<AppState>().loadGroomLog(p.id!);
                    }
                  },
                ),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          "No Grooming Logs.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, i) {
                          final record = records[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                record.type,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                "${record.date} — ${record.maintenance}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () async {
                                  final result = await showDialog<GroomLog>(
                                    context: context,
                                    builder: (_) => EditGroomLogDialog(
                                      groomLog: record,
                                      pets: appState.pets,
                                    ),
                                  );
                                  if (result != null) {
                                    await context.read<AppState>().updateGroomLog(result);
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await appState.deleteGroomLog(record.id!, record.petId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Grooming Log deleted')),
                                    );
                                  },
                                ),
                                ],
                            ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AddGroomLogDialog(petId: selectedPet.id!),
            );
          },
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
    );
  }
}