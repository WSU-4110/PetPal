// lib/ui/pet_details_screen.dart
import 'package:flutter/material.dart';
import '../models/pet.dart';
import 'appointments_screen.dart';
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
  final int _energyLevel = 3; // Out of 3

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Back to 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    
    // Use the age property from the Pet model
    final yearsOld = pet.age;

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
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF2D3142)),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section with pet info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Pet avatar with edit button
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFF42A5F5),
                          width: 3,
                        ),
                      ),
                      child: _buildPetAvatar(pet),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Pet name and energy indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: List.generate(3, (index) {
                        return Icon(
                          Icons.bolt,
                          color: index < _energyLevel
                              ? const Color(0xFFFFB020)
                              : Colors.grey[300],
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Pet details
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
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      pet.gender.toLowerCase() == 'male'
                          ? Icons.male
                          : Icons.female,
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
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.alarm,
                      label: 'Add\nReminder',
                      color: const Color(0xFF6C63FF),
                      onTap: () {
                        // Add reminder
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.favorite,
                      label: 'Book\nVet',
                      color: const Color(0xFFFF6B6B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentsScreen(pet: pet),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.cut,
                      label: 'Book\nGrooming',
                      color: const Color(0xFF4ECDC4),
                      onTap: () {
                        // Book grooming
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF6B6B),
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: const Color(0xFFFF6B6B),
              tabs: const [
                Tab(
                  icon: Icon(Icons.favorite),
                  text: 'Health',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Appointments',
                ),
                Tab(
                  icon: Icon(Icons.photo_library),
                  text: 'Gallery',
                ),
              ],
            ),
          ),
          
          // Tab content
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
          errorBuilder: (_, __, ___) => const Icon(
            Icons.pets,
            size: 60,
            color: Color(0xFF42A5F5),
          ),
        ),
      );
    }
    
    return ClipOval(
      child: Image.asset(
        image,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.pets,
          size: 60,
          color: Color(0xFF42A5F5),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}