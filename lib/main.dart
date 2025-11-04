// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/home_screen.dart';
import 'ui/pet_list_screen.dart';
import 'ui/reminder_list_screen.dart';
import 'ui/health_screen.dart';
import 'ui/app_drawer.dart';
import 'ui/login_page.dart';
import 'state/app_state.dart';
import 'ui/exercise_screen.dart';

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

  List<Widget> get _pages {
    if (widget.role == 'owner') {
      return [
        const HomeScreen(),
        const PetListScreen(),
        const ReminderListScreen(),
        const HealthScreen(),
        const ExerciseScreen(),
      ];
    } else if (widget.role == 'vet') {
      return [
        const HomeScreen(),
        const HealthScreen(),
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
                BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
                BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise')
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
              ],
      ),
    );
  }
}
