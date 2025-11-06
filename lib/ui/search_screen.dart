// lib/ui/search_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  String? _species;
  String? _breed;
  int? _minAge;
  int? _maxAge;
  Map<String, List<String>> _breedOptions = {};
  List<String> _speciesOptions = [];

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    try {
      final raw = await rootBundle.loadString('assets/breeds.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      setState(() {
        _breedOptions = decoded.map(
          (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
        );
        _speciesOptions = _breedOptions.keys.toList();
      });
    } catch (_) {
      // fallback if asset not present
      setState(() {
        _breedOptions = {'Other': ['Other']};
        _speciesOptions = ['Other'];
      });
    }
  }

  List<dynamic> _filterAll(AppState appState) {
    final q = _query.trim().toLowerCase();

    final List<Pet> pets = appState.pets;
    final List<MedicalRecord> records = appState.medicalRecords;

    final resources = <String>[
      'Top 10 puppy training tips',
      'How to socialize your cat',
      'Rabbit-safe houseplants',
      'Basic pet first-aid',
      'Emergency vet locations'
    ];

    final petResults = pets.where((p) {
      // text match
      if (q.isNotEmpty &&
          !('${p.name} ${p.species} ${p.breed}'.toLowerCase().contains(q))) {
        return false;
      }

      // species filter (explicit check)
      if ((_species ?? '').isNotEmpty) {
        if (p.species.toLowerCase() != _species!.toLowerCase()) {
          return false;
        }
      }

      // breed filter
      if ((_breed ?? '').isNotEmpty && _breed != 'Other') {
        if (p.breed.toLowerCase() != _breed!.toLowerCase()) {
          return false;
        }
      }

      // age range
      if (_minAge != null && p.age < _minAge!) return false;
      if (_maxAge != null && p.age > _maxAge!) return false;

      return true;
    }).toList();

    final recordResults = records.where((r) {
      final haystack =
          '${r.title} ${r.vetName} ${r.description}'.toLowerCase();
      return q.isEmpty || haystack.contains(q);
    }).toList();

    final resourceResults =
        resources.where((r) => r.toLowerCase().contains(q)).toList();

    return [...petResults, ...recordResults, ...resourceResults];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final results = _filterAll(appState);

    // Build species items and breed items without risky spread/null-aware assumptions.
    final List<DropdownMenuItem<String?>> speciesItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Any')),
      ..._speciesOptions.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
    ];

    // compute breed list safely
    List<String> breedList = <String>[];
    if (_species != null && _breedOptions.containsKey(_species)) {
      breedList = List<String>.from(_breedOptions[_species]!);
    }

    final List<DropdownMenuItem<String?>> breedItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Any')),
      ...breedList.map((b) => DropdownMenuItem<String?>(value: b, child: Text(b))),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search pets, medical records, resources...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),

            // Filters row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: 'Species',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    initialValue: _species,
                    items: speciesItems,
                    onChanged: (v) {
                      setState(() {
                        _species = v;
                        _breed = null; // reset breed when species changes
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: 'Breed',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    initialValue: _breed,
                    items: breedItems,
                    onChanged: (v) => setState(() => _breed = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Age range inputs + Reset
            Row(
              children: [
                Flexible(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Min age',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _minAge = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Max age',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _maxAge = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _species = null;
                      _breed = null;
                      _minAge = null;
                      _maxAge = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Results
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'No results',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = results[i];
                        if (item is Pet) {
                          final image = item.image ?? Pet.imageFor(item.species, item.breed);

                          final ImageProvider imageProvider =
                              image.startsWith('http') ? NetworkImage(image) : AssetImage(image);

                          return Card(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: imageProvider,
                                radius: 26,
                                backgroundColor: Colors.white.withValues(alpha: 0.24),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${item.breed} • ${item.species} • Age: ${item.age}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'view') {
                                    // show sheet without awaiting to avoid using context across async gap
                                    showModalBottomSheet<void>(
                                      context: context,
                                      builder: (_) => Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text('Breed: ${item.breed}'),
                                            Text('Species: ${item.species}'),
                                            Text('Age: ${item.age}'),
                                            const SizedBox(height: 12),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else if (v == 'delete') {
                                    // capture messenger before async gap
                                    final messenger = ScaffoldMessenger.of(context);
                                    final asDyn =
                                        Provider.of<AppState>(context, listen: false) as dynamic;
                                    if (asDyn.deletePet is Function) {
                                      await asDyn.deletePet(item.id);
                                      if (!mounted) return;
                                      messenger.showSnackBar(const SnackBar(content: Text('Pet deleted')));
                                      setState(() {});
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem(value: 'view', child: Text('View')),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit (TODO)')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        } else if (item is MedicalRecord) {
                          return Card(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: ListTile(
                              leading: const Icon(Icons.medical_services, color: Colors.white70),
                              title: Text(
                                '${item.title} • ${item.vetName}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                item.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        } else if (item is String) {
                          return Card(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: ListTile(
                              leading: const Icon(Icons.book, color: Colors.white70),
                              title: Text(
                                item,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}