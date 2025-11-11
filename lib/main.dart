import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/home_screen.dart';
import 'ui/pet_list_screen.dart';
import 'ui/reminder_list_screen.dart';
import 'ui/exercise_screen.dart';
import 'ui/groom_screen.dart';
import 'ui/app_drawer.dart'; // AppDrawer import
import 'ui/login_page.dart';
import 'ui/medical_records.dart';
import 'state/app_state.dart' as app_state; // aliased to avoid ambiguity
import 'models/pet.dart';
import '../dashboards/vetdash.dart';
import '../dashboards/trainerdash.dart';
import '../dashboards/groomdash.dart';

void main() {
  runApp(const PetPalApp());
}

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = app_state.AppState();
        state.init(); // load initial data and settings
        return state;
      },
      child: MaterialApp(
        title: 'PetPal',
        theme: ThemeData(primarySwatch: Colors.teal),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/main': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return MainNavigation(role: args['role'] as String);
          },
          '/medical_records': (context) {
            final pet = ModalRoute.of(context)!.settings.arguments as Pet;
            return MedicalRecordsPage(petId: pet.id!);
          },
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

  List<Widget> get _pages {
    switch (widget.role) {
      case 'owner':
        return const [
          HomeScreen(),
          PetListScreen(),
          ReminderListScreen(),
          ExerciseScreen(),
          GroomScreen(),
        ];
      case 'vet':
        return [
          const HomeScreen(),
          // Don't initialize MedicalRecordsPage with petId=0
          // Instead create a VetDashboard that handles pet selection
          VetDashboard(),
        ];
      case 'trainer':
        return [
          HomeScreen(),
          TrainerDashboard(),
        ];
      case 'groomer':
        return [
          HomeScreen(),
          GroomerDashboard(),
        ];
      default:
        return [Center(child: Text("Unknown role"))];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (widget.role) {
      case 'owner':
        return 'Owner Dashboard';
      case 'vet':
        return 'Veterinarian Dashboard';
      case 'trainer':
        return 'Trainer Dashboard';
      case 'groomer':
        return 'Grooming Dashboard';
      default:
        return 'Dashboard';
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    switch (widget.role) {
      case 'owner':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
          BottomNavigationBarItem(icon: Icon(Icons.cut), label: 'Grooming'),
        ];
      case 'vet':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
        ];
      case 'trainer':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Exercise'),
        ];
      case 'groomer':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.cut), label: 'Grooming'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        ];
    }
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
        title: Text(_getAppBarTitle()),
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
        items: _getBottomNavItems(),
      ),
    );
  }
}