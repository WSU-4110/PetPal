// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/home_screen.dart';
import 'ui/pet_list_screen.dart';
import 'ui/reminder_list_screen.dart';
import 'ui/medical_records.dart';
import 'ui/app_drawer.dart';
import 'ui/login_page.dart';
import 'state/app_state.dart';

void main() {
  runApp(const PetPalApp());
}

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final appState = AppState();
        appState.loadPet();
        appState.loadReminder();
        return appState;
      },
      child: MaterialApp(
        title: 'PetPal',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const LoginPage(),
        routes: {
          '/medical_records': (context) => const MedicalRecordsPage(petId: 0), // Default pet ID
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String role;
  const MainNavigation({super.key, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _currentPetId = 0; // Track current pet for medical records

  List<Widget> get _pages {
    if (widget.role == 'owner') {
      return [
        const HomeScreen(),
        const PetListScreen(),
        const ReminderListScreen(),
        MedicalRecordsPage(petId: _currentPetId), // Medical Records instead of Health
      ];
    } else if (widget.role == 'vet') {
      return [
        const HomeScreen(),
        const Center(child: Text('Vet Appointments')),
      ];
    } else {
      return [const Center(child: Text("Unknown role"))];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(widget.role == 'owner' ? 'Owner Dashboard' : 'Vet Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: widget.role == 'owner'
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
                BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
                BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Medical'), // Changed to Medical
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Appointments'),
              ],
      ),
    );
  }
}