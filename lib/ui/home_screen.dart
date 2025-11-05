// lib/ui/home_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'pet_list_screen.dart';
import 'reminder_list_screen.dart';
import 'calendar_screen.dart';
import '../models/pet.dart';
import '../services/breed_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedPetIndex;
  final Random _random = Random();

  // Tip rotation
  Timer? _tipTimer;
  int _tipIndex = 0;
  List<String> _currentTips = [];

  @override
  void initState() {
    super.initState();
    // timer started after we load pets in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chooseRandomPet();
    _prepareTipsAndTimer();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  void _chooseRandomPet() {
    final appState = Provider.of<AppState>(context, listen: false);
    final pets = _safePets(appState);
    if (pets.isEmpty) {
      setState(() => _selectedPetIndex = null);
    } else {
      setState(() => _selectedPetIndex = _random.nextInt(pets.length));
    }
  }

  List<Pet> _safePets(AppState appState) {
    try {
      final maybe = (appState as dynamic).pets;
      if (maybe is List<Pet>) return maybe;
      if (maybe is List) return maybe.whereType<Pet>().toList();
    } catch (_) {}
    return [];
  }

  Map<String, dynamic>? _safeUser(AppState appState) {
    try {
      final dyn = appState as dynamic;
      if (dyn.currentUser != null) return Map<String, dynamic>.from(dyn.currentUser);
    } catch (_) {}
    try {
      final dyn = appState as dynamic;
      if (dyn.user != null) return Map<String, dynamic>.from(dyn.user);
    } catch (_) {}
    try {
      final dyn = appState as dynamic;
      if (dyn.loggedInUser != null) return Map<String, dynamic>.from(dyn.loggedInUser);
    } catch (_) {}
    try {
      final dyn = appState as dynamic;
      final fn = dyn.firstName;
      final ln = dyn.lastName;
      if (fn != null || ln != null) return {'firstName': fn ?? '', 'lastName': ln ?? ''};
    } catch (_) {}
    return null;
  }

  String _greetingName(AppState appState) {
    final user = _safeUser(appState);
    if (user == null) return '';
    final fn = (user['firstName'] ?? user['first_name'] ?? user['first'])?.toString() ?? '';
    final ln = (user['lastName'] ?? user['last_name'] ?? user['last'])?.toString() ?? '';
    final full = '$fn ${ln}'.trim();
    return full.isEmpty ? '' : ', $full';
  }

  Widget _buildHeroPet(List<Pet> pets) {
    if (_selectedPetIndex == null || pets.isEmpty) {
      return _placeholderHero();
    }

    final idx = (_selectedPetIndex! >= pets.length) ? 0 : _selectedPetIndex!;
    final pet = pets[idx];
    final imagePath = pet.image ?? Pet.imageFor(pet.species, pet.breed);

    final ImageProvider provider =
        imagePath.startsWith('http') ? NetworkImage(imagePath) : AssetImage(imagePath);

    return GestureDetector(
      onTap: () {
        // optional: cycle manually when tapped
        if (pets.isEmpty) return;
        setState(() {
          _selectedPetIndex = ((_selectedPetIndex ?? 0) + 1) % pets.length;
          _prepareTipsAndTimer(); // update tips for new pet
        });
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
          image: DecorationImage(image: provider, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _placeholderHero() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: const Center(child: Icon(Icons.pets, size: 64, color: Colors.white70)),
    );
  }

  void _prepareTipsAndTimer() {
    _tipTimer?.cancel();
    final appState = Provider.of<AppState>(context, listen: false);
    final pets = _safePets(appState);

    final List<String> tips = [];

    if (pets.isNotEmpty) {
      // gather tips from all pets (unique)
      final Set<String> seen = {};
      for (var p in pets) {
        final combined = BreedService.getCombinedTipsForPet(p.species, p.breed);
        for (var t in combined) {
          if (!seen.contains(t)) {
            seen.add(t);
            tips.add(t);
          }
        }
      }
    }

    // always add general tips if none or to supplement
    if (tips.length < 3) {
      for (var t in BreedService.generalTips) {
        if (!tips.contains(t)) tips.add(t);
      }
    }

    setState(() {
      _currentTips = tips;
      _tipIndex = 0;
    });

    // start rotating every 6 seconds
    _tipTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % (_currentTips.isEmpty ? 1 : _currentTips.length);
      });
    });
  }

  Widget _tipsCard() {
    if (_currentTips.isEmpty) {
      return const SizedBox.shrink();
    }
    final tip = _currentTips[_tipIndex % _currentTips.length];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // small dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_currentTips.length, (i) {
              final active = i == _tipIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1.withOpacity(0.8), color2.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color2.withOpacity(0.4), blurRadius: 15, spreadRadius: 3, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pets = _safePets(appState);
    final greetingExtra = _greetingName(appState);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFB892F7), Color(0xFFFAC4F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Hero image + greeting row
                Row(
                  children: [
                    _buildHeroPet(pets),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome$greetingExtra!',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                                Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(1, 2))
                              ])),
                          const SizedBox(height: 6),
                          const Text('Love. Care. Track', style: TextStyle(fontSize: 16, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Tip card (polished)
                _tipsCard(),

                const SizedBox(height: 6),

                // Stats cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _statCard(
                        context: context,
                        title: 'Pets in System',
                        value: '${pets.length}',
                        icon: Icons.pets,
                        color1: Colors.purpleAccent,
                        color2: Colors.pinkAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PetListScreen()));
                        },
                      ),
                      const SizedBox(height: 20),
                      _statCard(
                        context: context,
                        title: 'Reminders Total',
                        value: '${(appState.reminders ?? []).length}',
                        icon: Icons.alarm,
                        color1: Colors.pinkAccent,
                        color2: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen()));
                        },
                      ),
                      const SizedBox(height: 20),
                      _statCard(
                        context: context,
                        title: 'Calendar',
                        value: 'See Tasks',
                        icon: Icons.today,
                        color1: Colors.pinkAccent,
                        color2: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Keep loving your furry friends!', style: TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
